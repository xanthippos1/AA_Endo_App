import 'dart:convert';
import 'dart:io';

/// Scans the data/ directory for patient JSON files and writes
/// data/patient_manifest.json so the app can discover them at runtime.
void main() {
  final dataDir = Directory('data');
  if (!dataDir.existsSync()) {
    stderr.writeln('Error: data/ directory not found. Run from project root.');
    exit(1);
  }

  final patientFiles = dataDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json') && f.uri.pathSegments.last.startsWith('Patient'))
      .map((f) => 'data/${f.uri.pathSegments.last}')
      .toList()
    ..sort();

  final manifest = jsonEncode(patientFiles);
  File('data/patient_manifest.json').writeAsStringSync(manifest);
  print('Wrote ${patientFiles.length} entries to data/patient_manifest.json');
}
