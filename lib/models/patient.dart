class Patient {
  final String patientId;
  final Map<String, dynamic> identity;
  final List<dynamic> visits;
  final Map<String, dynamic> rawData;

  Patient({
    required this.patientId,
    required this.identity,
    required this.visits,
    required this.rawData,
  });

  String get name => identity['name'] ?? '';
  String get amka => identity['amka'] ?? '';
  String get dob => identity['dob'] ?? '';
  String get address => identity['address'] ?? '';
  String get phone => identity['phone'] ?? '';

  String get amkaLast4 => amka.replaceAll('*', '');

  Map<String, dynamic> get social => rawData['social'] ?? {};
  List<dynamic> get presentingIllness => rawData['presenting_illness'] ?? [];
  Map<String, dynamic> get referral => rawData['referral'] ?? {};
  List<dynamic> get medicalHistory => rawData['medical_history'] ?? [];
  Map<String, dynamic> get familyHistory => rawData['family_history'] ?? {};
  Map<String, dynamic> get gynecologicalHistory => rawData['gynecological_history'] ?? {};

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: json['patient_id'] ?? '',
      identity: json['identity'] ?? {},
      visits: json['visits'] ?? [],
      rawData: json,
    );
  }
}
