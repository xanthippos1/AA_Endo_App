import 'dart:developer';
import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../core/services/patient_service.dart';

class NewPatientPage extends StatefulWidget {
  final void Function(Patient patient)? onPatientSaved;

  const NewPatientPage({super.key, this.onPatientSaved});

  @override
  State<NewPatientPage> createState() => _NewPatientPageState();
}

class _NewPatientPageState extends State<NewPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();
  bool _saving = false;
  bool _searching = false;
  bool _formVisible = false;
  Patient? _existingPatient;

  // Stores original values from existing patient to detect changes
  final Map<String, String> _originalValues = {};

  // Identity fields
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amkaController = TextEditingController();

  // Social fields
  final _professionController = TextEditingController();
  final _smokingController = TextEditingController();
  final _alcoholController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Presenting illness
  final _presentingIllnessController = TextEditingController();

  // Referral fields
  final _referralFromController = TextEditingController();
  final _referralRelationController = TextEditingController();

  // Expandable section visibility
  bool _medicalHistoryExpanded = false;
  bool _familyHistoryExpanded = false;
  bool _medicationExpanded = false;

  // Medical history rows: each row has {item, detail} controllers
  final List<_MedicalHistoryRow> _medicalHistoryRows = [];

  // Family history controllers
  final _fatherAgeController = TextEditingController();
  final _fatherStatusController = TextEditingController();
  final _fatherConditionsController = TextEditingController();
  final _motherAgeController = TextEditingController();
  final _motherStatusController = TextEditingController();
  final _motherConditionsController = TextEditingController();
  final _spouseStatusController = TextEditingController();
  final _spouseConditionsController = TextEditingController();
  final List<_SiblingRow> _siblingRows = [];

  // Latest medication rows: each row has {name, dose, frequency} controllers
  final List<_MedicationRow> _medicationRows = [];

  List<TextEditingController> get _allFieldControllers => [
        _nameController,
        _dobController,
        _addressController,
        _phoneController,
        _professionController,
        _smokingController,
        _alcoholController,
        _allergiesController,
        _presentingIllnessController,
        _referralFromController,
        _referralRelationController,
      ];

  @override
  void dispose() {
    _amkaController.dispose();
    for (final c in _allFieldControllers) {
      c.dispose();
    }
    _fatherAgeController.dispose();
    _fatherStatusController.dispose();
    _fatherConditionsController.dispose();
    _motherAgeController.dispose();
    _motherStatusController.dispose();
    _motherConditionsController.dispose();
    _spouseStatusController.dispose();
    _spouseConditionsController.dispose();
    for (final row in _medicalHistoryRows) {
      row.dispose();
    }
    for (final row in _siblingRows) {
      row.dispose();
    }
    for (final row in _medicationRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _lookupAmka() async {
    final amka = _amkaController.text.trim();
    if (amka.isEmpty) return;

    setState(() => _searching = true);

    try {
      final found = await _patientService.findByFullAmka(amka);

      if (found != null) {
        _existingPatient = found;
        _populateFromPatient(found);
      } else {
        _existingPatient = null;
        _clearFields();
      }

      setState(() {
        _formVisible = true;
        _searching = false;
      });
    } catch (e) {
      log('Error looking up AMKA: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Σφάλμα αναζήτησης: $e')),
        );
      }
      setState(() => _searching = false);
    }
  }

  void _populateFromPatient(Patient patient) {
    final identity = patient.identity;
    final social = patient.social;
    final referral = patient.referral;
    final illness = patient.presentingIllness;

    _nameController.text = identity['name'] ?? '';
    _dobController.text = identity['dob'] ?? '';
    _addressController.text = identity['address'] ?? '';
    _phoneController.text = identity['phone'] ?? '';

    _professionController.text = social['profession'] ?? '';
    final smoking = social['smoking'] ?? '';
    _smokingController.text = smoking == 'Ø' ? '' : smoking;
    final alcohol = social['alcohol'] ?? '';
    _alcoholController.text = alcohol == 'Ø' ? '' : alcohol;
    final allergies = social['allergies'];
    _allergiesController.text =
        allergies is List ? allergies.join(', ') : (allergies ?? '').toString();

    _presentingIllnessController.text = illness.join('\n');

    _referralFromController.text = referral['from'] ?? '';
    _referralRelationController.text = referral['relation'] ?? '';

    // Populate medical history
    _medicalHistoryRows.clear();
    final medHist = patient.medicalHistory;
    for (final entry in medHist) {
      final row = _MedicalHistoryRow();
      row.itemController.text = (entry['item'] ?? '').toString();
      row.detailController.text = (entry['detail'] ?? '').toString();
      row.originalItem = row.itemController.text;
      row.originalDetail = row.detailController.text;
      _medicalHistoryRows.add(row);
    }

    // Populate family history
    final fam = patient.familyHistory;
    final father = fam['father'] as Map<String, dynamic>? ?? {};
    _fatherAgeController.text = (father['age'] ?? '').toString();
    _fatherStatusController.text = father['status'] ?? '';
    final fatherConds = father['conditions'];
    _fatherConditionsController.text =
        fatherConds is List ? fatherConds.join(', ') : '';

    final mother = fam['mother'] as Map<String, dynamic>? ?? {};
    _motherAgeController.text = (mother['age'] ?? '').toString();
    _motherStatusController.text = mother['status'] ?? '';
    final motherConds = mother['conditions'];
    _motherConditionsController.text =
        motherConds is List ? motherConds.join(', ') : '';

    final spouse = fam['spouse'] as Map<String, dynamic>? ?? {};
    _spouseStatusController.text = spouse['status'] ?? '';
    final spouseConds = spouse['conditions'];
    _spouseConditionsController.text =
        spouseConds is List ? spouseConds.join(', ') : '';

    _siblingRows.clear();
    final siblings = fam['siblings'] as List? ?? [];
    for (final sib in siblings) {
      final row = _SiblingRow();
      row.relationController.text = (sib['relation'] ?? '').toString();
      row.ageController.text = (sib['age'] ?? '').toString();
      final sibConds = sib['conditions'];
      row.conditionsController.text =
          sibConds is List ? sibConds.join(', ') : '';
      row.originalRelation = row.relationController.text;
      row.originalAge = row.ageController.text;
      row.originalConditions = row.conditionsController.text;
      _siblingRows.add(row);
    }

    // Populate latest medication
    _medicationRows.clear();
    final meds = patient.rawData['latest_medication'] as List? ?? [];
    for (final med in meds) {
      final row = _MedicationRow();
      row.nameController.text = (med['name'] ?? '').toString();
      row.doseController.text = (med['dose'] ?? '').toString();
      row.frequencyController.text = (med['frequency'] ?? '').toString();
      row.originalName = row.nameController.text;
      row.originalDose = row.doseController.text;
      row.originalFrequency = row.frequencyController.text;
      _medicationRows.add(row);
    }

    // Store original values for change detection
    _originalValues.clear();
    for (final entry in _controllerMap.entries) {
      _originalValues[entry.key] = entry.value.text;
    }
    for (final entry in _familyControllerMap.entries) {
      _originalValues[entry.key] = entry.value.text;
    }
  }

  Map<String, TextEditingController> get _controllerMap => {
        'name': _nameController,
        'dob': _dobController,
        'address': _addressController,
        'phone': _phoneController,
        'profession': _professionController,
        'smoking': _smokingController,
        'alcohol': _alcoholController,
        'allergies': _allergiesController,
        'illness': _presentingIllnessController,
        'referralFrom': _referralFromController,
        'referralRelation': _referralRelationController,
      };

  Map<String, TextEditingController> get _familyControllerMap => {
        'fatherAge': _fatherAgeController,
        'fatherStatus': _fatherStatusController,
        'fatherConditions': _fatherConditionsController,
        'motherAge': _motherAgeController,
        'motherStatus': _motherStatusController,
        'motherConditions': _motherConditionsController,
        'spouseStatus': _spouseStatusController,
        'spouseConditions': _spouseConditionsController,
      };

  void _clearFields() {
    for (final c in _allFieldControllers) {
      c.clear();
    }
    _originalValues.clear();
    _medicalHistoryRows.clear();
    _fatherAgeController.clear();
    _fatherStatusController.clear();
    _fatherConditionsController.clear();
    _motherAgeController.clear();
    _motherStatusController.clear();
    _motherConditionsController.clear();
    _spouseStatusController.clear();
    _spouseConditionsController.clear();
    _siblingRows.clear();
    _medicationRows.clear();
  }

  void _resetAll() {
    _amkaController.clear();
    _clearFields();
    setState(() {
      _formVisible = false;
      _existingPatient = null;
      _medicalHistoryExpanded = false;
      _familyHistoryExpanded = false;
      _medicationExpanded = false;
    });
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      String patientId;
      if (_existingPatient != null) {
        patientId = _existingPatient!.patientId;
      } else {
        final nextNumber = await _patientService.getNextPatientNumber();
        patientId = 'Patient${nextNumber.toString().padLeft(3, '0')}';
      }

      final allergiesText = _allergiesController.text.trim();
      final allergies = allergiesText.isEmpty
          ? <String>[]
          : allergiesText.split(',').map((a) => a.trim()).toList();

      final illnessText = _presentingIllnessController.text.trim();
      final illnesses = illnessText.isEmpty
          ? <String>[]
          : illnessText
              .split('\n')
              .map((line) => line.trim())
              .where((l) => l.isNotEmpty)
              .toList();

      // Build medical history
      final medicalHistory = _medicalHistoryRows
          .where((r) => r.itemController.text.trim().isNotEmpty)
          .map((r) => {
                'item': r.itemController.text.trim(),
                'detail': r.detailController.text.trim(),
              })
          .toList();

      // Build family history
      final familyHistory = <String, dynamic>{
        ...(_existingPatient?.familyHistory ?? {}),
      };
      if (_fatherAgeController.text.trim().isNotEmpty ||
          _fatherConditionsController.text.trim().isNotEmpty) {
        familyHistory['father'] = {
          'age': int.tryParse(_fatherAgeController.text.trim()) ??
              _fatherAgeController.text.trim(),
          'status': _fatherStatusController.text.trim(),
          'conditions': _splitComma(_fatherConditionsController.text),
        };
      }
      if (_motherAgeController.text.trim().isNotEmpty ||
          _motherConditionsController.text.trim().isNotEmpty) {
        familyHistory['mother'] = {
          'age': int.tryParse(_motherAgeController.text.trim()) ??
              _motherAgeController.text.trim(),
          'status': _motherStatusController.text.trim(),
          'conditions': _splitComma(_motherConditionsController.text),
        };
      }
      if (_spouseConditionsController.text.trim().isNotEmpty) {
        familyHistory['spouse'] = {
          'status': _spouseStatusController.text.trim(),
          'conditions': _splitComma(_spouseConditionsController.text),
        };
      }
      if (_siblingRows.isNotEmpty) {
        familyHistory['siblings'] = _siblingRows
            .where((r) => r.relationController.text.trim().isNotEmpty)
            .map((r) => {
                  'relation': r.relationController.text.trim(),
                  'age': int.tryParse(r.ageController.text.trim()) ??
                      r.ageController.text.trim(),
                  'conditions': _splitComma(r.conditionsController.text),
                })
            .toList();
      }

      // Build latest medication
      final latestMedication = _medicationRows
          .where((r) => r.nameController.text.trim().isNotEmpty)
          .map((r) {
        final m = <String, dynamic>{
          'name': r.nameController.text.trim(),
        };
        if (r.doseController.text.trim().isNotEmpty) {
          m['dose'] = r.doseController.text.trim();
        }
        if (r.frequencyController.text.trim().isNotEmpty) {
          m['frequency'] = r.frequencyController.text.trim();
        }
        return m;
      }).toList();

      // Start from existing rawData if editing, to preserve fields we don't show
      final rawData = <String, dynamic>{
        ...(_existingPatient?.rawData ?? {}),
        '_schema': 'endo-data-v1',
        'patient_id': patientId,
        '_source_type': 2,
        'generated': DateTime.now().toIso8601String().split('T').first,
        'version': 'v10',
        'identity': {
          ...(_existingPatient?.identity ?? {}),
          'name': _nameController.text.trim(),
          'dob': _dobController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'amka': _amkaController.text.trim(),
          'amka4': _amkaController.text.trim().length >= 4
              ? _amkaController.text
                  .trim()
                  .substring(_amkaController.text.trim().length - 4)
              : _amkaController.text.trim(),
        },
        'social': {
          ...(_existingPatient?.social ?? {}),
          'profession': _professionController.text.trim(),
          'smoking': _smokingController.text.trim().isEmpty
              ? 'Ø'
              : _smokingController.text.trim(),
          'alcohol': _alcoholController.text.trim().isEmpty
              ? 'Ø'
              : _alcoholController.text.trim(),
          'allergies': allergies,
        },
        'presenting_illness': illnesses,
        'referral': {
          ...(_existingPatient?.referral ?? {}),
          'from': _referralFromController.text.trim(),
          'relation': _referralRelationController.text.trim(),
        },
        'medical_history': medicalHistory,
        'family_history': familyHistory,
        'latest_medication': latestMedication,
      };

      final patient = Patient.fromJson(rawData);
      await _patientService.savePatient(patient);

      log('Patient saved: $patientId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$patientId αποθηκεύτηκε')),
        );
        widget.onPatientSaved?.call(patient);
        _resetAll();
      }
    } catch (e) {
      log('Error saving patient: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Σφάλμα αποθήκευσης: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _splitComma(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];
    return trimmed.split(',').map((s) => s.trim()).toList();
  }

  /// Returns yellow if the field was changed from its original value,
  /// null (default white) otherwise.
  Color? _textColorFor(String key) {
    if (_existingPatient == null) return null;
    final original = _originalValues[key] ?? '';
    final current =
        _controllerMap[key]?.text ?? _familyControllerMap[key]?.text ?? '';
    if (current != original) return Colors.yellow;
    return null;
  }

  /// Builds a TextFormField that turns yellow when its value differs from original.
  Widget _trackedField({
    required String trackingKey,
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return TextFormField(
          controller: controller,
          style: TextStyle(color: _textColorFor(trackingKey)),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _existingPatient != null ? 'ΕΠΕΞΕΡΓΑΣΙΑ ΑΣΘΕΝΗ' : 'ΝΕΟΣ ΑΣΘΕΝΗΣ',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildAmkaLookup(),
          if (_formVisible) ...[
            const SizedBox(height: 16),
            _buildIdentityCard(),
            const SizedBox(height: 16),
            _buildSocialCard(),
            const SizedBox(height: 16),
            _buildPresentingIllnessCard(),
            const SizedBox(height: 16),
            _buildReferralCard(),
            const SizedBox(height: 24),
            _buildExpandableButton(
              label: 'ΙΣΤΟΡΙΚΟ',
              expanded: _medicalHistoryExpanded,
              onPressed: () => setState(
                  () => _medicalHistoryExpanded = !_medicalHistoryExpanded),
            ),
            if (_medicalHistoryExpanded) ...[
              const SizedBox(height: 8),
              _buildMedicalHistoryCard(),
            ],
            const SizedBox(height: 12),
            _buildExpandableButton(
              label: 'ΟΙΚ. ΙΣΤ.',
              expanded: _familyHistoryExpanded,
              onPressed: () => setState(
                  () => _familyHistoryExpanded = !_familyHistoryExpanded),
            ),
            if (_familyHistoryExpanded) ...[
              const SizedBox(height: 8),
              _buildFamilyHistoryCard(),
            ],
            const SizedBox(height: 12),
            _buildExpandableButton(
              label: 'ΑΓΩΓΗ',
              expanded: _medicationExpanded,
              onPressed: () =>
                  setState(() => _medicationExpanded = !_medicationExpanded),
            ),
            if (_medicationExpanded) ...[
              const SizedBox(height: 8),
              _buildMedicationCard(),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _resetAll,
                    child: const Text('ΚΑΘΑΡΙΣΜΟΣ'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _savePatient,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'ΑΠΟΘΗΚΕΥΣΗ...' : 'ΑΠΟΘΗΚΕΥΣΗ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableButton({
    required String label,
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildAmkaLookup() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amkaController,
                decoration: const InputDecoration(
                  labelText: 'AMKA',
                  hintText: 'Εισάγετε AMKA και πατήστε Enter',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: !_formVisible,
                onSubmitted: (_) => _lookupAmka(),
              ),
            ),
            const SizedBox(width: 12),
            if (_searching)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (!_formVisible)
              IconButton(
                onPressed: _lookupAmka,
                icon: const Icon(Icons.search),
                tooltip: 'Αναζήτηση',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ΣΤΟΙΧΕΙΑ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _trackedField(
              trackingKey: 'name',
              controller: _nameController,
              label: 'ΟΝΟΜΑ',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Υποχρεωτικό πεδίο' : null,
            ),
            const SizedBox(height: 12),
            _trackedField(
              trackingKey: 'dob',
              controller: _dobController,
              label: 'ΗΜ. ΓΕΝ.',
              hint: 'ΗΗ/MM/ΕΕΕΕ',
            ),
            const SizedBox(height: 12),
            _trackedField(
              trackingKey: 'address',
              controller: _addressController,
              label: 'ΚΑΤΟΙΚΙΑ',
            ),
            const SizedBox(height: 12),
            _trackedField(
              trackingKey: 'phone',
              controller: _phoneController,
              label: 'ΤΗΛ.',
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ΚΟΙΝΩΝΙΚΑ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _trackedField(
              trackingKey: 'profession',
              controller: _professionController,
              label: 'ΕΡΓΑΣΙΑ',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _trackedField(
                    trackingKey: 'smoking',
                    controller: _smokingController,
                    label: 'ΚΑΠΝΙΣΜΑ',
                    hint: 'π.χ. 10/ημέρα ή κενό για Ø',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _trackedField(
                    trackingKey: 'alcohol',
                    controller: _alcoholController,
                    label: 'ΑΛΚΟΟΛ',
                    hint: 'π.χ. κοινωνικό ή κενό για Ø',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _trackedField(
              trackingKey: 'allergies',
              controller: _allergiesController,
              label: 'ΑΛΛΕΡΓΙΑ',
              hint: 'Χωρισμένες με κόμμα',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentingIllnessCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ΠΑΡΟΥΣΑ ΝΟΣΟΣ',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _trackedField(
              trackingKey: 'illness',
              controller: _presentingIllnessController,
              label: 'Παθήσεις',
              hint: 'Μία ανά γραμμή',
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ΠΑΡΑΠΟΜΠΗ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _trackedField(
                    trackingKey: 'referralFrom',
                    controller: _referralFromController,
                    label: 'Από',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _trackedField(
                    trackingKey: 'referralRelation',
                    controller: _referralRelationController,
                    label: 'Σχέση',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Medical History Section ──

  Widget _buildMedicalHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ΙΣΤΟΡΙΚΟ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (int i = 0; i < _medicalHistoryRows.length; i++) ...[
              _buildMedicalHistoryRowWidget(i),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: () {
                setState(() => _medicalHistoryRows.add(_MedicalHistoryRow()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Προσθήκη'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryRowWidget(int index) {
    final row = _medicalHistoryRows[index];
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: row.itemController,
            builder: (context, _) {
              final changed = _existingPatient != null &&
                  row.itemController.text != row.originalItem;
              return TextFormField(
                controller: row.itemController,
                style: TextStyle(color: changed ? Colors.yellow : null),
                decoration: const InputDecoration(
                  labelText: 'Πάθηση',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: row.detailController,
            builder: (context, _) {
              final changed = _existingPatient != null &&
                  row.detailController.text != row.originalDetail;
              return TextFormField(
                controller: row.detailController,
                style: TextStyle(color: changed ? Colors.yellow : null),
                decoration: const InputDecoration(
                  labelText: 'Λεπτομέρεια',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: () {
            setState(() {
              _medicalHistoryRows[index].dispose();
              _medicalHistoryRows.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  // ── Family History Section ──

  Widget _buildFamilyHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ΟΙΚ. ΙΣΤ.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // Father
            Text('ΠΑΤΕΡΑΣ',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _trackedField(
                    trackingKey: 'fatherAge',
                    controller: _fatherAgeController,
                    label: 'Ηλικία',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _trackedField(
                    trackingKey: 'fatherStatus',
                    controller: _fatherStatusController,
                    label: 'Κατάσταση',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _trackedField(
              trackingKey: 'fatherConditions',
              controller: _fatherConditionsController,
              label: 'Παθήσεις',
              hint: 'Χωρισμένες με κόμμα',
            ),
            const SizedBox(height: 16),
            // Mother
            Text('ΜΗΤΕΡΑ',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _trackedField(
                    trackingKey: 'motherAge',
                    controller: _motherAgeController,
                    label: 'Ηλικία',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _trackedField(
                    trackingKey: 'motherStatus',
                    controller: _motherStatusController,
                    label: 'Κατάσταση',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _trackedField(
              trackingKey: 'motherConditions',
              controller: _motherConditionsController,
              label: 'Παθήσεις',
              hint: 'Χωρισμένες με κόμμα',
            ),
            const SizedBox(height: 16),
            // Spouse
            Text('ΣΥΖΥΓΟΣ',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _trackedField(
                    trackingKey: 'spouseStatus',
                    controller: _spouseStatusController,
                    label: 'Κατάσταση',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _trackedField(
                    trackingKey: 'spouseConditions',
                    controller: _spouseConditionsController,
                    label: 'Παθήσεις',
                    hint: 'Χωρισμένες με κόμμα',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Siblings
            Text('ΑΔΕΡΦΟΣ/Η',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (int i = 0; i < _siblingRows.length; i++) ...[
              _buildSiblingRowWidget(i),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: () {
                setState(() => _siblingRows.add(_SiblingRow()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Προσθήκη'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiblingRowWidget(int index) {
    final row = _siblingRows[index];
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: row.relationController,
            builder: (context, _) {
              final changed = _existingPatient != null &&
                  row.relationController.text != row.originalRelation;
              return TextFormField(
                controller: row.relationController,
                style: TextStyle(color: changed ? Colors.yellow : null),
                decoration: const InputDecoration(
                  labelText: 'Σχέση',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: AnimatedBuilder(
            animation: row.ageController,
            builder: (context, _) {
              final changed = _existingPatient != null &&
                  row.ageController.text != row.originalAge;
              return TextFormField(
                controller: row.ageController,
                style: TextStyle(color: changed ? Colors.yellow : null),
                decoration: const InputDecoration(
                  labelText: 'Ηλικία',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: row.conditionsController,
            builder: (context, _) {
              final changed = _existingPatient != null &&
                  row.conditionsController.text != row.originalConditions;
              return TextFormField(
                controller: row.conditionsController,
                style: TextStyle(color: changed ? Colors.yellow : null),
                decoration: const InputDecoration(
                  labelText: 'Παθήσεις',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: () {
            setState(() {
              _siblingRows[index].dispose();
              _siblingRows.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  // ── Medication Section ──

  Widget _buildMedicationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ΑΓΩΓΗ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (int i = 0; i < _medicationRows.length; i++) ...[
              _buildMedicationRowWidget(i),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: () {
                setState(() => _medicationRows.add(_MedicationRow()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Προσθήκη'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationRowWidget(int index) {
    final row = _medicationRows[index];
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: row.nameController,
            builder: (context, _) {
              final changed = _existingPatient != null &&
                  row.nameController.text != row.originalName;
              return TextFormField(
                controller: row.nameController,
                style: TextStyle(color: changed ? Colors.yellow : null),
                decoration: const InputDecoration(
                  labelText: 'Φάρμακο',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: row.doseController,
            builder: (context, _) {
              final changed = _existingPatient != null &&
                  row.doseController.text != row.originalDose;
              return TextFormField(
                controller: row.doseController,
                style: TextStyle(color: changed ? Colors.yellow : null),
                decoration: const InputDecoration(
                  labelText: 'Δόση',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: row.frequencyController,
            builder: (context, _) {
              final changed = _existingPatient != null &&
                  row.frequencyController.text != row.originalFrequency;
              return TextFormField(
                controller: row.frequencyController,
                style: TextStyle(color: changed ? Colors.yellow : null),
                decoration: const InputDecoration(
                  labelText: 'Συχνότητα',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: () {
            setState(() {
              _medicationRows[index].dispose();
              _medicationRows.removeAt(index);
            });
          },
        ),
      ],
    );
  }
}

// ── Helper classes for dynamic rows ──

class _MedicalHistoryRow {
  final itemController = TextEditingController();
  final detailController = TextEditingController();
  String originalItem = '';
  String originalDetail = '';

  void dispose() {
    itemController.dispose();
    detailController.dispose();
  }
}

class _SiblingRow {
  final relationController = TextEditingController();
  final ageController = TextEditingController();
  final conditionsController = TextEditingController();
  String originalRelation = '';
  String originalAge = '';
  String originalConditions = '';

  void dispose() {
    relationController.dispose();
    ageController.dispose();
    conditionsController.dispose();
  }
}

class _MedicationRow {
  final nameController = TextEditingController();
  final doseController = TextEditingController();
  final frequencyController = TextEditingController();
  String originalName = '';
  String originalDose = '';
  String originalFrequency = '';

  void dispose() {
    nameController.dispose();
    doseController.dispose();
    frequencyController.dispose();
  }
}
