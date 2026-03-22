import 'package:flutter/material.dart';
import '../../core/services/patient_service.dart';
import '../../models/patient.dart';

class SearchPage extends StatefulWidget {
  final void Function(Patient patient)? onPatientSelected;

  const SearchPage({super.key, this.onPatientSelected});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _amkaController = TextEditingController();
  final _patientService = PatientService();
  List<Patient> _results = [];
  bool _hasSearched = false;

  Future<void> _search() async {
    final query = _amkaController.text.trim();
    if (query.length != 4) return;

    final matches = await _patientService.searchByAmka(query);
    setState(() {
      _results = matches;
      _hasSearched = true;
    });
  }

  @override
  void dispose() {
    _amkaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Patient Search',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              enabled: false,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amkaController,
            decoration: const InputDecoration(
              labelText: 'AMKA (last 4 digits)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Birth',
              border: OutlineInputBorder(),
              enabled: false,
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Visit',
              border: OutlineInputBorder(),
              enabled: false,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _search,
            child: const Text('Search'),
          ),
          const SizedBox(height: 16),
          if (_hasSearched && _results.isEmpty)
            const Text('No patients found.'),
          if (_results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final patient = _results[index];
                  return ListTile(
                    title: Text(patient.name),
                    subtitle: Text('AMKA: ${patient.amka}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      widget.onPatientSelected?.call(patient);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
