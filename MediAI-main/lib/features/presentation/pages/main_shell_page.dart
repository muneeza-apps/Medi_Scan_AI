import 'package:flutter/material.dart';

import '../../../../core/repositories/scan_repository.dart';
import '../../../../core/services/locale_service.dart';
import 'clinical_analytics_page.dart';
import 'iot_vitals_page.dart';
import 'patient_profile_page.dart';
import 'scan_history_page.dart';
import 'skin_triage_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    ScanRepository.instance.getAllScans();
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _navigateToTriage() {
    setState(() => _selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                const SkinTriagePage(),
                const IotVitalsPage(),
                ScanHistoryPage(onNavigateToTriage: _navigateToTriage),
                const ClinicalAnalyticsPage(),
                const PatientProfilePage(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: Colors.white,
              elevation: 3,
              indicatorColor: const Color(0xFF80CBC4).withValues(alpha: 0.4),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.biotech_outlined),
                  selectedIcon: const Icon(
                    Icons.biotech,
                    color: Color(0xFF004D40),
                  ),
                  label: isUrdu ? 'اسکین' : 'Triage',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.sensors_outlined),
                  selectedIcon: const Icon(
                    Icons.sensors,
                    color: Color(0xFF004D40),
                  ),
                  label: isUrdu ? 'وائٹلز' : 'IoT Vitals',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(
                    Icons.history,
                    color: Color(0xFF004D40),
                  ),
                  label: isUrdu ? 'ریکارڈز' : 'Records',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(
                    Icons.insights,
                    color: Color(0xFF004D40),
                  ),
                  label: isUrdu ? 'تجزیات' : 'Analytics',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(
                    Icons.person,
                    color: Color(0xFF004D40),
                  ),
                  label: isUrdu ? 'پروفائل' : 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
