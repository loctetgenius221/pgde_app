import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_controller.dart';
import '../domain/demande.dart';
import '../domain/regles_fichiers.dart';

enum SourcePhoto { appareilPhoto, galerie }

/// Choix d'une pièce sur l'appareil.
///
/// Derrière une interface, parce que les sélecteurs natifs passent par des
/// canaux de plateforme : sans elle, aucun écran manipulant des pièces ne
/// serait testable.
abstract interface class SelecteurFichiers {
  Future<File?> photo({required SourcePhoto source});

  Future<List<File>> documents();
}

class SelecteurFichiersAppareil implements SelecteurFichiers {
  final ImagePicker _appareil = ImagePicker();

  @override
  Future<File?> photo({required SourcePhoto source}) async {
    final XFile? choisie = await _appareil.pickImage(
      source: source == SourcePhoto.appareilPhoto
          ? ImageSource.camera
          : ImageSource.gallery,
      // Première réduction, faite par le sélecteur lui-même : une photo de
      // profil n'a pas besoin de la définition du capteur.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    return choisie == null ? null : _sousLaLimite(File(choisie.path));
  }

  /// Une photo de smartphone dépasse les 4 Mo acceptés par le serveur
  /// (contrat §6.1). On comprime par paliers **avant** l'envoi : laisser le
  /// serveur refuser, c'est faire attendre le candidat pour rien.
  Future<File> _sousLaLimite(File source) async {
    File courant = source;
    for (final int qualite in <int>[80, 62, 45, 30]) {
      if (courant.lengthSync() <= ReglesFichiers.tailleMaxPhoto) break;

      final Uint8List? comprimee = await FlutterImageCompress.compressWithFile(
        courant.path,
        quality: qualite,
        minWidth: 1280,
        minHeight: 1280,
      );
      if (comprimee == null) break;

      // Le fichier choisi vit déjà dans un cache applicatif inscriptible :
      // on y dépose la version comprimée, sans dépendance supplémentaire.
      courant = await File(
        '${source.parent.path}/photo_$qualite.jpg',
      ).writeAsBytes(comprimee, flush: true);
    }
    return courant;
  }

  @override
  Future<List<File>> documents() async {
    final List<PlatformFile> choisis = await FilePicker.pickFiles(
      dialogTitle: 'Choisir vos documents',
      type: FileType.custom,
      // Le sélecteur natif filtre déjà ; `ReglesFichiers` revérifie ensuite,
      // car tous les systèmes ne respectent pas ce filtre.
      allowedExtensions: ReglesFichiers.extensionsAdmises(
        TypeFichier.diplome,
      ).toList(),
    );
    return choisis
        .map((PlatformFile f) => f.path)
        .nonNulls
        .map(File.new)
        .toList();
  }
}

final selecteurFichiersProvider = Provider<SelecteurFichiers>(
  (ref) => SelecteurFichiersAppareil(),
);

/// Pièces choisies sur l'appareil mais pas encore déposées sur le serveur.
///
/// Le formulaire web envoie les fichiers **avec** le dossier (§7.7b), et les
/// endpoints dédiés (§7.5) ne servent qu'à l'édition. Plutôt que deux
/// comportements selon que le dossier existe ou non, l'app suit une règle
/// unique : on met en file, et tout part à l'enregistrement.
class PiecesEnAttente {
  const PiecesEnAttente({this.photo, this.justificatifs = const <int, File>{}});

  final File? photo;

  /// Justificatifs choisis, indexés par le **rang de la formation** qu'ils
  /// prouvent. Un seul par formation : c'est un justificatif, pas un dossier.
  final Map<int, File> justificatifs;

  bool get estVide => photo == null && justificatifs.isEmpty;

  int get nombre => (photo == null ? 0 : 1) + justificatifs.length;

  PiecesEnAttente avecPhoto(File? fichier) =>
      PiecesEnAttente(photo: fichier, justificatifs: justificatifs);

  PiecesEnAttente avecJustificatifs(Map<int, File> fichiers) =>
      PiecesEnAttente(photo: photo, justificatifs: fichiers);
}

class PiecesEnAttenteController extends Notifier<PiecesEnAttente> {
  @override
  PiecesEnAttente build() {
    // Un changement de compte vide la file : les pièces choisies par un
    // candidat ne doivent jamais partir sur le dossier du suivant.
    ref.watch(utilisateurConnecteProvider.select((u) => u?.id));
    return const PiecesEnAttente();
  }

  void choisirPhoto(File fichier) => state = state.avecPhoto(fichier);

  void retirerPhoto() => state = state.avecPhoto(null);

  void choisirJustificatif(int rang, File fichier) => state = state
      .avecJustificatifs(<int, File>{...state.justificatifs, rang: fichier});

  void retirerJustificatif(int rang) => state = state.avecJustificatifs(
    <int, File>{...state.justificatifs}..remove(rang),
  );

  /// Une formation retirée décale toutes celles qui la suivaient : les
  /// justificatifs encore en file doivent suivre le mouvement, sinon ils
  /// partiraient rattachés à la mauvaise formation.
  void retirerFormation(int rang) {
    final Map<int, File> suivant = <int, File>{};
    state.justificatifs.forEach((int r, File fichier) {
      if (r < rang) suivant[r] = fichier;
      if (r > rang) suivant[r - 1] = fichier;
    });
    state = state.avecJustificatifs(suivant);
  }

  void vider() => state = const PiecesEnAttente();

  /// Vide la file **et** supprime les fichiers de l'appareil.
  ///
  /// Les sélecteurs natifs copient chaque pièce choisie dans le cache de
  /// l'application ; ces copies (photo d'identité, diplômes) survivraient
  /// sinon au départ de leur propriétaire.
  Future<void> effacer() async {
    final List<File> fichiers = <File>[
      ?state.photo,
      ...state.justificatifs.values,
    ];
    vider();
    for (final File fichier in fichiers) {
      try {
        if (fichier.existsSync()) await fichier.delete();
      } on FileSystemException {
        // Déjà supprimé ou inaccessible : rien de plus à faire.
      }
    }
    try {
      await FilePicker.clearTemporaryFiles();
    } on Object {
      // Plateforme sans cache de sélection : sans objet.
    }
  }
}

final piecesEnAttenteProvider =
    NotifierProvider<PiecesEnAttenteController, PiecesEnAttente>(
      PiecesEnAttenteController.new,
    );
