import 'dart:convert';

/// A single bodyweight log entry.
class WeightEntry {
  final DateTime date;
  final double weight; // kg

  WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight': weight,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
        date: DateTime.parse(j['date'] as String),
        weight: (j['weight'] as num).toDouble(),
      );
}

/// A saved progress photo (file path + when it was taken).
class ProgressPhoto {
  final String path;
  final DateTime date;
  final double? weightAtTime;

  ProgressPhoto({required this.path, required this.date, this.weightAtTime});

  Map<String, dynamic> toJson() => {
        'path': path,
        'date': date.toIso8601String(),
        'weightAtTime': weightAtTime,
      };

  factory ProgressPhoto.fromJson(Map<String, dynamic> j) => ProgressPhoto(
        path: j['path'] as String,
        date: DateTime.parse(j['date'] as String),
        weightAtTime: (j['weightAtTime'] as num?)?.toDouble(),
      );
}

/// Helpers to encode/decode lists.
String encodeWeights(List<WeightEntry> list) =>
    jsonEncode(list.map((e) => e.toJson()).toList());

List<WeightEntry> decodeWeights(String s) {
  final raw = jsonDecode(s) as List<dynamic>;
  return raw
      .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}

String encodePhotos(List<ProgressPhoto> list) =>
    jsonEncode(list.map((e) => e.toJson()).toList());

List<ProgressPhoto> decodePhotos(String s) {
  final raw = jsonDecode(s) as List<dynamic>;
  return raw
      .map((e) => ProgressPhoto.fromJson(e as Map<String, dynamic>))
      .toList();
}
