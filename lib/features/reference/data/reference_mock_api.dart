import '../domain/referentiel.dart';
import 'reference_api.dart';

/// Référentiel de développement.
///
/// **Régions, secteurs, niveaux d'études et handicaps sont les valeurs
/// réelles de la base** (§5.1 à §5.4), ids compris — y compris leurs
/// irrégularités : secteurs 1→15 puis 19, niveaux 1→10 puis 14→18, libellés
/// mal orthographiés qu'il ne faut pas « corriger » côté mobile.
///
/// Départements, emplois et pays sont en revanche un **échantillon** : la
/// base en compte 46, 491 et ~195. Assez pour exercer les cascades et la
/// recherche, pas pour recopier la base à la main.
class MockReferenceApi implements ReferenceApi {
  @override
  Future<Referentiel> bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const Referentiel(
      version: 'mock-2026-09-22',
      regions: _regions,
      departements: _departements,
      secteurs: _secteurs,
      emplois: _emplois,
      academics: _academics,
      handicaps: _handicaps,
      countries: _pays,
    );
  }
}

const List<Region> _regions = <Region>[
  Region(id: 1, libelle: 'Dakar'),
  Region(id: 2, libelle: 'Diourbel'),
  Region(id: 3, libelle: 'Fatick'),
  Region(id: 4, libelle: 'Kaffrine'),
  Region(id: 5, libelle: 'Kaolack'),
  Region(id: 6, libelle: 'Kédougou'),
  Region(id: 7, libelle: 'Kolda'),
  Region(id: 8, libelle: 'Louga'),
  Region(id: 9, libelle: 'Matam'),
  Region(id: 10, libelle: 'Saint-Louis'),
  Region(id: 11, libelle: 'Sédhiou'),
  Region(id: 12, libelle: 'Tambacounda'),
  Region(id: 13, libelle: 'Thiès'),
  Region(id: 14, libelle: 'Ziguinchor'),
  Region(id: 15, libelle: 'Hors Sénégal'), // aucun département rattaché
];

const List<Departement> _departements = <Departement>[
  Departement(id: 1, libelle: 'Dakar', regionId: 1),
  Departement(id: 2, libelle: 'Pikine', regionId: 1),
  Departement(id: 3, libelle: 'Guédiawaye', regionId: 1),
  Departement(id: 4, libelle: 'Rufisque', regionId: 1),
  Departement(id: 5, libelle: 'Keur Massar', regionId: 1),
  Departement(id: 6, libelle: 'Diourbel', regionId: 2),
  Departement(id: 7, libelle: 'Mbacké', regionId: 2),
  Departement(id: 8, libelle: 'Bambey', regionId: 2),
  Departement(id: 9, libelle: 'Saint-Louis', regionId: 10),
  Departement(id: 10, libelle: 'Dagana', regionId: 10),
  Departement(id: 11, libelle: 'Podor', regionId: 10),
  Departement(id: 12, libelle: 'Thiès', regionId: 13),
  Departement(id: 13, libelle: 'Mbour', regionId: 13),
  Departement(id: 14, libelle: 'Tivaouane', regionId: 13),
  Departement(id: 15, libelle: 'Ziguinchor', regionId: 14),
  Departement(id: 16, libelle: 'Bignona', regionId: 14),
  Departement(id: 17, libelle: 'Oussouye', regionId: 14),
];

const List<Secteur> _secteurs = <Secteur>[
  Secteur(id: 1, libelle: 'Affaires générales'),
  Secteur(id: 2, libelle: 'Agriculture / Elevage / Pêche'),
  Secteur(id: 3, libelle: 'BTP / Transport / Mécanique'),
  Secteur(id: 4, libelle: 'Documentation'),
  Secteur(id: 5, libelle: 'Education / Enseignement'),
  Secteur(id: 6, libelle: 'Finances'),
  Secteur(id: 7, libelle: 'Gestion / Comptabilité'),
  Secteur(id: 8, libelle: 'Industrie / Mines / Energies / Electricité / Hydraulique'),
  Secteur(id: 9, libelle: 'Informatique / Télécom / Téléservices'),
  Secteur(id: 10, libelle: 'Menuiserie / Peinture / Plomberie / Maçonnerie'),
  Secteur(id: 11, libelle: 'Planification'),
  Secteur(id: 12, libelle: 'Santé'),
  Secteur(id: 13, libelle: 'Science sociale / Affaire juridique'),
  Secteur(id: 14, libelle: 'Tourisme / Culture / Hotelerie'),
  Secteur(id: 15, libelle: 'Urbanisation / Envirronement / Eaux / Forêt'),
  Secteur(id: 19, libelle: 'Communication'),
];

