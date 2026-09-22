import '../../../core/network/api_exception.dart';
import '../domain/demande.dart';
import 'demande_api.dart';
import 'demande_mapper.dart';

/// Faux backend du dossier, tant que `/api/v1` n'existe pas.
///
/// Il **fait transiter les données par la correspondance réelle** — `versCorps`
/// puis `depuisApi` — au lieu de renvoyer l'objet reçu. Un mock complaisant
/// masquerait les pertes de conversion ; celui-ci les révèle dès maintenant.
class MockDemandeApi implements DemandeApi {
  static const Duration _latence = Duration(milliseconds: 500);

  static Demande? _dossier;

  @override
  Future<Demande?> mien() async {
    await Future<void>.delayed(_latence);
    return _dossier;
  }

  @override
  Future<Demande> creer(Demande demande) async {
    await Future<void>.delayed(_latence);
    if (_dossier != null) {
      // §2.1 : `utilisateur_id` est UNIQUE. Un second POST déclenche une
      // erreur SQL 1062 côté serveur, que l'API doit traduire en 409.
      throw const ApiException(
        'Vous avez déjà une demande enregistrée.',
        statusCode: 409,
      );
    }
    return _dossier = _allerRetour(demande, id: 1369020);
  }

  @override
  Future<Demande> mettreAJour(Demande demande) async {
    await Future<void>.delayed(_latence);
    if (_dossier == null) {
      throw const ApiException('Dossier introuvable.', statusCode: 404);
    }
    return _dossier = _allerRetour(demande, id: _dossier!.id);
  }

  /// Simule le trajet complet : sérialisation vers le serveur, puis lecture de
  /// la réponse. Ce qui ne survit pas au trajet ne survivra pas en production.
  Demande _allerRetour(Demande demande, {int? id}) {
    final corps = DemandeMapper.versCorps(demande);
    return DemandeMapper.depuisApi(<String, dynamic>{
      'id': id,
      'identite': <String, dynamic>{
        'datenaiss': corps['datenaiss'],
        'lieunaiss': corps['lieunaiss'],
        'lieuresidence': corps['lieuresidence'],
        'addresse': corps['addresse'],
        'genre': corps['genre'],
        'situationmatrimoniale': corps['situationmatrimoniale'],
        'telephone1': corps['telephone1'],
        'telephone2': corps['telephone2'],
        'nombreenfant': corps['nombreenfant'],
        'pays': corps['country_id'],
        'naissance': <String, dynamic>{
          'region': corps['regionnaiss_id'],
          'departement': corps['departementnaiss_id'],
        },
        'residence': <String, dynamic>{
          'region': corps['regionresidence_id'],
          'departement': corps['departementresidence_id'],
        },
        'handicap': corps['handicap_id'],
      },
      'formations': corps['formations'],
      'has_experience': corps['hasExperience'] == 'oui',
      'experiences': corps['experiences'],
      'voeux': <String, dynamic>{
        'emploi1': <String, dynamic>{
          'id': corps['emploi1_id'],
          'annees': corps['anneeexperience1'],
        },
        'emploi2': <String, dynamic>{
          'id': corps['emploi2_id'],
          'annees': corps['anneeexperience2'],
        },
      },
      'cv_summary': corps['cv_summary'],
    });
  }
}
