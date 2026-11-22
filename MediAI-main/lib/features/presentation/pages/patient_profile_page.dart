import 'package:flutter/material.dart';

import '../../../../core/models/iot_vitals_model.dart';
import '../../../../core/models/patient_profile_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/iot_vitals_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/services/patient_profile_service.dart';
import '../../../../core/services/scan_history_storage.dart';
import 'auth_page.dart';
import 'iot_vitals_page.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _fitzpatrickType = 'Type III';
  String _selectedCity = 'Faisalabad';
  String _selectedLanguage = 'en';
  int _cachedRecordCount = 0;
  bool _isLoading = true;

  final List<String> _cities = [
    'Faisalabad',
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Peshawar',
    'Multan',
    'Quetta',
  ];

  final List<Map<String, String>> _fitzpatrickTypes = [
    {
      'type': 'Type I',
      'labelEn': 'Type I: Very Fair / Always Burns, Never Tans',
      'labelUr': 'ٹائپ 1 اور 2: انتہائی ہلکی یا گوری جلد (جلدی سرخ ہوتی ہے)',
    },
    {
      'type': 'Type II',
      'labelEn': 'Type II: Fair / Usually Burns, Tans Minimally',
      'labelUr': 'ٹائپ 1 اور 2: انتہائی ہلکی یا گوری جلد (جلدی سرخ ہوتی ہے)',
    },
    {
      'type': 'Type III',
      'labelEn': 'Type III: Medium / Sometimes Burns, Uniform Tan',
      'labelUr': 'ٹائپ 3 اور 4: گندمی / سانولی جلد (دھوپ برداشت کرتی ہے)',
    },
    {
      'type': 'Type IV',
      'labelEn': 'Type IV: Olive / Rarely Burns, Always Tans Well',
      'labelUr': 'ٹائپ 3 اور 4: گندمی / سانولی جلد (دھوپ برداشت کرتی ہے)',
    },
    {
      'type': 'Type V',
      'labelEn': 'Type V: Brown / Very Rarely Burns, Tans Easily',
      'labelUr': 'ٹائپ 5 اور 6: گہری سانولی یا سیاہ جلد',
    },
    {
      'type': 'Type VI',
      'labelEn': 'Type VI: Dark Brown/Black / Never Burns, Profound Pigment',
      'labelUr': 'ٹائپ 5 اور 6: گہری سانولی یا سیاہ جلد',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final profile = PatientProfileService.profile;
    final scans = await ScanHistoryStorage.getAllScans();

    if (mounted) {
      setState(() {
        _nameController.text = profile.name;
        _ageController.text = profile.age;
        _fitzpatrickType = profile.fitzpatrickType;
        _selectedCity = _cities.contains(profile.city) ? profile.city : _cities.first;
        _selectedLanguage = LocaleService.languageCode;
        _cachedRecordCount = scans.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    final updatedProfile = PatientProfile(
      name: _nameController.text.trim().isEmpty
          ? 'Clinical Patient'
          : _nameController.text.trim(),
      age: _ageController.text.trim().isEmpty
          ? '34'
          : _ageController.text.trim(),
      fitzpatrickType: _fitzpatrickType,
      city: _selectedCity,
    );

    await PatientProfileService.saveProfile(updatedProfile);
    await LocaleService.setLocale(_selectedLanguage);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleService.isUrdu
                ? 'مریض کا پروفائل کامیابی سے محفوظ ہو گیا۔'
                : 'Patient profile updated successfully.',
          ),
          backgroundColor: const Color(0xFF004D40),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final isUrdu = LocaleService.isUrdu;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                isUrdu ? 'لاگ آؤٹ کی تصدیق' : 'Sign Out Confirmation',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isUrdu
                ? 'کیا آپ واقعی اپنے سیشن سے لاگ آؤٹ کرنا چاہتے ہیں؟'
                : 'Are you sure you want to sign out from your local account?',
          ),
          actions: [
            TextButton(
              child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(isUrdu ? 'لاگ آؤٹ' : 'Sign Out'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _confirmClearCache() async {
    final isUrdu = LocaleService.isUrdu;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                isUrdu
                    ? 'مقامی ریکارڈز صاف کریں؟'
                    : 'Clear Local Records?',
              ),
            ],
          ),
          content: Text(
            isUrdu
                ? 'اس سے آپ کے موبائل پر محفوظ تمام اسکین ریکارڈز ہٹا دیے جائیں گے۔ کلاؤڈ آرکائیو محفوظ رہے گی۔'
                : 'This will permanently remove all cached scan records from your device storage. Uploaded Cloudinary copies will remain archived.',
          ),
          actions: [
            TextButton(
              child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(isUrdu ? 'تمام صاف کریں' : 'Clear All'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await ScanHistoryStorage.clearAllScans();
      await _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu
                  ? 'مقامی اسکین کیشے صاف کر دی گئی ہے۔'
                  : 'Local scan cache cleared.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';
        _selectedLanguage = locale.languageCode;

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F9FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    isUrdu ? 'مریض کا پروفائل' : 'Patient Profile',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save_rounded),
                  tooltip: isUrdu ? 'محفوظ کریں' : 'Save Profile',
                  onPressed: _saveProfileData,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: isUrdu ? 'لاگ آؤٹ' : 'Sign Out',
                  onPressed: _handleLogout,
                ),
              ],
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00796B)),
                  )
                : ValueListenableBuilder<PatientProfile>(
                    valueListenable: PatientProfileService.currentProfile,
                    builder: (context, liveProfile, _) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              elevation: 1.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF004D40),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_outline_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            liveProfile.name.isEmpty ||
                                                    liveProfile.name ==
                                                        'Clinical Patient'
                                                ? (isUrdu
                                                    ? 'طبی مریض'
                                                    : 'Clinical Patient')
                                                : liveProfile.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF004D40),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isUrdu
                                                ? 'عمر: ${liveProfile.age.isEmpty ? "نامعلوم" : liveProfile.age} • ${liveProfile.fitzpatrickType} • ${liveProfile.city == "Faisalabad" ? "فیصل آباد" : liveProfile.city}'
                                                : 'Age: ${liveProfile.age.isEmpty ? "N/A" : liveProfile.age} • ${liveProfile.fitzpatrickType} • ${liveProfile.city}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0F2F1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      size: 11,
                                                      color: Color(0xFF004D40),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      isUrdu &&
                                                              liveProfile.city ==
                                                                  'Faisalabad'
                                                          ? 'فیصل آباد'
                                                          : liveProfile.city,
                                                      style: const TextStyle(
                                                        color: Color(0xFF004D40),
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0F2F1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  isUrdu
                                                      ? 'فعال مریض ریکارڈ'
                                                      : 'Active CDS Profile',
                                                  style: const TextStyle(
                                                    color: Color(0xFF004D40),
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFFFE082)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.health_and_safety_rounded,
                                    color: Color(0xFFF57F17),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isUrdu
                                              ? 'طبی رہنمائی کا ضروری نوٹس'
                                              : 'Clinical Decision Support Notice',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFFE65100),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isUrdu
                                              ? 'میڈی اے آئی ابتدائی مدد کے لیے ایک خودکار نظام ہے اور یہ مستند معالج کی تشخیص کا متبادل نہیں ہے۔ ہمیشہ حتمی فیصلے کے لیے ڈاکٹر سے مشورہ لیں۔'
                                              : 'MediAI is an assistive edge-AI algorithmic triage system and does not replace in-person diagnosis by a licensed physician or dermatologist. Always consult a medical professional for clinical guidance.',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF5D4037),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.badge_outlined,
                                          color: Color(0xFF00796B),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isUrdu
                                              ? 'مریض کے وائٹلز اور مقام'
                                              : 'Clinical Vitals & Location',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF004D40),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: isUrdu
                                            ? 'مریض کا نام / شناختی نام'
                                            : 'Patient Identifier / Name',
                                        hintText: isUrdu
                                            ? 'طبی مریض'
                                            : 'Clinical Patient',
                                        prefixIcon:
                                            const Icon(Icons.person_outline),
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _ageController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: isUrdu
                                            ? 'مریض کی عمر (سال)'
                                            : 'Patient Age (Years)',
                                        prefixIcon:
                                            const Icon(Icons.cake_outlined),
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      isUrdu
                                          ? 'شہر / جغرافیائی مقام (قریبی کلینکس کے لیے)'
                                          : 'City / Geographic Location',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: _selectedCity,
                                          items: _cities.map((city) {
                                            final cityDisplay = isUrdu &&
                                                    city == 'Faisalabad'
                                                ? 'فیصل آباد'
                                                : city;
                                            return DropdownMenuItem<String>(
                                              value: city,
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_city_rounded,
                                                    size: 16,
                                                    color: Color(0xFF00796B),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    cityDisplay,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(
                                                () => _selectedCity = val,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      isUrdu
                                          ? 'فٹزپیٹرک جلد کی فوٹو ٹائپ'
                                          : 'Fitzpatrick Skin Phototype',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: _fitzpatrickType,
                                          items: _fitzpatrickTypes.map((item) {
                                            final label = isUrdu
                                                ? item['labelUr']!
                                                : item['labelEn']!;
                                            return DropdownMenuItem<String>(
                                              value: item['type'],
                                              child: Text(
                                                label,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(
                                                () => _fitzpatrickType = val,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.sensors,
                                              color: Color(0xFF00796B),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isUrdu
                                                  ? 'طبی IoT سینسر حب'
                                                  : 'Medical IoT Sensors',
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF004D40),
                                              ),
                                            ),
                                          ],
                                        ),
                                        StreamBuilder<IotConnectionState>(
                                          stream: IotVitalsService
                                              .instance.connectionStateStream,
                                          initialData: IotVitalsService
                                              .instance.connectionState,
                                          builder: (context, snapshot) {
                                            final isConn = snapshot.data ==
                                                IotConnectionState.connected;
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isConn
                                                    ? const Color(0xFFE8F5E9)
                                                    : Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isConn
                                                    ? (isUrdu
                                                        ? 'منسلک ہے'
                                                        : 'PAIRED')
                                                    : (isUrdu
                                                        ? 'تیار حالت'
                                                        : 'STANDBY'),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isConn
                                                      ? Colors.green.shade800
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      isUrdu
                                          ? 'پلس آکسیمیٹر، ڈیجیٹل تھرمامیٹر، یا بی پی مانیٹر کو بلوٹوتھ کے ذریعے جوڑیں'
                                          : 'Connect pulse oximeter, thermometer, or blood pressure sensor via BLE/IoT',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF004D40),
                                          side: const BorderSide(
                                            color: Color(0xFF004D40),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const IotVitalsPage(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.monitor_heart_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isUrdu
                                              ? 'IoT وائٹلز مانیٹر کھولیں'
                                              : 'Open IoT Vitals Hub',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.settings_suggest_outlined,
                                          color: Color(0xFF00796B),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isUrdu
                                              ? 'ترجیحات اور ڈیٹا محفوظ کرنا'
                                              : 'Preferences & Storage',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF004D40),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isUrdu
                                              ? 'ایپلیکیشن کی زبان'
                                              : 'App Language',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SegmentedButton<String>(
                                          segments: const [
                                            ButtonSegment(
                                              value: 'en',
                                              label: Text('English'),
                                            ),
                                            ButtonSegment(
                                              value: 'ur',
                                              label: Text('اردو'),
                                            ),
                                          ],
                                          selected: {_selectedLanguage},
                                          onSelectionChanged: (set) {
                                            final newLang = set.first;
                                            setState(
                                              () =>
                                                  _selectedLanguage = newLang,
                                            );
                                            LocaleService.setLocale(newLang);
                                          },
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.folder_outlined,
                                          color: Colors.blueGrey,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isUrdu
                                                    ? 'محفوظ شدہ طبی اسکینز'
                                                    : 'Cached Clinical Scans',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                isUrdu
                                                    ? '$_cachedRecordCount ریکارڈز مقامی ڈیوائس پر محفوظ ہیں'
                                                    : '$_cachedRecordCount records stored on local device',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _confirmClearCache,
                                          child: Text(
                                            isUrdu
                                                ? 'کیشے صاف کریں'
                                                : 'Clear Cache',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 20,
                              ),
                              label: Text(
                                isUrdu
                                    ? 'پروفائل محفوظ کریں'
                                    : 'Save Patient Profile',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _saveProfileData,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: Text(
                                isUrdu
                                    ? 'اکاؤنٹ سے لاگ آؤٹ کریں'
                                    : 'Sign Out Account',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: _handleLogout,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
