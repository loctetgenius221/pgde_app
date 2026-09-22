import 'package:json_annotation/json_annotation.dart';

/// Date sans heure, au format attendu par Laravel : `YYYY-MM-DD` (§4, §8.9).
///
/// `DateTime` sérialisé par défaut produit un ISO-8601 complet, que la règle
/// `date` de Laravel accepte mais qui pollue la base d'une heure fictive.
class DateOnlyConverter implements JsonConverter<DateTime?, String?> {
  const DateOnlyConverter();

  @override
  DateTime? fromJson(String? json) =>
      (json == null || json.isEmpty) ? null : DateTime.tryParse(json);

  @override
  String? toJson(DateTime? date) => date == null
      ? null
      : '${date.year.toString().padLeft(4, '0')}'
            '-${date.month.toString().padLeft(2, '0')}'
            '-${date.day.toString().padLeft(2, '0')}';
}
