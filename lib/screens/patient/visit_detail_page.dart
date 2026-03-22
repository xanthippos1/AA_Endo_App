import 'package:flutter/material.dart';

class VisitDetailPage extends StatelessWidget {
  final Map<String, dynamic> visit;

  const VisitDetailPage({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Visit ${visit['visit_number']} — ${visit['date']}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => items[index],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems() {
    final items = <Widget>[];

    // Medications first
    final medications = visit['current_medication'] as List<dynamic>?;
    if (medications != null && medications.isNotEmpty) {
      items.add(const ListTile(
        leading: Icon(Icons.medication),
        title: Text('Medications'),
        dense: true,
      ));
    }

    // Instructions second
    final instructions = visit['instructions'] as List<dynamic>?;
    if (instructions != null && instructions.isNotEmpty) {
      items.add(const ListTile(
        leading: Icon(Icons.assignment),
        title: Text('Instructions'),
        dense: true,
      ));
    }

    // Labs sorted by date (reverse chronological)
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
        final type = lab['type'] ?? '';
        final date = lab['date'] ?? '';
        final desc = lab['description'] ?? '';
        items.add(ListTile(
          leading: const Icon(Icons.science),
          title: Text('lab ($date) ${type.toUpperCase()}${desc.isNotEmpty ? ' $desc' : ''}'),
          dense: true,
        ));
      }
    }

    // Notes last
    final notes = visit['notes'] as List<dynamic>?;
    if (notes != null && notes.isNotEmpty) {
      for (final note in notes) {
        items.add(ListTile(
          leading: const Icon(Icons.note),
          title: Text(note.toString()),
          dense: true,
        ));
      }
    }

    if (items.isEmpty) {
      items.add(const ListTile(title: Text('No details for this visit.')));
    }

    return items;
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
