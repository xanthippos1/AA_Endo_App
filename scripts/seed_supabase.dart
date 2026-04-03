import 'dart:convert';
import 'dart:io';

const supabaseUrl = 'https://mjaplyzvhffxuxhsioyp.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1qYXBseXp2aGZmeHV4aHNpb3lwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzc1NzcsImV4cCI6MjA5MDgxMzU3N30.UJXUzMLOJ-MGvfhcfHvIKWkF0X_GmZb909Z2oKKRPFY';

Future<void> main() async {
  final dataDir = Directory('data');
  final files = dataDir
      .listSync()
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('.json') &&
          f.uri.pathSegments.last.startsWith('Patient'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  print('Found ${files.length} patient files to seed.');

  final client = HttpClient();

  for (final file in files) {
    final jsonString = file.readAsStringSync();
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final patientId = data['patient_id'] as String;

    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/rest/v1/patients'),
    );
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('Content-Type', 'application/json; charset=utf-8');
    request.headers.set('Prefer', 'resolution=merge-duplicates');
    final bodyBytes = utf8.encode(json.encode({
      'patient_id': patientId,
      'source_type': 1,
      'data': data,
    }));
    request.contentLength = bodyBytes.length;
    request.add(bodyBytes);

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('  Seeded $patientId');
    } else {
      print('  FAILED $patientId: ${response.statusCode} $body');
    }
  }

  client.close();
  print('Done.');
}
