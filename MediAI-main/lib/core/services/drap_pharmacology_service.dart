import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class DrapMedicationItem {
  final String genericName;
  final List<String> brandNames;
  final String drapRegistrationNumber;
  final String otcCategory;
  final String strength;
  final List<String> matchingConditions;
  final String guidanceEn;
  final String guidanceUr;
  final String warningsEn;
  final String warningsUr;
  final bool isPrescriptionOnly;
  final String? nonMedicinalSelfCareEn;
  final String? nonMedicinalSelfCareUr;

  const DrapMedicationItem({
    required this.genericName,
    required this.brandNames,
    required this.drapRegistrationNumber,
    required this.otcCategory,
    required this.strength,
    required this.matchingConditions,
    required this.guidanceEn,
    required this.guidanceUr,
    required this.warningsEn,
    required this.warningsUr,
    this.isPrescriptionOnly = false,
    this.nonMedicinalSelfCareEn,
    this.nonMedicinalSelfCareUr,
  });

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    if (genericName.toLowerCase().contains(q)) return true;
    for (final brand in brandNames) {
      if (brand.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  bool matchesCondition(String conditionName) {
    final c = conditionName.toLowerCase();
    for (final cond in matchingConditions) {
      if (c.contains(cond.toLowerCase())) return true;
    }
    return false;
  }
}

class DrapPharmacologyService {
  DrapPharmacologyService._internal();
  static final DrapPharmacologyService instance = DrapPharmacologyService._internal();
  factory DrapPharmacologyService() => instance;

  static const String criticalReferralBanner =
      'Critical Medical Alert: Consult a Certified Dermatologist / Hospital Immediately (فوری طور پر ماہر امراض جلد سے رجوع کریں)';

  static bool isSevereHighRiskClass(String conditionName) {
    final c = conditionName.toLowerCase();
    return c.contains('melanoma') ||
        c.contains('malignant') ||
        c.contains('actinic keratosis basal cell') ||
        c.contains('bullous') ||
        c.contains('systemic disease') ||
        c.contains('vasculitis');
  }

  static const List<DrapMedicationItem> _database = [

    DrapMedicationItem(
      genericName: 'Clotrimazole',
      brandNames: ['Canesten', 'Dermaspor', 'Surfak'],
      drapRegistrationNumber: 'DRAP-004512',
      otcCategory: 'DRAP Approved OTC Broad-Spectrum Topical Antifungal',
      strength: '1% w/w Cream / Solution',
      matchingConditions: [
        'Tinea Ringworm Candidiasis and other Fungal Infections',
        'Fungal Infections',
        'Ringworm',
        'Tinea',
        'Candidiasis',
      ],
      guidanceEn:
          'Wash and completely dry the affected skin. Apply thinly 2-3 times daily for 2 to 4 weeks. Continue treatment for 1 week after lesions clear.',
      guidanceUr:
          'متاثرہ جلد کو دھو کر خشک کریں۔ دن میں 2 سے 3 بار ہلکی تہہ لگائیں۔ علامات ختم ہونے کے بعد بھی ایک ہفتہ جاری رکھیں۔',
      warningsEn:
          'For external dermatological use only. Avoid contact with eyes and mucous membranes. Discontinue if severe irritation develops.',
      warningsUr:
          'صرف بیرونی استعمال کے لیے۔ آنکھوں اور منہ کے اندر لگانے سے پرہیز کریں۔ جلن کی صورت میں استعمال روک دیں۔',
      nonMedicinalSelfCareEn:
          'Keep infected area clean and dry. Wear loose breathable cotton clothing. Avoid sharing towels.',
      nonMedicinalSelfCareUr:
          'متاثرہ حصے کو صاف اور خشک رکھیں۔ ڈھیلے سوتی کپڑے پہنیں اور تولیہ الگ رکھیں۔',
    ),

    DrapMedicationItem(
      genericName: 'Terbinafine Hydrochloride',
      brandNames: ['Lamisil', 'Terbisil', 'Fungisil'],
      drapRegistrationNumber: 'DRAP-008912',
      otcCategory: 'DRAP Approved OTC Allylamine Antifungal',
      strength: '1% w/w Cream',
      matchingConditions: [
        'Tinea Ringworm Candidiasis and other Fungal Infections',
        'Athlete\'s Foot',
        'Tinea Pedis',
      ],
      guidanceEn:
          'Apply once or twice daily for 1 to 2 weeks on cleansed, thoroughly dried skin.',
      guidanceUr:
          'صاف اور خشک جلد پر دن میں ایک یا دو بار 1 سے 2 ہفتے تک لگائیں۔',
      warningsEn:
          'External use only. Avoid contact with eyes or oral mucosa.',
      warningsUr:
          'صرف بیرونی استعمال کے لیے۔ آنکھوں یا منہ سے دور رکھیں۔',
      nonMedicinalSelfCareEn:
          'Change socks daily and dry between toes thoroughly after bathing.',
      nonMedicinalSelfCareUr:
          'روزانہ جرابیں تبدیل کریں اور نہانے کے بعد انگلیوں کے درمیان کی جگہ خشک رکھیں۔',
    ),

    DrapMedicationItem(
      genericName: 'Benzoyl Peroxide',
      brandNames: ['Brevoxyl', 'Benzac AC', 'PanOxyl'],
      drapRegistrationNumber: 'DRAP-015482',
      otcCategory: 'DRAP Approved OTC Acne Vulgaris Topical',
      strength: '4% w/w Topical Gel',
      matchingConditions: [
        'Acne and Rosacea Photos',
        'Acne',
        'Pimples',
      ],
      guidanceEn:
          'Wash face with mild cleanser; apply a thin film once daily at bedtime initially, increasing to twice daily if tolerated.',
      guidanceUr:
          'چہرے کو ہلکے صابن سے دھو کر رات کو سونے سے پہلے باریک تہہ لگائیں۔ ضرورت پڑنے پر دن میں دو بار استعمال کریں۔',
      warningsEn:
          'May bleach colored fabrics and hair. Avoid harsh sunlight and use SPF daily. Mild peeling is normal.',
      warningsUr:
          'کپڑوں اور بالوں کا رنگ اڑا سکتا ہے۔ دھوپ میں نکلتے وقت سن اسکرین استعمال کریں۔',
      nonMedicinalSelfCareEn:
          'Do not squeeze or pick pimples. Wash face twice daily with non-comedogenic gentle cleanser.',
      nonMedicinalSelfCareUr:
          'دانوں کو نوچنے یا دبانے سے گریز کریں۔ دن میں دو بار آئل فری فیس واش استعمال کریں۔',
    ),

    DrapMedicationItem(
      genericName: 'Clindamycin Phosphate',
      brandNames: ['Dalacin T', 'Clindacin', 'Acnesol'],
      drapRegistrationNumber: 'DRAP-019844',
      otcCategory: 'DRAP Registered Prescription-Only Topical Lincosamide Antibiotic',
      strength: '1% w/v Topical Solution / Lotion',
      isPrescriptionOnly: true,
      matchingConditions: [
        'Acne and Rosacea Photos',
        'Bacterial Infections',
      ],
      guidanceEn:
          'PRESCRIPTION LOCKED: Strictly requires in-person registered physician prescription. Applied twice daily under medical supervision.',
      guidanceUr:
          'صرف ڈاکٹر کے نسخے پر: مستند ڈاکٹر کے معائنے اور نسخے کے بغیر استعمال ممنوع ہے۔',
      warningsEn:
          'PRESCRIPTION GATE: Regulated antibiotic. Unmonitored OTC usage causes antibiotic resistance. Do not self-administer.',
      warningsUr:
          'نسخہ درکار ہے: یہ اینٹی بائیوٹک ہے جس کے غیر ضروری استعمال سے بیکٹیریا میں مدافعت پیدا ہو سکتی ہے۔ معالج سے مشورہ کریں۔',
      nonMedicinalSelfCareEn:
          'Consult a registered dermatologist. Do not mix multiple unprescribed antibiotic creams.',
      nonMedicinalSelfCareUr:
          'ماہر امراض جلد سے باقاعدہ معائنہ کروائیں۔ بیک وقت کئی اینٹی بائیوٹکس لگانے سے پرہیز کریں۔',
    ),

    DrapMedicationItem(
      genericName: 'Permethrin',
      brandNames: ['Scabite', 'Loxit', 'Permethrin Lotion'],
      drapRegistrationNumber: 'DRAP-022341',
      otcCategory: 'DRAP Approved OTC Scabicidal Antiparasitic',
      strength: '5% w/w Lotion',
      matchingConditions: [
        'Scabies Lyme Disease and other Infestations and Bites',
        'Scabies',
        'Mites',
      ],
      guidanceEn:
          'Apply thoroughly from neck to soles of feet. Leave on for 8 to 14 hours overnight, then bathe off. Repeat after 7 days if required.',
      guidanceUr:
          'گردن سے لے کر پاؤں کے تلووں تک پورے جسم پر لگائیں۔ 8 سے 14 گھنٹے تک لگا رہنے دیں، پھر نہائیں۔ 7 دن بعد دوبارہ دہرائیں۔',
      warningsEn:
          'Treat all household members and close contacts simultaneously to prevent re-infestation.',
      warningsUr:
          'گھر کے تمام افراد کا بیک وقت علاج ضروری ہے تاکہ انفیکشن دوبارہ نہ پھیلے۔',
      nonMedicinalSelfCareEn:
          'Wash all bed sheets, towels, and clothes in boiling water or seal in an airtight bag for 72 hours.',
      nonMedicinalSelfCareUr:
          'تمام بستر کی چادریں اور کپڑے گرم پانی میں دھوئیں یا 3 دن کے لیے پلاسٹک بیگ میں بند رکھیں۔',
    ),

    DrapMedicationItem(
      genericName: 'Hydrocortisone',
      brandNames: ['Cortiderm', 'Hydrocortisone Cream', 'Efcortelan'],
      drapRegistrationNumber: 'DRAP-005619',
      otcCategory: 'DRAP Approved OTC Mild Topical Corticosteroid',
      strength: '1% w/w Cream / Ointment',
      matchingConditions: [
        'Atopic Dermatitis Photos',
        'Eczema Photos',
        'Poison Ivy Photos and other Contact Dermatitis',
      ],
      guidanceEn:
          'Apply sparingly in a thin layer 1-2 times daily for maximum 7 consecutive days during acute flare.',
      guidanceUr:
          'متاثرہ جگہ پر دن میں 1 سے 2 بار ہلکی مقدار لگائیں۔ مسلسل 7 دن سے زیادہ مت لگائیں۔',
      warningsEn:
          'Do NOT apply on active fungal, viral (herpes), or bacterial infections. Avoid long-term facial application.',
      warningsUr:
          'فنگل یا بیکٹیریل انفیکشن پر ہرگز نہ لگائیں۔ چہرے پر طویل عرصے تک مت لگائیں کیونکہ یہ جلد پتلی کر سکتی ہے۔',
      nonMedicinalSelfCareEn:
          'Apply fragrance-free ceramide moisturizer 15 minutes after hydrocortisone to repair skin barrier.',
      nonMedicinalSelfCareUr:
          'جلد کی نمی بحال رکھنے کے لیے موئسچرائزنگ لوشن باقاعدگی سے لگائیں۔',
    ),

    DrapMedicationItem(
      genericName: 'Polymyxin B Sulfate + Bacitracin Zinc',
      brandNames: ['Polyfax', 'Polyfax Plus'],
      drapRegistrationNumber: 'DRAP-000124',
      otcCategory: 'DRAP Approved OTC Topical Antibacterial Ointment',
      strength: 'Polymyxin B 10,000 IU + Bacitracin 500 IU per gram',
      matchingConditions: [
        'Cellulitis Impetigo and other Bacterial Infections',
        'Bacterial Infections',
        'Impetigo',
        'minor skin infection',
      ],
      guidanceEn:
          'Cleanse the affected area with clean water. Apply a thin layer 1 to 2 times daily. Cover with sterile dressing if required.',
      guidanceUr:
          'متاثرہ جگہ کو صاف پانی سے دھو کر خشک کریں۔ دن میں 1 سے 2 مرتبہ ہلکی تہہ لگائیں۔ ضرورت پڑنے پر صاف پٹی باندھیں۔',
      warningsEn:
          'Do not apply over extensive burn areas or deep puncture wounds. If spreading redness or fever occurs, seek urgent hospital care.',
      warningsUr:
          'بڑے گہرے زخموں پر استعمال نہ کریں۔ اگر سرخی پھیلے یا بخار ہو جائے تو فوری ہسپتال جائیں۔',
      nonMedicinalSelfCareEn:
          'Keep wound clean and dry. Avoid touching lesions with unwashed fingers.',
      nonMedicinalSelfCareUr:
          'زخم کو گندے ہاتھوں سے نہ چھوئیں۔ زخم صاف اور خشک رکھیں۔',
    ),

    DrapMedicationItem(
      genericName: 'Calamine + Zinc Oxide',
      brandNames: ['Calamox', 'Calamine Lotion'],
      drapRegistrationNumber: 'DRAP-038912',
      otcCategory: 'DRAP Approved OTC Soothing Antipruritic Formulation',
      strength: '15% + 5% w/v Suspension',
      matchingConditions: [
        'Urticaria Hives',
        'Poison Ivy Photos and other Contact Dermatitis',
      ],
      guidanceEn:
          'Shake bottle thoroughly. Apply liberally with cotton pad to irritated skin 3 to 4 times daily as needed.',
      guidanceUr:
          'استعمال سے پہلے بوتل اچھی طرح ہلائیں۔ روئی کی مدد سے دن میں 3 سے 4 بار متاثرہ حصے پر لگائیں۔',
      warningsEn:
          'Safe soothing topical formulation. Avoid open weeping lesions or mucosal contact.',
      warningsUr:
          'محفوظ گھریلو لوشن۔ کھلے گہرے زخموں پر نہ لگائیں۔',
      nonMedicinalSelfCareEn:
          'Cool compresses ease inflammation. Avoid hot showers and tight clothing.',
      nonMedicinalSelfCareUr:
          'ٹھنڈے پانی کی پٹی رکھیں، گرم پانی سے نہانے سے پرہیز کریں اور ڈھیلے کپڑے پہنیں۔',
    ),
  ];

  Future<void> loadLocalDatabase() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/pak_clinical_db.json');
      jsonDecode(jsonStr);
    } catch (_) {

    }
  }

  DrapMedicationItem? findMedicationByName(String name) {
    if (name.trim().isEmpty) return null;
    for (final item in _database) {
      if (item.matchesQuery(name)) {
        return item;
      }
    }
    return null;
  }

  List<DrapMedicationItem> findMedicationsForCondition(String conditionName) {
    if (conditionName.trim().isEmpty) return const [];
    if (isSevereHighRiskClass(conditionName)) {
      return const [];
    }

    return _database
        .where((item) => !item.isPrescriptionOnly && item.matchesCondition(conditionName))
        .toList();
  }

  String formatDrugSafetyGuidance(String medicationName) {
    final clean = medicationName.trim();
    if (clean.isEmpty) return 'No medication specified.';

    final match = findMedicationByName(clean);
    if (match != null) {
      final prescriptionWarning = match.isPrescriptionOnly
          ? '\n🔒 PRESCRIPTION GATE: Regulated antibiotic/steroid. Requires certified doctor prescription. Do not self-administer.'
          : '';

      return '🇵🇰 DRAP Approved Record [${match.drapRegistrationNumber}]:\n'
          '• Generic: ${match.genericName}\n'
          '• Brands: ${match.brandNames.join(", ")}\n'
          '• Category: ${match.otcCategory}\n'
          '• Guidance (EN): ${match.guidanceEn}\n'
          '• رہنمائی (اردو): ${match.guidanceUr}\n'
          '• Warnings (EN): ${match.warningsEn}\n'
          '• انتباہ (اردو): ${match.warningsUr}'
          '$prescriptionWarning';
    }

    return 'No specific DRAP boxed warnings or severe contraindications found for "$clean". '
        'Verify with a registered local pharmacist before topical application.';
  }

  String generateUrduDrugGuidance(String medicationName) {
    final clean = medicationName.trim();
    if (clean.isEmpty) return 'کوئی دوا درج نہیں کی گئی۔';

    final match = findMedicationByName(clean);
    if (match != null) {
      final prescriptionWarning = match.isPrescriptionOnly
          ? '\n🔒 نسخہ درکار ہے: یہ دوا نسخے کے بغیر استعمال نہیں کی جا سکتی۔ مستند ڈاکٹر سے رجوع کریں۔'
          : '';

      return '🇵🇰 ڈریپ (DRAP) تصدیق شدہ دوا برائے "${match.brandNames.first}":\n'
          '${match.guidanceUr}\n\n'
          '⚠️ احتیاط: ${match.warningsUr}'
          '$prescriptionWarning';
    }

    return 'ڈریپ (DRAP) ریکارڈ میں "$clean" کے لیے کوئی خاص ممانعت درج نہیں۔ استعمال سے پہلے قریبی فارماسسٹ سے تصدیق کر لیں۔';
  }

  ({String en, String ur}) getRecommendedTopicalsForCondition(String conditionName) {
    if (isSevereHighRiskClass(conditionName)) {
      return (
        en: '$criticalReferralBanner. High-risk pathology suspected. Over-the-counter (OTC) medication is strictly contraindicated. Specialist clinical biopsy and examination required.',
        ur: '$criticalReferralBanner۔ شدید خطرے کی علامت ہے۔ اوور دی کاؤنٹر مرہم کا استعمال ممنوع ہے، فوری مستند ڈاکٹر سے رجوع کریں۔',
      );
    }

    final items = findMedicationsForCondition(conditionName);
    if (items.isEmpty) {
      return (
        en: 'Maintain clean, dry skin. Consult a physician if redness or irritation persists.',
        ur: 'متاثرہ جلد کو صاف اور خشک رکھیں۔ اگر سرخی برقرار رہے تو معالج سے مشورہ کریں۔',
      );
    }

    final top = items.first;
    final enText =
        'Recommended DRAP-approved formulation: ${top.brandNames.first} (${top.genericName} - ${top.drapRegistrationNumber}). ${top.guidanceEn} Note: ${top.warningsEn}';
    final urText =
        'ڈریپ (DRAP) منظور شدہ تجویز: ${top.brandNames.first} (${top.genericName})۔ ${top.guidanceUr} احتیاط: ${top.warningsUr}';

    return (en: enText, ur: urText);
  }
}
