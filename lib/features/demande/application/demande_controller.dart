import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
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

    // Surveiller le magasin, c'est surveiller le compte : il est recréé à
    // chaque changement d'utilisateur, et le dossier repart alors de zéro.
    // Sans cela, le candidat suivant sur le même téléphone héritait en
    // mémoire du dossier du précédent.
    final Demande? brouillon = ref.watch(brouillonStoreProvider).lire();

    // Sans fiche `userdata` (`has_profile: false` au login), il n'y a rien à
    // lire : le serveur répond même 500 sur `GET /candidat/profile` dans ce
    // cas. On part donc d'un dossier vierge sans l'appeler.
    final bool aUnProfil = ref.watch(
      utilisateurConnecteProvider.select((u) => u?.hasProfile ?? false),
    );
    if (!aUnProfil) return brouillon ?? const Demande();

    final Demande? serveur = await ref.watch(demandeApiProvider).mien();

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
    // Le magasin est capturé **maintenant** : la sauvegarde différée part
    // dans le brouillon de l'auteur de la modification, même si un autre
    // compte s'est connecté entre-temps.
    final BrouillonStore brouillon = ref.read(brouillonStoreProvider);
    _sauvegarde = Timer(_delaiSauvegarde, () => brouillon.ecrire(suivant));
  }

  /// Envoie le dossier au serveur, étape par étape, puis purge le brouillon.
  ///
  /// Un justificatif de diplôme doit être téléversé **avant** le PUT
  /// formations : le serveur n'accepte que le `file_path` retourné (§5.3, §6.4).
  Future<void> enregistrer() async {
    final Demande? actuel = state.value;
    if (actuel == null) return;

    _sauvegarde?.cancel();
    final DemandeApi api = ref.read(demandeApiProvider);

    final Demande aEnvoyer = await _rattacherLesPieces(actuel);

    await api.enregistrerIdentite(aEnvoyer);
    await api.enregistrerFormations(aEnvoyer);
    await api.enregistrerExperiences(aEnvoyer);
    await api.enregistrerVoeux(aEnvoyer);

    await ref.read(brouillonStoreProvider).purger();
    state = AsyncData(aEnvoyer.copyWith(deposee: true));

    // Le premier enregistrement crée la fiche : `has_profile` passe à vrai
    // côté serveur, et le profil devient lisible au prochain démarrage.
    if (!(ref.read(utilisateurConnecteProvider)?.hasProfile ?? false)) {
      try {
        await ref.read(authControllerProvider.notifier).rafraichir();
      } on Object {
        // Sans incidence sur l'enregistrement qui vient d'aboutir.
      }
    }

    final Demande? serveur = await api.mien();
    if (serveur != null) state = AsyncData(serveur);
  }

  /// Téléverse photo et justificatifs, et recopie les `file_path` dans le dossier.
  Future<Demande> _rattacherLesPieces(Demande actuel) async {
    final PiecesEnAttente file = ref.read(piecesEnAttenteProvider);
    if (file.estVide) return actuel;

    final DemandeApi api = ref.read(demandeApiProvider);
    Demande suivant = actuel;

    final File? photo = file.photo;
    if (photo != null) {
      suivant = suivant.copyWith(photo: await api.deposerPhoto(photo));
    }

    final List<int> rangs = file.justificatifs.keys.toList()..sort();
    for (final int rang in rangs) {
      final FichierJoint piece = await api.deposerDiplome(
        file.justificatifs[rang]!,
      );
      suivant = suivant.avecJustificatif(rang, piece);
    }

    ref.read(piecesEnAttenteProvider.notifier).vider();
    state = AsyncData(suivant);
    return suivant;
  }

  /// Retire le justificatif d'une formation.
  ///
  /// Le contrat §6 n'expose **aucune suppression de justificatif** : seul le
  /// CV peut être retiré côté serveur. On détache donc la pièce de la
  /// formation et on laisse le prochain `PUT /candidat/formations` partir
  /// sans `diplome_file` pour cette ligne.
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

  /// Efface de l'appareil tout ce que l'utilisateur connecté y a laissé :
  /// brouillon, pièces choisies non envoyées et copies temporaires des
  /// fichiers. Appelé à la déconnexion volontaire, pour que le téléphone
  /// puisse passer à quelqu'un d'autre.
  Future<void> effacerLesDonneesLocales() async {
    _sauvegarde?.cancel();
    await ref.read(brouillonStoreProvider).purger();
    await ref.read(piecesEnAttenteProvider.notifier).effacer();
  }

  /// Abandonne les modifications locales et repart de l'état serveur.
  Future<void> abandonnerLeBrouillon() async {
    _sauvegarde?.cancel();
    await ref.read(brouillonStoreProvider).purger();
    ref.invalidateSelf();
  }
}

final demandeControllerProvider =
    AsyncNotifierProvider<DemandeController, Demande>(
      DemandeController.new,
      // Network failures are shown with an explicit retry action in the UI.
      retry: (_, _) => null,
    );

/// Vrai si une édition locale n'a pas encore été envoyée au serveur.
final brouillonEnAttenteProvider = Provider<bool>(
  (ref) => ref.watch(brouillonStoreProvider).lire() != null,
);
