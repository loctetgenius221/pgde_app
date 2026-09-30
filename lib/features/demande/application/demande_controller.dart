import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/brouillon_store.dart';
import '../data/demande_api.dart';
import '../data/selecteur_fichiers.dart';
import '../domain/demande.dart';

/// Détient le dossier en cours d'édition.
///
/// **Un seul point de mutation** : [modifier]. Trente champs donneraient
/// trente méthodes ; une transformation sur un agrégat immuable en donne une.
/// C'est aussi ce qui garantit qu'aucune écriture ne peut contourner la
/// sauvegarde du brouillon.
class DemandeController extends AsyncNotifier<Demande> {
  /// On n'écrit pas sur disque à chaque frappe : les champs texte déclenchent
  /// une modification par caractère.
  static const Duration _delaiSauvegarde = Duration(milliseconds: 400);

  Timer? _sauvegarde;

  @override
  Future<Demande> build() async {
    ref.onDispose(() => _sauvegarde?.cancel());

    final Demande? serveur = await ref.watch(demandeApiProvider).mien();
    final Demande? brouillon = ref.watch(brouillonStoreProvider).lire();

    // Le brouillon prime : il n'existe que **pendant** une édition, et il est
    // purgé dès qu'un enregistrement aboutit. S'il est là, c'est qu'il porte
    // des modifications que le serveur n'a pas.
    return brouillon ?? serveur ?? const Demande();
  }

  /// Applique une transformation au dossier et planifie la sauvegarde locale.
  void modifier(Demande Function(Demande) transformation) {
    final Demande? actuel = state.value;
    if (actuel == null) return;

    final Demande suivant = transformation(actuel);
    if (suivant == actuel) return; // rien n'a bougé : pas d'écriture inutile

    state = AsyncData(suivant);

    _sauvegarde?.cancel();
    _sauvegarde = Timer(
      _delaiSauvegarde,
      () => ref.read(brouillonStoreProvider).ecrire(suivant),
    );
  }

  /// Envoie le dossier au serveur, étape par étape, puis purge le brouillon.
  ///
  /// Le contrat découpe l'écriture en quatre `PUT` (§5.2 à §5.5). On les
  /// enchaîne dans l'ordre du formulaire : si l'un échoue, les précédents
  /// sont déjà enregistrés et le candidat ne perd que ce qui n'est pas
  /// passé. C'est l'inverse exact de l'ancien envoi global, où un seul champ
  /// refusé renvoyait tout le dossier à l'expéditeur.
  ///
  /// Les erreurs remontent à l'appelant : c'est l'écran qui sait sur quelle
  /// étape renvoyer l'utilisateur en cas de 422.
  Future<void> enregistrer() async {
    final Demande? actuel = state.value;
    if (actuel == null) return;

    _sauvegarde?.cancel();
    final DemandeApi api = ref.read(demandeApiProvider);

    await api.enregistrerIdentite(actuel);
    await api.enregistrerFormations(actuel);
    await api.enregistrerExperiences(actuel);
    await api.enregistrerVoeux(actuel);

    // Le formulaire est sauvé : on purge le brouillon avant de toucher aux
    // pièces. Si un fichier est refusé ensuite, l'utilisateur ne doit pas
    // croire que sa saisie est perdue.
    await ref.read(brouillonStoreProvider).purger();
    state = AsyncData(actuel.copyWith(deposee: true));

    await _deposerLesPiecesEnAttente();

    // Le serveur fait foi une fois tout envoyé : les justificatifs y ont pris
    // leur chemin définitif, que seul `GET /candidat/profile` connaît.
    final Demande? serveur = await api.mien();
    if (serveur != null) state = AsyncData(serveur);
  }

  /// Dépose les pièces mises en file (§6).
  ///
  /// Elles ne peuvent partir qu'**après** l'enregistrement des formations :
  /// `formation_index` désigne un rang que le serveur doit déjà connaître.
  Future<void> _deposerLesPiecesEnAttente() async {
    final PiecesEnAttente file = ref.read(piecesEnAttenteProvider);
    if (file.estVide) return;

    final DemandeApi api = ref.read(demandeApiProvider);

    final File? photo = file.photo;
    if (photo != null) {
      final FichierJoint piece = await api.deposerPhoto(photo);
      modifier((d) => d.copyWith(photo: piece));
    }

    // Dans l'ordre des formations, pour que les rangs envoyés correspondent
    // à ceux que le serveur vient d'enregistrer.
    final List<int> rangs = file.justificatifs.keys.toList()..sort();
    for (final int rang in rangs) {
      final FichierJoint piece = await api.deposerDiplome(
        fichier: file.justificatifs[rang]!,
        formationIndex: rang,
      );
      modifier((d) => d.avecJustificatif(rang, piece));
    }

    ref.read(piecesEnAttenteProvider.notifier).vider();
  }

  /// Retire le justificatif d'une formation.
  ///
  /// Le contrat §6 n'expose **aucune suppression de justificatif** : seul le
  /// CV peut être retiré côté serveur. On détache donc la pièce de la
  /// formation et on laisse le prochain `PUT /candidat/formations` la
  /// remplacer — l'absence d'`existing_diplome_file` vaut abandon.
  Future<void> retirerJustificatif(int rang) async {
    modifier((d) => d.avecJustificatif(rang, null));
  }

  /// Remplace la photo d'un dossier déjà enregistré (§6.1).
  Future<void> remplacerPhoto(File fichier) async {
    final FichierJoint piece = await ref
        .read(demandeApiProvider)
        .deposerPhoto(fichier);
    modifier((d) => d.copyWith(photo: piece));
  }

  /// Abandonne les modifications locales et repart de l'état serveur.
  Future<void> abandonnerLeBrouillon() async {
    _sauvegarde?.cancel();
    await ref.read(brouillonStoreProvider).purger();
    ref.invalidateSelf();
  }
}

final demandeControllerProvider =
    AsyncNotifierProvider<DemandeController, Demande>(DemandeController.new);

/// Vrai si une édition locale n'a pas encore été envoyée au serveur.
final brouillonEnAttenteProvider = Provider<bool>(
  (ref) => ref.watch(brouillonStoreProvider).lire() != null,
);
