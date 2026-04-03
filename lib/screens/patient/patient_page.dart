import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../core/services/patient_service.dart';
import '../../core/services/label_service.dart';

class PatientPage extends StatefulWidget {
  final Patient? patient;

  const PatientPage({super.key, this.patient});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  Map<String, dynamic>? _selectedVisit;
  int? _expandedDetailIndex; // which visit detail item is expanded
  bool _expandAll = false;
  int _imageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadImageCount();
  }

  void _loadImageCount() {
    if (widget.patient == null) return;
    PatientService.getImageCount(widget.patient!.patientId).then((count) {
      if (mounted) setState(() => _imageCount = count);
    });
  }

  void _goBack() {
    setState(() {
      _selectedVisit = null;
      _expandedDetailIndex = null;
      _expandAll = false;
    });
  }

  @override
  void didUpdateWidget(PatientPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patient != oldWidget.patient) {
      _selectedVisit = null;
      _expandedDetailIndex = null;
      _imageCount = 0;
      _loadImageCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.patient == null) {
      return const Center(child: Text('Search for a patient first.'));
    }

    if (_selectedVisit != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to visits'),
                  ),
                  const Spacer(),
                  _buildImageButtons(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildLevel1(context, widget.patient!, Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold), Theme.of(context).textTheme.bodySmall),
                  const Divider(height: 16),
                  ..._buildVisitDetailItems(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final visits = List<dynamic>.from(widget.patient!.visits)
      ..sort((a, b) {
        final dateA = _parseDate(a['date'] ?? '');
        final dateB = _parseDate(b['date'] ?? '');
        return dateB.compareTo(dateA);
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.patient!.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              _buildImageButtons(),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
        _buildPatientLevels(context),
        const Divider(height: 32),
        Text(
          '${LabelService.get('visit')} (${visits.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final visit in visits)
          ListTile(
            leading: const Icon(Icons.event),
            title: Text('${LabelService.get('visit')} ${visit['visit_number']}'),
            subtitle: Text(visit['date'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _selectedVisit = visit as Map<String, dynamic>;
                _expandedDetailIndex = null;
                _expandAll = false;
              });
            },
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageButtons() {
    if (_imageCount == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= _imageCount; i++)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: SizedBox(
              width: 32,
              height: 32,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _showImage(i),
                child: Text(
                  '$i',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showImage(int imageNumber) {
    final patientId = widget.patient!.patientId;
    final assetPath = 'jpeg_images/${patientId}_$imageNumber.jpg';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientLevels(BuildContext context) {
    final patient = widget.patient!;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final valueStyle = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLevel1(context, patient, labelStyle, valueStyle),
        const SizedBox(height: 8),
        _buildLevel2(context, patient, labelStyle, valueStyle),
        const SizedBox(height: 8),
        _buildLevel3(context, patient, labelStyle, valueStyle),
        const SizedBox(height: 8),
        _buildLevel4(context, patient, labelStyle, valueStyle),
      ],
    );
  }

  // Level 1: identity (left) | social (center) | referral (top-right) + presenting_illness (bottom-right)
  Widget _buildLevel1(BuildContext context, Patient patient, TextStyle? labelStyle, TextStyle? valueStyle) {
    final identity = patient.identity;
    final social = patient.social;
    final referral = patient.referral;
    final illness = patient.presentingIllness;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final identityCard = _sectionCard(
          color: Colors.blueGrey.withValues(alpha: 0.08),
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              _tableHeader(LabelService.get('identity'), context),
              if (identity['name'] != null)
                _tableRow(LabelService.get('name'), identity['name'], labelStyle, valueStyle),
              if (identity['dob'] != null)
                _tableRow(LabelService.get('dob'), identity['dob'], labelStyle, valueStyle),
              if (identity['age_at_first_visit'] != null)
                _tableRow(LabelService.get('age_at_first_visit'), '${identity['age_at_first_visit']}', labelStyle, valueStyle),
              if (identity['address'] != null)
                _tableRow(LabelService.get('address'), identity['address'], labelStyle, valueStyle),
              if (identity['phone'] != null)
                _tableRow(LabelService.get('phone'), identity['phone'], labelStyle, valueStyle),
              if (identity['amka'] != null)
                _tableRow(LabelService.get('amka'), identity['amka'], labelStyle, valueStyle),
            ],
          ),
        );

        final socialCard = social.isNotEmpty
            ? _sectionCard(
                color: Colors.teal.withValues(alpha: 0.08),
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    _tableHeader(LabelService.get('social'), context),
                    if (social['profession'] != null)
                      _tableRow(LabelService.get('profession'), social['profession'], labelStyle, valueStyle),
                    if (social['smoking'] != null)
                      _tableRow(LabelService.get('smoking'), social['smoking'], labelStyle, valueStyle),
                    if (social['alcohol'] != null)
                      _tableRow(LabelService.get('alcohol'), social['alcohol'], labelStyle, valueStyle),
                    if (social['allergies'] != null)
                      _tableRow(
                        LabelService.get('allergies'),
                        social['allergies'] is List
                            ? (social['allergies'] as List).join(', ')
                            : social['allergies'].toString(),
                        labelStyle,
                        valueStyle,
                      ),
                  ],
                ),
              )
            : null;

        final referralCard = referral.isNotEmpty
            ? _sectionCard(
                color: Colors.indigo.withValues(alpha: 0.08),
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    _tableHeader(LabelService.get('referral'), context),
                    if (referral['from'] != null)
                      _tableRow('Από', referral['from'], labelStyle, valueStyle),
                    if (referral['relation'] != null)
                      _tableRow('Σχέση', referral['relation'], labelStyle, valueStyle),
                  ],
                ),
              )
            : null;

        final illnessCard = illness.isNotEmpty
            ? _sectionCard(
                color: Colors.orange.withValues(alpha: 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LabelService.get('presenting_illness'), style: _sectionTitleStyle),
                    const SizedBox(height: 4),
                    for (final item in illness)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text('• $item', style: valueStyle),
                      ),
                  ],
                ),
              )
            : null;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identityCard,
              if (socialCard != null) ...[const SizedBox(height: 8), socialCard],
              if (referralCard != null) ...[const SizedBox(height: 8), referralCard],
              if (illnessCard != null) ...[const SizedBox(height: 8), illnessCard],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: identityCard),
            if (socialCard != null) ...[const SizedBox(width: 8), Expanded(child: socialCard)],
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  if (referralCard != null) referralCard,
                  if (referralCard != null && illnessCard != null) const SizedBox(height: 8),
                  if (illnessCard != null) illnessCard,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Level 2: medical_history (left) | gynecological_history (right, if applicable)
  Widget _buildLevel2(BuildContext context, Patient patient, TextStyle? labelStyle, TextStyle? valueStyle) {
    final history = patient.medicalHistory;
    final gynHistory = patient.gynecologicalHistory;

    if (history.isEmpty && gynHistory.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final historyCard = history.isNotEmpty
            ? _sectionCard(
                color: Colors.purple.withValues(alpha: 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LabelService.get('medical_history'), style: _sectionTitleStyle),
                    const SizedBox(height: 4),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(),
                      },
                      children: [
                        for (final h in history)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: Text('• ${h['item']}${h['detail'] != null ? ' — ${h['detail']}' : ''}', style: valueStyle),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              )
            : null;

        final gynCard = gynHistory.isNotEmpty
            ? _sectionCard(
                color: Colors.pink.withValues(alpha: 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LabelService.get('gynecological_history'), style: _sectionTitleStyle),
                    const SizedBox(height: 4),
                    Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      children: [
                        for (final entry in gynHistory.entries)
                          _tableRow(entry.key.replaceAll('_', ' '), '${entry.value}', labelStyle, valueStyle),
                      ],
                    ),
                  ],
                ),
              )
            : null;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (historyCard != null) historyCard,
              if (historyCard != null && gynCard != null) const SizedBox(height: 8),
              if (gynCard != null) gynCard,
            ],
          );
        }

        if (gynCard == null) return historyCard ?? const SizedBox.shrink();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (historyCard != null) Expanded(child: historyCard),
            if (historyCard != null) const SizedBox(width: 8),
            Expanded(child: gynCard),
          ],
        );
      },
    );
  }

  // Level 3: father (left) | mother (center) | spouse (top-right) + siblings (bottom-right)
  Widget _buildLevel3(BuildContext context, Patient patient, TextStyle? labelStyle, TextStyle? valueStyle) {
    final fh = patient.familyHistory;
    if (fh.isEmpty) return const SizedBox.shrink();

    Widget familyMemberCard(String key, Map<String, dynamic>? member, Color color) {
      final age = member != null && member['age'] != null ? '${member['age']}' : '';
      final status = member != null ? (member['status'] ?? '') : '';
      final conditions = member != null ? ((member['conditions'] as List?)?.join(', ') ?? '') : '';

      return _sectionCard(
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LabelService.get(key), style: _sectionTitleStyle),
            const SizedBox(height: 4),
            if (member == null || member.isEmpty)
              Text('—', style: valueStyle)
            else ...[
              if (age.isNotEmpty || status.isNotEmpty)
                Text('$status${age.isNotEmpty ? ', $age' : ''}', style: valueStyle),
              if (conditions.isNotEmpty)
                Text(conditions, style: valueStyle),
            ],
          ],
        ),
      );
    }

    final father = fh['father'] as Map<String, dynamic>?;
    final mother = fh['mother'] as Map<String, dynamic>?;
    final spouse = fh['spouse'] as Map<String, dynamic>?;
    final siblings = fh['siblings'] as List?;

    final spouseCard = _sectionCard(
      color: Colors.brown.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LabelService.get('spouse'), style: _sectionTitleStyle),
          const SizedBox(height: 4),
          if (spouse == null || spouse.isEmpty)
            Text('—', style: valueStyle)
          else ...[
            if (spouse['status'] != null) Text('${spouse['status']}', style: valueStyle),
            if ((spouse['conditions'] as List?)?.isNotEmpty == true)
              Text((spouse['conditions'] as List).join(', '), style: valueStyle),
          ],
        ],
      ),
    );

    final siblingsCard = _sectionCard(
      color: Colors.deepOrange.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LabelService.get('siblings'), style: _sectionTitleStyle),
          const SizedBox(height: 4),
          if (siblings == null || siblings.isEmpty)
            Text('—', style: valueStyle)
          else
            for (final s in siblings) ...[
              Text(
                '${s['relation'] ?? ''}${s['age'] != null ? ', ${s['age']}' : ''}',
                style: labelStyle,
              ),
              if ((s['conditions'] as List?)?.isNotEmpty == true)
                Text((s['conditions'] as List).join(', '), style: valueStyle),
              const SizedBox(height: 2),
            ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final fatherCard = familyMemberCard('father', father, Colors.blue.withValues(alpha: 0.08));
        final motherCard = familyMemberCard('mother', mother, Colors.green.withValues(alpha: 0.08));

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(LabelService.get('family_history'), style: _sectionTitleStyle),
              const SizedBox(height: 4),
              fatherCard,
              const SizedBox(height: 8),
              motherCard,
              const SizedBox(height: 8),
              spouseCard,
              const SizedBox(height: 8),
              siblingsCard,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LabelService.get('family_history'), style: _sectionTitleStyle),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fatherCard),
                const SizedBox(width: 8),
                Expanded(child: motherCard),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      spouseCard,
                      const SizedBox(height: 8),
                      siblingsCard,
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Level 4: latest_medication (across full width)
  Widget _buildLevel4(BuildContext context, Patient patient, TextStyle? labelStyle, TextStyle? valueStyle) {
    // Get current_medication from the most recent visit (highest visit_number)
    final visits = patient.visits;
    if (visits.isEmpty) return const SizedBox.shrink();

    // Find the most recent visit that has current_medication
    List<dynamic>? latestMeds;
    String medDate = '';

    // Check top-level latest_medication first
    final topLevelMeds = patient.rawData['latest_medication'] as List<dynamic>?;
    if (topLevelMeds != null && topLevelMeds.isNotEmpty) {
      latestMeds = topLevelMeds;
      // Find the date of the latest visit with medication
      int highestNumber = -1;
      for (final v in visits) {
        final meds = v['current_medication'] as List<dynamic>?;
        if (meds != null && meds.isNotEmpty) {
          final num = (v['visit_number'] ?? 0) as int;
          if (num > highestNumber) {
            highestNumber = num;
            medDate = v['date'] ?? '';
          }
        }
      }
    } else {
      int highestNumber = -1;
      for (final v in visits) {
        final meds = v['current_medication'] as List<dynamic>?;
        if (meds != null && meds.isNotEmpty) {
          final num = (v['visit_number'] ?? 0) as int;
          if (num > highestNumber) {
            highestNumber = num;
            latestMeds = meds;
            medDate = v['date'] ?? '';
          }
        }
      }
    }

    if (latestMeds == null || latestMeds.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      color: Colors.teal.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(LabelService.get('current_medication'), style: _sectionTitleStyle),
              if (medDate.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('($medDate)', style: valueStyle),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            children: [
              for (int i = 0; i < latestMeds.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: latestMeds[i]['name'] ?? '',
                        style: const TextStyle(color: Colors.pinkAccent, fontSize: 12),
                      ),
                      TextSpan(
                        text: ' ${[latestMeds[i]['dose'] ?? '', latestMeds[i]['frequency'] ?? ''].where((s) => s.isNotEmpty).join(' ')}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      TextSpan(
                        text: i < latestMeds.length - 1 ? ', ' : '',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Build a flat list of detail entries from the visit, each with a type tag
  List<Map<String, dynamic>> _visitDetailEntries() {
    final visit = _selectedVisit!;
    final entries = <Map<String, dynamic>>[];

    final medications = visit['current_medication'] as List<dynamic>?;
    if (medications != null && medications.isNotEmpty) {
      entries.add({'_type': 'medications', 'data': medications});
    }

    final clinicalExam = visit['clinical_exam'] as Map<String, dynamic>?;
    if (clinicalExam != null && clinicalExam.isNotEmpty) {
      entries.add({'_type': 'clinical_exam', 'data': clinicalExam});
    }

    final instructions = visit['instructions'] as List<dynamic>?;
    if (instructions != null && instructions.isNotEmpty) {
      entries.add({'_type': 'instructions', 'data': instructions});
    }

    // Labs can be a List of lab objects OR a Map with date + panels
    final labsRaw = visit['labs'];
    final labList = <Map<String, dynamic>>[];
    if (labsRaw is List) {
      labList.addAll(labsRaw.map((l) => l as Map<String, dynamic>));
    } else if (labsRaw is Map) {
      final date = labsRaw['date'] ?? '';
      final panels = labsRaw['panels'] as Map<String, dynamic>?;
      if (panels != null) {
        for (final entry in panels.entries) {
          labList.add({
            'type': entry.key,
            'date': date,
            'results': entry.value,
          });
        }
      }
    }
    if (labList.isNotEmpty) {
      labList.sort((a, b) {
        final dateA = _parseDate(a['date'] ?? '');
        final dateB = _parseDate(b['date'] ?? '');
        return dateB.compareTo(dateA);
      });
      for (final lab in labList) {
        entries.add({'_type': 'lab', ...lab});
      }
    }

    // Imaging as a separate field (some patients have it outside labs)
    final imaging = visit['imaging'] as List<dynamic>?;
    if (imaging != null && imaging.isNotEmpty) {
      final sortedImaging = List<Map<String, dynamic>>.from(
        imaging.map((i) => i as Map<String, dynamic>),
      )..sort((a, b) {
          final dateA = _parseDate(a['date'] ?? '');
          final dateB = _parseDate(b['date'] ?? '');
          return dateB.compareTo(dateA);
        });
      for (final img in sortedImaging) {
        entries.add({'_type': 'lab', ...img});
      }
    }

    final notes = visit['notes'] as List<dynamic>?;
    if (notes != null && notes.isNotEmpty) {
      for (final note in notes) {
        entries.add({'_type': 'note', 'text': note.toString()});
      }
    }

    return entries;
  }

  List<Widget> _buildVisitDetailItems() {
    final visit = _selectedVisit!;
    final items = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(
              '${LabelService.get('visit')} ${visit['visit_number']} — ${visit['date']}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _expandAll = !_expandAll;
                _expandedDetailIndex = null;
              });
            },
            icon: Icon(_expandAll ? Icons.unfold_less : Icons.unfold_more, size: 18),
            label: Text(_expandAll ? 'Collapse' : 'Expand All', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];

    final entries = _visitDetailEntries();

    if (entries.isEmpty) {
      items.add(const ListTile(title: Text('No details for this visit.')));
      return items;
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final type = entry['_type'] as String;
      final isExpanded = _expandAll || _expandedDetailIndex == i;

      // List tile for each entry
      switch (type) {
        case 'medications':
          items.add(ListTile(
            leading: const Icon(Icons.medication),
            title: Text(LabelService.get('current_medication')),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            dense: true,
            onTap: () => setState(() =>
              _expandedDetailIndex = isExpanded ? null : i),
          ));
          if (isExpanded) {
            items.add(_buildMedicationsDetail(entry['data'] as List<dynamic>));
          }
        case 'clinical_exam':
          items.add(ListTile(
            leading: const Icon(Icons.medical_services),
            title: Text(LabelService.get('clinical_exam')),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            dense: true,
            onTap: () => setState(() =>
              _expandedDetailIndex = isExpanded ? null : i),
          ));
          if (isExpanded) {
            items.add(_buildClinicalExamDetail(entry['data'] as Map<String, dynamic>));
          }
        case 'instructions':
          items.add(ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(LabelService.get('instructions')),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            dense: true,
            onTap: () => setState(() =>
              _expandedDetailIndex = isExpanded ? null : i),
          ));
          if (isExpanded) {
            items.add(_buildInstructionsDetail(entry['data'] as List<dynamic>));
          }
        case 'lab':
          final date = entry['date'] ?? '';
          final labType = (entry['type'] ?? '').toString().toUpperCase();
          final desc = entry['description'] ?? '';
          items.add(ListTile(
            leading: const Icon(Icons.science),
            title: Text('lab ($date) $labType${desc.isNotEmpty ? ' $desc' : ''}'),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            dense: true,
            onTap: () => setState(() =>
              _expandedDetailIndex = isExpanded ? null : i),
          ));
          if (isExpanded) {
            items.add(_buildLabDetail(entry));
          }
        case 'note':
          items.add(ListTile(
            leading: const Icon(Icons.note),
            title: Text(entry['text'] as String),
            dense: true,
          ));
      }
    }

    return items;
  }

  Widget _buildMedicationsDetail(List<dynamic> medications) {
    return _sectionCard(
      color: Colors.teal.withValues(alpha: 0.06),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
            ),
            children: const [
              Padding(padding: EdgeInsets.all(6), child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(6), child: Text('Dose', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(6), child: Text('Freq', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          for (int i = 0; i < medications.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: i.isOdd ? Colors.white.withValues(alpha: 0.03) : null,
              ),
              children: [
                Padding(padding: const EdgeInsets.all(6), child: Text(medications[i]['name'] ?? '')),
                Padding(padding: const EdgeInsets.all(6), child: Text(medications[i]['dose'] ?? '')),
                Padding(padding: const EdgeInsets.all(6), child: Text(medications[i]['frequency'] ?? '')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildClinicalExamDetail(Map<String, dynamic> exam) {
    final valueStyle = Theme.of(context).textTheme.bodySmall;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final vitals = <MapEntry<String, String>>[];
    if (exam['weight_kg'] != null) vitals.add(MapEntry('Βάρος', '${exam['weight_kg']} kg'));
    if (exam['height_cm'] != null) vitals.add(MapEntry('Ύψος', '${exam['height_cm']} cm'));
    if (exam['bp'] != null) vitals.add(MapEntry('ΑΠ', '${exam['bp']}'));
    if (exam['bp_home'] != null) vitals.add(MapEntry('ΑΠ (σπίτι)', '${exam['bp_home']}'));
    if (exam['pulse'] != null) vitals.add(MapEntry('Σφ.', '${exam['pulse']}'));

    final findings = exam['findings'] as List<dynamic>?;
    final note = exam['note'] as String?;

    return _sectionCard(
      color: Colors.green.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vitals.isNotEmpty)
            Wrap(
              spacing: 16,
              children: [
                for (final v in vitals)
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${v.key}: ', style: labelStyle),
                    TextSpan(text: v.value, style: valueStyle),
                  ])),
              ],
            ),
          if (vitals.isNotEmpty && (findings != null || note != null))
            const SizedBox(height: 6),
          if (note != null)
            Text(note, style: const TextStyle(fontStyle: FontStyle.italic)),
          if (findings != null)
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              children: [
                for (int i = 0; i < findings.length; i++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: i.isOdd ? Colors.white.withValues(alpha: 0.03) : null,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
                        child: Text(findings[i]['system'] ?? '', style: labelStyle),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(findings[i]['value'] ?? '', style: valueStyle),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsDetail(List<dynamic> instructions) {
    return _sectionCard(
      color: Colors.blue.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final instruction in instructions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('• $instruction'),
            ),
        ],
      ),
    );
  }

  Widget _buildLabDetail(Map<String, dynamic> lab) {
    // Imaging labs have findings text instead of results table
    final findings = lab['findings'];
    if (findings != null) {
      return _sectionCard(
        color: Colors.cyan.withValues(alpha: 0.06),
        child: Text(findings.toString()),
      );
    }

    final results = lab['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      return const SizedBox();
    }

    final note = lab['note'] as String?;

    return _sectionCard(
      color: Colors.cyan.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(note, style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('Test', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('Reference', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                for (int i = 0; i < results.length; i++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: i.isOdd ? Colors.white.withValues(alpha: 0.03) : null,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(results[i]['test'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(results[i]['value'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(results[i]['reference'] ?? ''),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _buildSectionDetailItems removed — family/gynecological history now shown inline in levels

  Widget _sectionCard({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }

  static const _sectionTitleStyle = TextStyle(
    color: Colors.lightBlue,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  TableRow _tableHeader(String title, BuildContext context) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(title, style: _sectionTitleStyle),
        ),
        if (title != LabelService.get('presenting_illness')) const SizedBox(),
      ],
    );
  }

  TableRow _tableRow(String label, String value, TextStyle? labelStyle, TextStyle? valueStyle) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 1, bottom: 1),
          child: Text(label, style: labelStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(value, style: valueStyle),
        ),
      ],
    );
  }

  DateTime _parseDate(String date) {
    try {
      final parts = date.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return DateTime(1900);
    }
  }
}
