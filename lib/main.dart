import 'package:flutter/material.dart';
import 'models/patient.dart';
import 'screens/search/search_page.dart';
import 'screens/patient/patient_page.dart';
import 'core/services/label_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LabelService.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endo App',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      theme: ThemeData(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Patient? _selectedPatient;

  List<Widget> get _pages => [
    SearchPage(onPatientSelected: (patient) {
      setState(() {
        _selectedPatient = patient;
        _selectedIndex = 1;
      });
    }),
    PatientPage(patient: _selectedPatient),
    const Center(child: Text('New')),
    const Center(child: Text('Date')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Patient',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'New',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Date',
          ),
        ],
      ),
    );
  }
}
