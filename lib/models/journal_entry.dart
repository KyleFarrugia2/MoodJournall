import 'package:flutter/material.dart';

class JournalEntry {
  final int? id;
  final String title;
  final String content;
  final Mood mood;
  final DateTime entryDate;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.entryDate,
    this.locationName,
    this.latitude,
    this.longitude,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mood': mood.name,
      'moodValue': mood.value,
      'entryDate': entryDate.toIso8601String(),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      mood: Mood.fromValue(map['moodValue'] as int),
      entryDate: DateTime.parse(map['entryDate'] as String),
      locationName: map['locationName'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      tags: (map['tags'] as String? ?? '').split(',').where((t) => t.isNotEmpty).toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  JournalEntry copyWith({
    int? id,
    String? title,
    String? content,
    Mood? mood,
    DateTime? entryDate,
    String? locationName,
    double? latitude,
    double? longitude,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      entryDate: entryDate ?? this.entryDate,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum Mood {
  terrible(0, '😢', 'Terrible', 0xFFE57373),
  bad(1, '😞', 'Bad', 0xFFFFB74D),
  okay(2, '😐', 'Okay', 0xFFFFF176),
  good(3, '🙂', 'Good', 0xFF81C784),
  excellent(4, '😄', 'Excellent', 0xFF4CAF50);

  final int value;
  final String emoji;
  final String label;
  final int color;

  const Mood(this.value, this.emoji, this.label, this.color);

  static Mood fromValue(int value) {
    return Mood.values.firstWhere(
      (mood) => mood.value == value,
      orElse: () => Mood.okay,
    );
  }

  Color get colorValue => Color(color);
}
