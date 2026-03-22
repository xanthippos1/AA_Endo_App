import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import '../../models/patient.dart';

class PatientService {
  static final List<String> _assetFiles = [
    'data/Patient001_1_data.v10.json',
    'data/Patient004_1_data_v10.json',
    'data/Patient005_1_data_v10.json',
  ];

  Future<List<Patient>> loadAllPatients() async {
    final patients = <Patient>[];
    for (final path in _assetFiles) {
      try {
        final jsonString = await rootBundle.loadString(path);
        final data = json.decode(jsonString) as Map<String, dynamic>;
        patients.add(Patient.fromJson(data));
      } catch (e) {
        log('Error loading $path: $e');
      }
    }
    return patients;
  }

  Future<List<Patient>> searchByAmka(String last4) async {
    final patients = await loadAllPatients();
    return patients.where((p) => p.amkaLast4 == last4).toList();
  }

  /// Returns how many JPEG images exist for the given patient ID.
  /// Images follow the pattern: jpeg_images/PatientXXX_N.jpg
  /// Tries loading sequentially from 1 until one fails.
  static Future<int> getImageCount(String patientId) async {
    int count = 0;
    for (int i = 1; i <= 20; i++) {
      try {
        final path = 'jpeg_images/${patientId}_$i.jpg';
        await rootBundle.load(path);
        count = i;
      } catch (_) {
        break;
      }
    }
    log('Image count for $patientId: $count');
    return count;
  }
}
