import 'dart:developer';
import 'package:flutter/services.dart';
import '../../models/patient.dart';
import 'supabase_service.dart';

class PatientService {
  Future<List<Patient>> loadAllPatients() async {
    try {
      final response = await SupabaseService.client
          .from('patients')
          .select()
          .order('patient_id');
      return (response as List)
          .map((row) => Patient.fromJson(row['data'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Error loading patients from Supabase: $e');
      return [];
    }
  }

  Future<List<Patient>> searchByAmka(String last4) async {
    final patients = await loadAllPatients();
    return patients.where((p) => p.amkaLast4 == last4).toList();
  }

  Future<void> savePatient(Patient patient) async {
    try {
      await SupabaseService.client.from('patients').upsert({
        'patient_id': patient.patientId,
        'source_type': patient.rawData['_source_type'] ?? 1,
        'data': patient.rawData,
      }, onConflict: 'patient_id');
      log('Saved patient ${patient.patientId}');
    } catch (e) {
      log('Error saving patient: $e');
      rethrow;
    }
  }

  /// Returns the next available patient ID number.
  Future<int> getNextPatientNumber() async {
    try {
      final response = await SupabaseService.client
          .from('patients')
          .select('patient_id')
          .order('patient_id');
      final ids = (response as List).map((r) => r['patient_id'] as String);
      int max = 0;
      for (final id in ids) {
        final num = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (num > max) max = num;
      }
      return max + 1;
    } catch (e) {
      log('Error getting next patient number: $e');
      return 999;
    }
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
