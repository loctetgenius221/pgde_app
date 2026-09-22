import '../../domain/demande.dart';

/// Applique une transformation au dossier en cours d'édition.
///
/// Les écrans d'étape ne détiennent aucun état : ils reçoivent le dossier et
/// cette fonction. Toute écriture passe donc par le contrôleur — et par la
/// sauvegarde du brouillon qu'il déclenche (§8.8).
typedef Modification = void Function(Demande Function(Demande) transformation);
