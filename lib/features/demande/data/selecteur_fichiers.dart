import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  /// §6.2 D5 — une photo de smartphone dépasse les 2 Mo acceptés par le
  /// serveur. On comprime par paliers **avant** l'envoi : laisser le serveur
  /// refuser, c'est faire attendre le candidat pour rien.
  Future<File> _sousLaLimite(File source) async {
    File courant = source;
    for (final int qualite in <int>[80, 62, 45, 30]) {
      if (courant.lengthSync() <= ReglesFichiers.tailleMaxOctets) break;

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
      allowedExtensions: ReglesFichiers.extensionsDocument.toList(),
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
  const PiecesEnAttente({
    this.photo,
    this.diplomes = const <File>[],
    this.cv = const <File>[],
  });

  final File? photo;
  final List<File> diplomes;
  final List<File> cv;

  bool get estVide => photo == null && diplomes.isEmpty && cv.isEmpty;

  int get nombre => (photo == null ? 0 : 1) + diplomes.length + cv.length;

  List<File> de(TypeFichier type) =>
      type == TypeFichier.diplome ? diplomes : cv;

  PiecesEnAttente avec(TypeFichier type, List<File> fichiers) =>
      type == TypeFichier.diplome
      ? PiecesEnAttente(photo: photo, diplomes: fichiers, cv: cv)
      : PiecesEnAttente(photo: photo, diplomes: diplomes, cv: fichiers);

  PiecesEnAttente avecPhoto(File? fichier) =>
      PiecesEnAttente(photo: fichier, diplomes: diplomes, cv: cv);
}

class PiecesEnAttenteController extends Notifier<PiecesEnAttente> {
  @override
  PiecesEnAttente build() => const PiecesEnAttente();

  void choisirPhoto(File fichier) => state = state.avecPhoto(fichier);

  void retirerPhoto() => state = state.avecPhoto(null);

  void ajouter(TypeFichier type, List<File> fichiers) =>
      state = state.avec(type, <File>[...state.de(type), ...fichiers]);

  void retirer(TypeFichier type, File fichier) => state = state.avec(
    type,
    state.de(type).where((f) => f.path != fichier.path).toList(),
  );

  void vider() => state = const PiecesEnAttente();
}

final piecesEnAttenteProvider =
    NotifierProvider<PiecesEnAttenteController, PiecesEnAttente>(
      PiecesEnAttenteController.new,
    );
