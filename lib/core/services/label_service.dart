import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';

class LabelService {
  static Map<String, String> _labels = {};

  static Future<void> load() async {
    try {
      final jsonString = await rootBundle.loadString('data/labels.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      _labels = data.map((key, value) => MapEntry(key, value.toString()));
      log('Loaded ${_labels.length} labels');
    } catch (e) {
      log('Error loading labels: $e');
    }
  }

  /// Returns the Greek label for a JSON key, or falls back to the key itself.
  static String get(String key) => _labels[key] ?? key;
}
