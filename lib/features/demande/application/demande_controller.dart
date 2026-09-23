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

  /// Envoie **l'intégralité** du dossier au serveur, puis purge le brouillon.
  ///
  /// Les erreurs remontent à l'appelant : c'est l'écran qui sait sur quelle
  /// étape renvoyer l'utilisateur en cas de 422 (§8.7).
  Future<void> enregistrer() async {
    final Demande? actuel = state.value;
    if (actuel == null) return;

    _sauvegarde?.cancel();
    final DemandeApi api = ref.read(demandeApiProvider);

    final Demande enregistre = actuel.existeSurLeServeur
        ? await api.mettreAJour(actuel)
        : await api.creer(actuel);

    // Le formulaire est sauvé : on le publie et on purge le brouillon avant
    // de toucher aux pièces. Si un fichier est refusé ensuite, l'utilisateur
    // ne doit pas croire que sa saisie est perdue.
    await ref.read(brouillonStoreProvider).purger();
    state = AsyncData(enregistre);

    state = AsyncData(await _deposerLesPiecesEnAttente(enregistre));
  }

  /// Dépose les pièces mises en file. Elles ne peuvent partir qu'après la
  /// création du dossier : les endpoints du §7.5 s'attachent à une `userdata`
  /// existante.
  Future<Demande> _deposerLesPiecesEnAttente(Demande dossier) async {
    final PiecesEnAttente file = ref.read(piecesEnAttenteProvider);
    if (file.estVide) return dossier;

    final DemandeApi api = ref.read(demandeApiProvider);
    Demande courant = dossier;

    final File? photo = file.photo;
    if (photo != null) courant = await api.deposerPhoto(photo);

    for (final TypeFichier type in TypeFichier.values) {
      final List<File> fichiers = file.de(type);
      if (fichiers.isEmpty) continue;
      courant = await api.deposerDocuments(type: type, fichiers: fichiers);
    }

    ref.read(piecesEnAttenteProvider.notifier).vider();
    return courant;
  }

  /// Retire une pièce déjà déposée sur le serveur.
  ///
  /// La réponse porte l'état **serveur** du dossier : l'adopter en entier
  /// écraserait les modifications du formulaire pas encore enregistrées. On
  /// n'en reprend donc que la liste des pièces.
  Future<void> retirerPiece(TypeFichier type, String chemin) async {
    final Demande retour = await ref
        .read(demandeApiProvider)
        .supprimerFichier(type: type, chemin: chemin);
    modifier((d) => d.avecFichiers(type, retour.fichiersDe(type)));
  }

  /// Remplace la photo d'un dossier déjà enregistré (§3.1, « Changer la
  /// photo »).
  Future<void> remplacerPhoto(File fichier) async {
    final Demande retour = await ref
        .read(demandeApiProvider)
        .deposerPhoto(fichier);
    modifier((d) => d.copyWith(photo: retour.photo));
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
