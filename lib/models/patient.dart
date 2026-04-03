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

  String get amkaLast4 => identity['amka4'] ?? '';

  Map<String, dynamic> get social => rawData['social'] ?? {};
  List<dynamic> get presentingIllness => rawData['presenting_illness'] ?? [];
  Map<String, dynamic> get referral => rawData['referral'] ?? {};
  List<dynamic> get medicalHistory => rawData['medical_history'] ?? [];
  Map<String, dynamic> get familyHistory => rawData['family_history'] ?? {};
  Map<String, dynamic> get gynecologicalHistory => rawData['gynecological_history'] ?? {};

  factory Patient.fromJson(Map<String, dynamic> json) {
    final cast = _deepCast(json);
    return Patient(
      patientId: cast['patient_id'] ?? '',
      identity: cast['identity'] ?? {},
      visits: cast['visits'] ?? [],
      rawData: cast,
    );
  }

  static Map<String, dynamic> _deepCast(Map data) {
    return data.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepCast(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _deepCastList(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  static List<dynamic> _deepCastList(List data) {
    return data.map((item) {
      if (item is Map) return _deepCast(item);
      if (item is List) return _deepCastList(item);
      return item;
    }).toList();
  }
}
