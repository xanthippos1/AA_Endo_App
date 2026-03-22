import 'package:flutter/material.dart';
import '../../models/patient.dart';

class PatientPage extends StatefulWidget {
  final Patient? patient;

  const PatientPage({super.key, this.patient});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  Map<String, dynamic>? _selectedVisit;
  String? _selectedSection; // 'family' or 'gynecological'
  int? _expandedDetailIndex; // which visit detail item is expanded

  void _goBack() {
    setState(() {
      if (_selectedSection != null) {
        _selectedSection = null;
      } else if (_selectedVisit != null) {
        _selectedVisit = null;
        _expandedDetailIndex = null;
      }
    });
  }

  @override
  void didUpdateWidget(PatientPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patient != oldWidget.patient) {
      _selectedVisit = null;
      _selectedSection = null;
      _expandedDetailIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.patient == null) {
      return const Center(child: Text('Search for a patient first.'));
    }

    if (_selectedSection != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to visits'),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildClinicalHeader(context),
                  const Divider(height: 16),
                  ..._buildSectionDetailItems(context),
                ],
              ),
            ),
          ],
        ),
      );
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
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to visits'),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildClinicalHeader(context),
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
          child: Text(
            widget.patient!.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
        _buildClinicalHeader(context),
        const Divider(height: 32),
        Text(
          'Visits (${visits.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (widget.patient!.familyHistory.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Family History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selectedSection = 'family'),
          ),
        if (widget.patient!.gynecologicalHistory.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.female),
            title: const Text('Gynecological History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selectedSection = 'gynecological'),
          ),
        const Divider(),
        for (final visit in visits)
          ListTile(
            leading: const Icon(Icons.event),
            title: Text('Visit ${visit['visit_number']}'),
            subtitle: Text(visit['date'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _selectedVisit = visit as Map<String, dynamic>;
                _expandedDetailIndex = null;
              });
            },
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalHeader(BuildContext context) {
    final patient = widget.patient!;
    final social = patient.social;
    final illness = patient.presentingIllness;
    final referral = patient.referral;
    final history = patient.medicalHistory;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final valueStyle = Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Social | Presenting Illness | Referral
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final sections = <Widget>[
                if (social.isNotEmpty)
                  _sectionCard(
                    color: Colors.teal.withValues(alpha: 0.08),
                    child: Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      children: [
                        _tableHeader('Social', context),
                        if (social['profession'] != null)
                          _tableRow('Profession', social['profession'], labelStyle, valueStyle),
                        if (social['smoking'] != null)
                          _tableRow('Smoking', social['smoking'], labelStyle, valueStyle),
                        if (social['alcohol'] != null)
                          _tableRow('Alcohol', social['alcohol'], labelStyle, valueStyle),
                        if ((social['allergies'] as List?)?.isNotEmpty == true)
                          _tableRow('Allergies', (social['allergies'] as List).join(', '), labelStyle, valueStyle),
                      ],
                    ),
                  ),
                if (illness.isNotEmpty)
                  _sectionCard(
                    color: Colors.orange.withValues(alpha: 0.08),
                    child: Table(
                      children: [
                        _tableHeader('Presenting Illness', context),
                        ...illness.map((item) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Text('• $item', style: valueStyle),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                if (referral.isNotEmpty)
                  _sectionCard(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    child: Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      children: [
                        _tableHeader('Referral', context),
                        if (referral['from'] != null)
                          _tableRow('From', referral['from'], labelStyle, valueStyle),
                        if (referral['relation'] != null)
                          _tableRow('Relation', referral['relation'], labelStyle, valueStyle),
                      ],
                    ),
                  ),
              ];

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < sections.length; i++) ...[
                      sections[i],
                      if (i < sections.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < sections.length; i++) ...[
                    Expanded(child: sections[i]),
                    if (i < sections.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Medical History table
          if (history.isNotEmpty)
            _sectionCard(
              color: Colors.purple.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medical History', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Table(
                    columnWidths: const {
                      0: FixedColumnWidth(30),
                      1: FlexColumnWidth(),
                    },
                    children: [
                      for (final h in history)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Text('${h['number'] ?? ''}', style: labelStyle),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Text('${h['item']}', style: valueStyle),
                            ),
                          ],
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

  // Build a flat list of detail entries from the visit, each with a type tag
  List<Map<String, dynamic>> _visitDetailEntries() {
    final visit = _selectedVisit!;
    final entries = <Map<String, dynamic>>[];

    final medications = visit['current_medication'] as List<dynamic>?;
    if (medications != null && medications.isNotEmpty) {
      entries.add({'_type': 'medications', 'data': medications});
    }

    final instructions = visit['instructions'] as List<dynamic>?;
    if (instructions != null && instructions.isNotEmpty) {
      entries.add({'_type': 'instructions', 'data': instructions});
    }

    final labs = visit['labs'] as List<dynamic>?;
    if (labs != null && labs.isNotEmpty) {
      final sortedLabs = List<Map<String, dynamic>>.from(
        labs.map((l) => l as Map<String, dynamic>),
      )..sort((a, b) {
          final dateA = _parseDate(a['date'] ?? '');
          final dateB = _parseDate(b['date'] ?? '');
          return dateB.compareTo(dateA);
        });
      for (final lab in sortedLabs) {
        entries.add({'_type': 'lab', ...lab});
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
      Text(
        'Visit ${visit['visit_number']} — ${visit['date']}',
        style: Theme.of(context).textTheme.titleMedium,
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
      final isExpanded = _expandedDetailIndex == i;

      // List tile for each entry
      switch (type) {
        case 'medications':
          items.add(ListTile(
            leading: const Icon(Icons.medication),
            title: const Text('Medications'),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            dense: true,
            onTap: () => setState(() =>
              _expandedDetailIndex = isExpanded ? null : i),
          ));
          if (isExpanded) {
            items.add(_buildMedicationsDetail(entry['data'] as List<dynamic>));
          }
        case 'instructions':
          items.add(ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Instructions'),
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

  List<Widget> _buildSectionDetailItems(BuildContext context) {
    final patient = widget.patient!;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final valueStyle = Theme.of(context).textTheme.bodySmall;

    if (_selectedSection == 'family') {
      final fh = patient.familyHistory;
      final items = <Widget>[
        Text('Family History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
      ];

      for (final key in ['father', 'mother', 'spouse']) {
        final member = fh[key] as Map<String, dynamic>?;
        if (member != null) {
          final age = member['age'] != null ? ', age ${member['age']}' : '';
          final status = member['status'] ?? '';
          final conditions = (member['conditions'] as List?)?.join(', ') ?? '';
          items.add(ListTile(
            title: Text('${key[0].toUpperCase()}${key.substring(1)}$age $status'),
            subtitle: Text(conditions),
            dense: true,
          ));
        }
      }

      final siblings = fh['siblings'] as List?;
      if (siblings != null) {
        for (final s in siblings) {
          final relation = s['relation'] ?? '';
          final conditions = (s['conditions'] as List?)?.join(', ') ?? '';
          items.add(ListTile(
            title: Text(relation),
            subtitle: Text(conditions),
            dense: true,
          ));
        }
      }

      final summary = fh['patient_summary'] as List?;
      if (summary != null) {
        items.add(ListTile(
          title: Text('Patient', style: labelStyle),
          subtitle: Text(summary.join(', '), style: valueStyle),
          dense: true,
        ));
      }

      return items;
    }

    if (_selectedSection == 'gynecological') {
      final gh = patient.gynecologicalHistory;
      final items = <Widget>[
        Text('Gynecological History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
      ];
      gh.forEach((key, value) {
        items.add(ListTile(
          title: Text(key.replaceAll('_', ' '), style: labelStyle),
          trailing: Text('$value', style: valueStyle),
          dense: true,
        ));
      });
      return items;
    }

    return [];
  }

  Widget _sectionCard({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  TableRow _tableHeader(String title, BuildContext context) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (title != 'Presenting Illness') const SizedBox(),
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