const List<Emploi> _emplois = <Emploi>[
  Emploi(id: 1, libelle: 'Secrétaire administratif', secteurId: 1),
  Emploi(id: 2, libelle: 'Agent administratif', secteurId: 1),
  Emploi(id: 10, libelle: 'Ingénieur agronome', secteurId: 2),
  Emploi(id: 11, libelle: 'Technicien élevage', secteurId: 2),
  Emploi(id: 20, libelle: 'Conducteur de travaux', secteurId: 3),
  Emploi(id: 30, libelle: 'Documentaliste', secteurId: 4),
  Emploi(id: 40, libelle: 'Professeur de collège', secteurId: 5),
  Emploi(id: 41, libelle: 'Instituteur', secteurId: 5),
  Emploi(id: 45, libelle: 'Analyste financier', secteurId: 6),
  Emploi(id: 46, libelle: 'Inspecteur des impôts', secteurId: 6),
  Emploi(id: 50, libelle: 'Comptable', secteurId: 7),
  Emploi(id: 51, libelle: 'Contrôleur de gestion', secteurId: 7),
  Emploi(id: 60, libelle: 'Électrotechnicien', secteurId: 8),
  Emploi(id: 12, libelle: 'Développeur web', secteurId: 9),
  Emploi(id: 13, libelle: 'Administrateur systèmes et réseaux', secteurId: 9),
  Emploi(id: 14, libelle: 'Technicien support informatique', secteurId: 9),
  Emploi(id: 15, libelle: 'Analyste programmeur', secteurId: 9),
  Emploi(id: 70, libelle: 'Menuisier', secteurId: 10),
  Emploi(id: 80, libelle: 'Planificateur', secteurId: 11),
  Emploi(id: 90, libelle: 'Infirmier', secteurId: 12),
  Emploi(id: 91, libelle: 'Sage-femme', secteurId: 12),
  Emploi(id: 100, libelle: 'Juriste', secteurId: 13),
  Emploi(id: 110, libelle: 'Agent de tourisme', secteurId: 14),
  Emploi(id: 120, libelle: 'Agent des eaux et forêts', secteurId: 15),
  Emploi(id: 130, libelle: 'Chargé de communication', secteurId: 19),
];

const List<Academic> _academics = <Academic>[
  Academic(id: 1, libelle: 'Supérieur à BAC+5'),
  Academic(id: 2, libelle: 'Master 2'),
  Academic(id: 3, libelle: 'Master 1'),
  Academic(id: 4, libelle: 'Licence'),
  Academic(id: 5, libelle: 'BAC+2'),
  Academic(id: 6, libelle: 'BAC+1'),
  Academic(id: 7, libelle: 'BAC'),
  Academic(id: 8, libelle: 'DTS'),
  Academic(id: 9, libelle: 'BTS'),
  Academic(id: 10, libelle: 'BFEM'),
  Academic(id: 14, libelle: 'sansdiplome'),
  Academic(id: 15, libelle: 'CFEE'),
  Academic(id: 16, libelle: 'CAP'),
  Academic(id: 17, libelle: 'BT'),
  Academic(id: 18, libelle: 'Doctorat'),
];

const List<Handicap> _handicaps = <Handicap>[
  Handicap(id: 1, libelle: 'Handicap physique'),
  Handicap(id: 2, libelle: 'Handicap visuel'),
  Handicap(id: 3, libelle: 'Handicap mental'),
  Handicap(id: 4, libelle: "Un mélange de plusieurs types d'handicaps"),
];

const List<Pays> _pays = <Pays>[
  Pays(id: 1, name: 'Sénégal'),
  Pays(id: 2, name: 'Mali'),
  Pays(id: 3, name: 'Mauritanie'),
  Pays(id: 4, name: "Côte d'Ivoire"),
  Pays(id: 5, name: 'Guinée'),
  Pays(id: 6, name: 'Gambie'),
  Pays(id: 7, name: 'France'),
  Pays(id: 8, name: 'Maroc'),
  Pays(id: 9, name: 'Canada'),
  Pays(id: 10, name: 'Espagne'),
];
