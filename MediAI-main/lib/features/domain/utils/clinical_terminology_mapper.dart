import 'package:flutter/widgets.dart';
import 'package:mediscanai/core/services/locale_service.dart';

bool isUrdu(BuildContext context) =>
    LocaleService.isUrdu || Localizations.maybeLocaleOf(context)?.languageCode == 'ur';

class LocalizedTerm {
  final String en;
  final String ur;
  const LocalizedTerm({required this.en, required this.ur});
  String get(BuildContext context) => isUrdu(context) ? ur : en;
  String byLang([String? lang]) =>
      (lang == 'ur' || (lang == null && LocaleService.isUrdu)) ? ur : en;
}

class ThreeTieredClinicalLabel {
  final String benchmarkScientificName;
  final String plainVernacularEn;
  final String regionalUrduContext;

  const ThreeTieredClinicalLabel({
    required this.benchmarkScientificName,
    required this.plainVernacularEn,
    required this.regionalUrduContext,
  });

  String formattedBilingual([String? lang]) {
    final effectiveLang = lang ?? (LocaleService.isUrdu ? 'ur' : 'en');
    if (effectiveLang == 'ur') {
      return regionalUrduContext;
    }
    return plainVernacularEn;
  }

  Map<String, String> toMap() => {
    'benchmarkScientificName': benchmarkScientificName,
    'plainVernacularEn': plainVernacularEn,
    'regionalUrduContext': regionalUrduContext,
  };
}

class LaymanTerm {
  final String technicalName;
  final String friendlyNameEn;
  final String friendlyNameUr;
  final String urgencyTagEn;
  final String urgencyTagUr;
  final bool isHighUrgency;
  final String patientExplanationEn;
  final String patientExplanationUr;
  final String benchmarkScientificName;
  final String plainVernacularEn;
  final String regionalUrduContext;

  const LaymanTerm({
    required this.technicalName,
    required this.friendlyNameEn,
    required this.friendlyNameUr,
    this.urgencyTagEn = 'Self-Care / Low Risk',
    this.urgencyTagUr = 'گھریلو دیکھ بھال / کم خطرہ',
    this.isHighUrgency = false,
    this.patientExplanationEn = '',
    this.patientExplanationUr = '',
    String? benchmarkScientificName,
    String? plainVernacularEn,
    String? regionalUrduContext,
  })  : benchmarkScientificName = benchmarkScientificName ?? technicalName,
        plainVernacularEn = plainVernacularEn ?? friendlyNameEn,
        regionalUrduContext = regionalUrduContext ?? friendlyNameUr;

  String get english => friendlyNameEn;
  String get urdu => friendlyNameUr;
  String? get patientNoteEn => patientExplanationEn;
  String? get patientNoteUr => patientExplanationUr;

  ThreeTieredClinicalLabel get threeTieredLabel => ThreeTieredClinicalLabel(
        benchmarkScientificName: benchmarkScientificName,
        plainVernacularEn: plainVernacularEn,
        regionalUrduContext: regionalUrduContext,
      );

  String bilingualTitle([String? languageCode]) {
    final effectiveLang = languageCode ?? (LocaleService.isUrdu ? 'ur' : 'en');
    if (effectiveLang == 'ur') {
      return friendlyNameUr;
    }
    return friendlyNameEn;
  }

  String bilingualUrgency([String? languageCode]) {
    final effectiveLang = languageCode ?? (LocaleService.isUrdu ? 'ur' : 'en');
    if (effectiveLang == 'ur') {
      return urgencyTagUr;
    }
    return urgencyTagEn;
  }
}

class ClinicalTerminologyMapper {
  ClinicalTerminologyMapper._();

  static const List<LaymanTerm> _terms = [
    LaymanTerm(
      technicalName: 'Acne and Rosacea Photos',
      friendlyNameEn: 'Pimples, Acne & Facial Redness (Acne / Rosacea)',
      friendlyNameUr: 'چہرے کے دانے، کیل مہاسے اور سرخی (ایکنی)',
      benchmarkScientificName: 'Acne and Rosacea Photos',
      plainVernacularEn: 'Pimples, Acne & Facial Redness',
      regionalUrduContext: 'چہرے کے دانے، کیل مہاسے، اضافی چکنائی اور سرخی',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Inflammatory spots or facial redness. Usually managed with gentle cleansing, topical treatments, and avoiding oily cosmetics.',
      patientExplanationUr:
          'چہرے پر بننے والے عام دانے یا سرخی۔ عام طور پر مناسب صفائی، معیاری فیس واش اور آئل فری مصنوعات سے ٹھیک ہو جاتے ہیں۔',
    ),

    LaymanTerm(
      technicalName:
          'Actinic Keratosis Basal Cell Carcinoma and other Malignant Lesions',
      friendlyNameEn: 'Pre-Cancerous / Suspicious Skin Growth',
      friendlyNameUr: 'مشتبہ جلدی ابھار یا کینسر کا امکان',
      benchmarkScientificName:
          'Actinic Keratosis Basal Cell Carcinoma and other Malignant Lesions',
      plainVernacularEn: 'Pre-Cancerous & Malignant Skin Growth',
      regionalUrduContext: 'جلد کا مشتبہ کینسر، زخم یا غیر معمولی سخت ابھار',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'فوری ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Rough, persistent scaly patch or nodule that requires clinical dermatological evaluation and biopsy.',
      patientExplanationUr:
          'جلد پر کھردرے، مستقل دھبے یا غیر معمولی ابھار جن کے جلد از جلد طبی معائنے اور بایوپسی کی ضرورت ہے۔',
    ),

    LaymanTerm(
      technicalName: 'Atopic Dermatitis Photos',
      friendlyNameEn: 'Dry Skin Itch & Rash (Eczema)',
      friendlyNameUr: 'جلد کی الرجی (ایگزیما)',
      benchmarkScientificName: 'Atopic Dermatitis Photos',
      plainVernacularEn: 'Dry Skin Itch & Atopic Eczema',
      regionalUrduContext: 'خشک جلد کی شدید الرجی، ایگزیما اور کھجلی',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Dry, itchy patches of skin. Keep area moisturized with fragrance-free lotion and avoid harsh detergents.',
      patientExplanationUr:
          'خشک اور خارش زدہ جلد کے دھبے۔ جلد کو معیاری موئسچرائزر سے تر رکھیں اور خوشبودار صابن سے پرہیز کریں۔',
    ),

    LaymanTerm(
      technicalName: 'Bullous Disease Photos',
      friendlyNameEn: 'Fluid-Filled Skin Blisters',
      friendlyNameUr: 'پانی بھرے چھالے اور آبلے',
      benchmarkScientificName: 'Bullous Disease Photos',
      plainVernacularEn: 'Fluid-Filled Skin Blisters (Bullous Disease)',
      regionalUrduContext: 'پانی بھرے چھالے، نازک آبلے اور جلد کی ٹوٹ پھوٹ',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Blistering condition where fluid-filled bubbles form on the skin. Requires direct medical examination.',
      patientExplanationUr:
          'جلد پر پانی والے چھالے یا آبلے بننے کی کیفیت۔ فوری طبی معائنے اور علاج کی ضرورت ہے۔',
    ),

    LaymanTerm(
      technicalName: 'Cellulitis Impetigo and other Bacterial Infections',
      friendlyNameEn: 'Bacterial Infection & Swelling (Cellulitis)',
      friendlyNameUr: 'بیکٹیریل انفیکشن اور سوجن (سیلولائٹس)',
      benchmarkScientificName:
          'Cellulitis Impetigo and other Bacterial Infections',
      plainVernacularEn:
          'Bacterial Infection & Swelling (Cellulitis / Impetigo)',
      regionalUrduContext:
          'بیکٹیریل انفیکشن، پیپ والے دانے اور گرم سوجن (سیلولائٹس)',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'فوری ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Bacterial dermis infection marked by spreading redness, warmth, and tenderness. Requires prescription antibiotics.',
      patientExplanationUr:
          'جلد کی گہرائی میں بیکٹیریل انفیکشن جس سے سرخی، گرمائش اور سوجن ہوتی ہے۔ فوری اینٹی بائیوٹک درکار ہے۔',
    ),

    LaymanTerm(
      technicalName: 'Eczema Photos',
      friendlyNameEn: 'Dry Irritated Skin (Eczema / Dermatitis)',
      friendlyNameUr: 'خشک، خارش زدہ اور سرخ جلد (ایگزیما)',
      benchmarkScientificName: 'Eczema Photos',
      plainVernacularEn: 'Dry Irritated Skin (Eczema)',
      regionalUrduContext: 'خشک، چھلکے دار، خارش زدہ جلد اور چنبل',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Irritated, itchy skin patches. Avoid triggers, hydrate with gentle barrier creams, and do not scratch.',
      patientExplanationUr:
          'جلد پر خارش اور چڑچڑاہٹ کے دھبے۔ خارش کرنے سے گریز کریں اور موئسچرائزنگ کریم باقاعدگی سے لگائیں۔',
    ),

    LaymanTerm(
      technicalName: 'Exanthems and Drug Eruptions',
      friendlyNameEn: 'Widespread Medication Rash',
      friendlyNameUr: 'ادویات کے ردعمل کے دانے اور ریش',
      benchmarkScientificName: 'Exanthems and Drug Eruptions',
      plainVernacularEn: 'Widespread Medication & Viral Body Rash',
      regionalUrduContext: 'دوائی کا شدید ری ایکشن یا وائرل دانے اور جسمانی سرخی',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Widespread rash often triggered as an adverse reaction to medications or a systemic virus.',
      patientExplanationUr:
          'نئی دوائی کے استعمال یا وائرل ردعمل کے بعد جسم پر پھیلنے والے دانے۔ اپنے معالج سے فوری رابطہ کریں۔',
    ),

    LaymanTerm(
      technicalName: 'Hair Loss Photos Alopecia and other Hair Diseases',
      friendlyNameEn: 'Hair Thinning & Patchy Loss (Alopecia)',
      friendlyNameUr: 'بال جھڑنا یا سر کا گنج پن (ایلوپیشیا)',
      benchmarkScientificName:
          'Hair Loss Photos Alopecia and other Hair Diseases',
      plainVernacularEn: 'Hair Thinning, Shedding & Patchy Baldness',
      regionalUrduContext: 'سر کے بال گرنا، چنڈی اور دائروں کا گنج پن (ایلوپیشیا)',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'طبی رہنمائی / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Thinning hair or circular patches of shedding. Consider blood tests and consultation with a trichologist.',
      patientExplanationUr:
          'سر کے بالوں کا گرنا یا دائروں کی شکل میں گنج پن۔ غذائیت کی جانچ اور معالج سے مشورہ مفید ہے۔',
    ),

    LaymanTerm(
      technicalName: 'Herpes HPV and other STDs Photos',
      friendlyNameEn: 'Viral Blister Outbreak (Herpes)',
      friendlyNameUr: 'وائرل چھالے یا دانوں کا انفیکشن',
      benchmarkScientificName: 'Herpes HPV and other STDs Photos',
      plainVernacularEn: 'Viral Blister Clusters & Contagious Lesions',
      regionalUrduContext: 'وائرل چھالوں کا گچھا، ہرپیز اور جلدی دانے',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Viral blistering eruptions. Avoid touching or breaking blisters and consult a physician for antiviral treatment.',
      patientExplanationUr:
          'وائرس کی وجہ سے بننے والے تکلیف دہ چھالے۔ چھالوں کو چھیڑنے سے گریز کریں اور اینٹی وائرل علاج کے لیے معالج سے رجوع کریں۔',
    ),

    LaymanTerm(
      technicalName: 'Light Diseases and Disorders of Pigmentation',
      friendlyNameEn: 'Skin Discoloration & Sun Spots (Melasma)',
      friendlyNameUr: 'جلد کی رنگت میں تبدیلی اور چھائیاں',
      benchmarkScientificName:
          'Light Diseases and Disorders of Pigmentation',
      plainVernacularEn: 'Sun Spots, Melasma & Skin Discoloration',
      regionalUrduContext: 'دھوپ کے داغ، چھائیاں اور جلد کی رنگت کی خرابی',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Hyperpigmentation, uneven skin tone, or sun spots. Daily broad-spectrum SPF 50 sunscreen is recommended.',
      patientExplanationUr:
          'دھوپ یا ہارمونز کی وجہ سے رنگت کی تبدیلی اور چھائیاں۔ دھوپ سے بچاؤ کے لیے سن اسکرین کا باقاعدہ استعمال کریں۔',
    ),

    LaymanTerm(
      technicalName: 'Lupus and other Connective Tissue diseases',
      friendlyNameEn: 'Autoimmune Skin Rash (Lupus / Connective)',
      friendlyNameUr: 'قوت مدافعت کی خرابی کا جلدی ریش (لوپس)',
      benchmarkScientificName:
          'Lupus and other Connective Tissue diseases',
      plainVernacularEn: 'Autoimmune Butterfly Rash & Connective Inflammation',
      regionalUrduContext:
          'لوپس (قوت مدافعت کی بیماری)، چہرے کی سرخی اور ریش',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Autoimmune skin inflammation such as butterfly malar rash. Clinical autoimmune screening is essential.',
      patientExplanationUr:
          'قوت مدافعت کے ردعمل سے چہرے یا جسم پر بننے والا ریش۔ ماہر امراضِ جلد سے تشخیصی ٹیسٹ کروائیں۔',
    ),

    LaymanTerm(
      technicalName: 'Melanoma Skin Cancer Nevi and Moles',
      friendlyNameEn: 'Critical / Irregular Mole (Melanoma Risk)',
      friendlyNameUr: 'غیر معمولی یا مشتبہ تل (میلانوما کا خطرہ)',
      benchmarkScientificName: 'Melanoma Skin Cancer Nevi and Moles',
      plainVernacularEn: 'Irregular Mole & High-Risk Skin Cancer',
      regionalUrduContext: 'مشتبہ یا بے قاعدہ تل اور خطرناک جلد کا کینسر (میلانوما)',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'فوری ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Asymmetrical or evolving dark lesion. Urgent dermatological examination with dermoscopy is strongly advised.',
      patientExplanationUr:
          'غیر متوازن یا رنگ و سائز بدلنے والا تل۔ کسی مستند ڈرمیٹالوجسٹ سے فوری معائنہ اور ڈرموسکوپی کروائیں۔',
    ),

    LaymanTerm(
      technicalName: 'Nail Fungus and other Nail Disease',
      friendlyNameEn: 'Fungal Nail Infection',
      friendlyNameUr: 'ناخن کی فنگس اور رنگت کی تبدیلی',
      benchmarkScientificName: 'Nail Fungus and other Nail Disease',
      plainVernacularEn: 'Fungal Nail Infection & Discolored Nails',
      regionalUrduContext: 'ناخن کی فنگس، پیلا پن اور ناخنوں کا موٹا ہو کر ٹوٹنا',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / اینٹی فنگل',
      isHighUrgency: false,
      patientExplanationEn:
          'Thickened, discolored, or brittle nails caused by fungal growth. Keep hands and feet dry.',
      patientExplanationUr:
          'ناخنوں کا موٹا ہونا، پیلا پڑنا یا ٹوٹنا۔ پاؤں کو خشک رکھیں اور اینٹی فنگل علاج اپنائیں۔',
    ),

    LaymanTerm(
      technicalName: 'Poison Ivy Photos and other Contact Dermatitis',
      friendlyNameEn: 'Allergic Contact Rash (Contact Dermatitis)',
      friendlyNameUr: 'کسی چیز کو چھونے سے الرجی اور خارش',
      benchmarkScientificName:
          'Poison Ivy Photos and other Contact Dermatitis',
      plainVernacularEn: 'Allergic Contact Rash & Chemical Irritation',
      regionalUrduContext: 'کسی چیز کو چھونے سے الرجی، خارش اور جلن',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Localized skin reaction from touching an irritant or allergen. Wash thoroughly with cool water and apply soothing calamine.',
      patientExplanationUr:
          'کسی بیرونی کیمیکل، پودے یا الرجی والی چیز کو چھونے سے بننے والے دانے۔ ٹھنڈے پانی سے دھوئیں اور سوتھنگ لوشن لگائیں۔',
    ),

    LaymanTerm(
      technicalName: 'Psoriasis pictures Lichen Planus and related diseases',
      friendlyNameEn: 'Scaly Skin Patches (Psoriasis)',
      friendlyNameUr: 'چھلکے دار سرخی مائل دھبے (سورائسس)',
      benchmarkScientificName:
          'Psoriasis pictures Lichen Planus and related diseases',
      plainVernacularEn: 'Scaly Silvery Skin Patches (Psoriasis)',
      regionalUrduContext: 'چھلکے دار سرخی مائل دھبے اور سورائسس',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Chronic scaly silvery plaques. Requires prescribed topical therapy or phototherapy under medical supervision.',
      patientExplanationUr:
          'جلد پر ابھرے ہوئے چاندی جیسے چھلکے دار سرخ دھبے۔ طبی نگرانی میں ادویاتی لوشن کا استعمال کریں۔',
    ),

    LaymanTerm(
      technicalName: 'Scabies Lyme Disease and other Infestations and Bites',
      friendlyNameEn: 'Insect Bite / Itch Mite (Scabies)',
      friendlyNameUr: 'خارش کا کیڑا یا کیڑے کا کاٹا (اسکیبیز)',
      benchmarkScientificName:
          'Scabies Lyme Disease and other Infestations and Bites',
      plainVernacularEn: 'Mite Infestation (Scabies) & Nocturnal Itch',
      regionalUrduContext:
          'خارش کا کیڑا (اسکیبیز)، رات کی شدید کھجلی اور دانوں کا جال',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Intense nocturnal itch caused by microscopic mites or insect bites. Requires targeted antiparasitic treatment for all household members.',
      patientExplanationUr:
          'رات کے وقت شدید خارش پیدا کرنے والے باریک کیڑے۔ پورے خاندان کے لیے بیک وقت اینٹی پیراسائٹک لوشن درکار ہوتا ہے۔',
    ),

    LaymanTerm(
      technicalName: 'Seborrheic Keratoses and other Benign Tumors',
      friendlyNameEn: 'Harmless Age Spot / Skin Growth',
      friendlyNameUr: 'عمر کا بے ضرر داغ یا مسا',
      benchmarkScientificName:
          'Seborrheic Keratoses and other Benign Tumors',
      plainVernacularEn: 'Harmless Waxy Age Spot & Non-Cancerous Growth',
      regionalUrduContext: 'عمر کا بے ضرر داغ، مسا یا عام جلدی ابھار',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'محفوظ / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Harmless waxy or raised non-cancerous growth that naturally occurs with age. No intervention required unless irritated.',
      patientExplanationUr:
          'عمر کے ساتھ ابھرنے والا بالکل بے ضرر اور غیر سرطانی مسا یا تل۔ اس سے کوئی خطرہ لاحق نہیں ہوتا۔',
    ),

    LaymanTerm(
      technicalName: 'Systemic Disease',
      friendlyNameEn: 'Skin Signs of Internal Health',
      friendlyNameUr: 'اندرونی جسمانی صحت کا اثر',
      benchmarkScientificName: 'Systemic Disease',
      plainVernacularEn: 'Skin Signs of Internal Health / Metabolic Conditions',
      regionalUrduContext:
          'اندرونی جسمانی صحت، شوگر یا جگر کے اثرات',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Cutaneous manifestation related to metabolic, hepatic, or vascular internal conditions. Medical evaluation is advised.',
      patientExplanationUr:
          'جسم کی اندرونی بیماریوں (جیسے شوگر یا جگر) کی وجہ سے جلد پر پڑنے والے اثرات۔ معالج سے مشورہ کریں۔',
    ),

    LaymanTerm(
      technicalName:
          'Tinea Ringworm Candidiasis and other Fungal Infections',
      friendlyNameEn: 'Ringworm / Fungal Infection (Tinea)',
      friendlyNameUr: 'داد / چنبل (فنگل انفیکشن)',
      benchmarkScientificName:
          'Tinea Ringworm Candidiasis and other Fungal Infections',
      plainVernacularEn: 'Ringworm & Fungal Skin Infection',
      regionalUrduContext: 'داد، فنگل انفیکشن اور خارش والے دائرے',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / اینٹی فنگل',
      isHighUrgency: false,
      patientExplanationEn:
          'Annular ring-shaped fungal rash with red borders. Clears with over-the-counter antifungal creams.',
      patientExplanationUr:
          'گول دائرے والی خارش اور داد۔ کاؤنٹر سے ملنے والی اینٹی فنگل کریم سے آسانی سے ٹھیک ہو جاتی ہے۔',
    ),

    LaymanTerm(
      technicalName: 'Urticaria Hives',
      friendlyNameEn: 'Allergic Itchy Welts (Hives / Urticaria)',
      friendlyNameUr: 'اچانک ابھرنے والی پتی اور چھپاکی',
      benchmarkScientificName: 'Urticaria Hives',
      plainVernacularEn: 'Sudden Itchy Welts & Allergic Hives',
      regionalUrduContext: 'اچانک ابھرنے والی پتی، چھپاکی اور الرجی کی سوجن',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / الرجی کی دوا',
      isHighUrgency: false,
      patientExplanationEn:
          'Sudden raised itchy red wheals triggered by allergens or stress. Antihistamines provide rapid relief.',
      patientExplanationUr:
          'الرجی کی وجہ سے اچانک ابھرنے والی سرخ سوجن اور پتی۔ اینٹی ہسٹامائن گولی سے فوری آرام ملتا ہے۔',
    ),

    LaymanTerm(
      technicalName: 'Vascular Tumors',
      friendlyNameEn: 'Benign Blood Vessel Mark (Hemangioma)',
      friendlyNameUr: 'خون کی نالیوں کا بے ضرر ابھار',
      benchmarkScientificName: 'Vascular Tumors',
      plainVernacularEn: 'Benign Blood Vessel Mark & Superficial Hemangioma',
      regionalUrduContext: 'خون کی نالیوں کا بے ضرر ابھار اور سرخ تل',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'محفوظ / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Harmless collection of superficial blood vessels forming a red or purple mark. Typically benign.',
      patientExplanationUr:
          'جلد کی باریک خون کی نالیوں کا بے ضرر سرخ ابھار۔ یہ مکمل طور پر محفوظ ہوتا ہے۔',
    ),

    LaymanTerm(
      technicalName: 'Vasculitis Photos',
      friendlyNameEn: 'Blood Vessel Rash (Vasculitis)',
      friendlyNameUr: 'خون کی نالیوں کی سوزش کے نشانات',
      benchmarkScientificName: 'Vasculitis Photos',
      plainVernacularEn: 'Blood Vessel Rash (Vasculitis)',
      regionalUrduContext:
          'خون کی نالیوں کی سوزش کے نشانات، جامنی دھبے اور پورپورا',
      urgencyTagEn: 'Consult a Dermatologist',
      urgencyTagUr: 'فوری ماہر امراض جلد سے رجوع کریں',
      isHighUrgency: true,
      patientExplanationEn:
          'Purple or dark red spots caused by vascular inflammation. Immediate consultation with a doctor is necessary.',
      patientExplanationUr:
          'خون کی نالیوں میں سوزش سے بننے والے جامنی یا سرخ نشانات۔ فوری طور پر ڈاکٹر کو دکھائیں۔',
    ),

    LaymanTerm(
      technicalName: 'Warts Molluscum and other Viral Infections',
      friendlyNameEn: 'Viral Skin Bumps & Warts',
      friendlyNameUr: 'وائرل مسے اور چھوٹے دانے',
      benchmarkScientificName:
          'Warts Molluscum and other Viral Infections',
      plainVernacularEn: 'Viral Skin Warts & Contagious Bumps',
      regionalUrduContext: 'وائرل مسے، ابھار اور چھوت کے دانے',
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'Common harmless viral bumps. Maintain good hygiene, avoid picking, and consider over-the-counter wart treatments.',
      patientExplanationUr:
          'عام وائرل مسے یا ابھار۔ انہیں نوچنے سے پرہیز کریں تاکہ یہ مزید نہ پھیلیں۔',
    ),

    LaymanTerm(
      technicalName: 'non_skin',
      friendlyNameEn: 'Non-Skin Surface Detected',
      friendlyNameUr: 'یہ انسانی جلد نہیں ہے',
      benchmarkScientificName: 'non_skin',
      plainVernacularEn: 'Non-Skin Surface Detected',
      regionalUrduContext: 'یہ انسانی جلد نہیں ہے',
      urgencyTagEn: 'Invalid Scan',
      urgencyTagUr: 'غیر جلدی شے',
      isHighUrgency: false,
      patientExplanationEn:
          'Please take a photo directly on the affected skin area.',
      patientExplanationUr: 'براہ کرم صرف متاثرہ جلد کی تصویر لیں۔',
    ),

    LaymanTerm(
      technicalName: 'Normal / Healthy Skin Surface',
      friendlyNameEn: 'Healthy & Clear Skin',
      friendlyNameUr: 'صاف اور صحت مند جلد',
      benchmarkScientificName: 'Normal Epidermal Surface / Intact Homeostasis',
      plainVernacularEn: 'Healthy & Clear Skin',
      regionalUrduContext: 'صاف، شفاف اور صحت مند جلد',
      urgencyTagEn: 'Normal / Low Risk',
      urgencyTagUr: 'محفوظ / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'No visible rash or disease detected on this area.',
      patientExplanationUr:
          'جلد پر کسی بیماری یا الرجی کے اثرات ظاہر نہیں ہوئے۔',
    ),

    LaymanTerm(
      technicalName: 'Healthy Skin / No Active Lesion',
      friendlyNameEn: 'Healthy & Clear Skin',
      friendlyNameUr: 'صاف اور صحت مند جلد',
      benchmarkScientificName: 'Intact Cutaneous Barrier / No Active Dermatosis',
      plainVernacularEn: 'Healthy & Clear Skin',
      regionalUrduContext: 'صاف اور صحت مند جلد',
      urgencyTagEn: 'Normal / Low Risk',
      urgencyTagUr: 'محفوظ / کم خطرہ',
      isHighUrgency: false,
      patientExplanationEn:
          'No visible rash or disease detected on this area.',
      patientExplanationUr:
          'جلد پر کسی بیماری یا الرجی کے اثرات ظاہر نہیں ہوئے۔',
    ),

    LaymanTerm(
      technicalName: 'Inconclusive Scan',
      friendlyNameEn: 'Inconclusive Scan',
      friendlyNameUr: 'تصویر واضح نہیں ہے',
      benchmarkScientificName: 'Sub-Optimal Image Resolution / Undetermined Pattern',
      plainVernacularEn: 'Inconclusive Scan / Retake Required',
      regionalUrduContext: 'غیر واضح اسکین / دوبارہ تصویر بنائیں',
      urgencyTagEn: 'Retake Photo',
      urgencyTagUr: 'دوبارہ تصویر لیں',
      isHighUrgency: false,
      patientExplanationEn:
          'Lighting is low or the spot is blurry. Please hold camera 10cm away with direct light and rescan.',
      patientExplanationUr:
          'براہ کرم اچھی روشنی میں داغ کے قریب سے دوبارہ تصویر بنائیں۔',
    ),

    LaymanTerm(
      technicalName: 'Invalid or Inconclusive Scan',
      friendlyNameEn: 'Invalid or Inconclusive Scan',
      friendlyNameUr: 'ناقابل قبول یا غیر واضح اسکین',
      benchmarkScientificName: 'Unverified Dermatological Target',
      plainVernacularEn: 'Invalid or Inconclusive Scan',
      regionalUrduContext: 'ناقابل قبول یا غیر واضح اسکین',
      urgencyTagEn: 'Scan Not Accepted',
      urgencyTagUr: 'اسکین قبول نہیں ہوا',
      isHighUrgency: false,
      patientExplanationEn:
          'The system could not detect a valid human skin condition. Please review the criteria below and scan again.',
      patientExplanationUr:
          'سسٹم کسی قابلِ شناخت جلدی کیفیت کی تصدیق نہیں کر سکا۔ نیچے دی گئی ہدایات دیکھ کر دوبارہ اسکین کریں۔',
    ),

    LaymanTerm(
      technicalName: 'Indeterminate Scan',
      friendlyNameEn: 'Indeterminate Scan',
      friendlyNameUr: 'غیر حتمی نتیجہ',
      benchmarkScientificName:
          'Indeterminate Cutaneous Presentation (<25% Confidence)',
      plainVernacularEn:
          'Indeterminate Scan (Better Lighting Required)',
      regionalUrduContext:
          'غیر حتمی نتیجہ (بہتر روشنی میں دوبارہ تصویر لیں)',
      urgencyTagEn: 'Retake Photo',
      urgencyTagUr: 'دوبارہ تصویر لیں',
      isHighUrgency: false,
      patientExplanationEn:
          'Inference confidence is below 25%. Please retake the photo under better lighting.',
      patientExplanationUr:
          'تشخیصی یقین کی شرح 25 فیصد سے کم ہے۔ برائے مہربانی بہتر روشنی میں دوبارہ تصویر لیں۔',
    ),

    LaymanTerm(
      technicalName: 'Indeterminate / Multiple Overlapping Dermatological Patterns',
      friendlyNameEn: 'Indeterminate / Multiple Overlapping Dermatological Patterns',
      friendlyNameUr: 'غیر حتمی / باہم ملتے جلتے جلدی نقوش',
      benchmarkScientificName:
          'Indeterminate Cutaneous Presentation (Multiple Overlapping Dermatological Patterns)',
      plainVernacularEn:
          'Indeterminate Overlapping Skin Patterns (Clinical Review Required)',
      regionalUrduContext:
          'غیر حتمی اور باہم ملتے جلتے جلدی نقوش (ماہر ڈاکٹر کا معائنہ لازمی ہے)',
      urgencyTagEn: 'Dermatologist Review Required',
      urgencyTagUr: 'ماہر امراض جلد سے معائنہ ضروری ہے',
      isHighUrgency: true,
      patientExplanationEn:
          'Primary lesion confidence is below the safe threshold (<25%). Multiple overlapping dermatological patterns detected. Professional clinical evaluation is required.',
      patientExplanationUr:
          'تشخیصی یقین کی شرح 25 فیصد سے کم ہے۔ متعدد جلدی علامات کے باہم ملاپ کی وجہ سے حتمی نتیجہ ممکن نہیں، مستند ڈاکٹر سے رجوع کریں۔',
    ),
  ];

  static LaymanTerm mapToLayman(String technicalName) {
    final cleanInput = technicalName.trim().toLowerCase();

    for (final term in _terms) {
      if (term.technicalName.toLowerCase() == cleanInput) {
        return term;
      }
    }

    for (final term in _terms) {
      final termKey = term.technicalName.toLowerCase();
      if (cleanInput.contains(termKey) || termKey.contains(cleanInput)) {
        return term;
      }
    }

    if (cleanInput.contains('indeterminate') ||
        cleanInput.contains('overlapping')) {
      return _terms.firstWhere(
        (t) => t.technicalName.contains('Indeterminate'),
      );
    }
    if (cleanInput.contains('not accepted') ||
        cleanInput.contains('invalid or inconclusive') ||
        cleanInput.contains('scan not accepted')) {
      return _terms.firstWhere(
        (t) => t.technicalName == 'Invalid or Inconclusive Scan',
      );
    }
    if (cleanInput.contains('non-skin') ||
        cleanInput.contains('non_skin') ||
        cleanInput.contains('invalid')) {
      return _terms.firstWhere((t) => t.technicalName == 'non_skin');
    }
    if (cleanInput.contains('healthy') ||
        cleanInput.contains('clear skin') ||
        cleanInput.contains('normal skin')) {
      return _terms.firstWhere(
        (t) => t.technicalName == 'Healthy Skin / No Active Lesion',
      );
    }
    if (cleanInput.contains('inconclusive')) {
      return _terms.firstWhere((t) => t.technicalName == 'Inconclusive Scan');
    }
    if (cleanInput.contains('keratosis')) {
      return _terms.firstWhere(
        (t) =>
            t.technicalName == 'Seborrheic Keratoses and other Benign Tumors',
      );
    }
    if (cleanInput.contains('melanoma')) {
      return _terms.firstWhere(
        (t) => t.technicalName == 'Melanoma Skin Cancer Nevi and Moles',
      );
    }
    if (cleanInput.contains('carcinoma') || cleanInput.contains('malignant')) {
      return _terms.firstWhere(
        (t) =>
            t.technicalName ==
            'Actinic Keratosis Basal Cell Carcinoma and other Malignant Lesions',
      );
    }
    if (cleanInput.contains('bullous') || cleanInput.contains('blister')) {
      return _terms.firstWhere(
        (t) => t.technicalName == 'Bullous Disease Photos',
      );
    }
    if (cleanInput.contains('vasculitis') || cleanInput.contains('purpura')) {
      return _terms.firstWhere(
        (t) => t.technicalName == 'Vasculitis Photos',
      );
    }
    if (cleanInput.contains('systemic')) {
      return _terms.firstWhere(
        (t) => t.technicalName == 'Systemic Disease',
      );
    }

    return LaymanTerm(
      technicalName: technicalName,
      friendlyNameEn: technicalName,
      friendlyNameUr: technicalName,
      benchmarkScientificName: technicalName,
      plainVernacularEn: technicalName,
      regionalUrduContext: technicalName,
      urgencyTagEn: 'Self-Care / Low Risk',
      urgencyTagUr: 'گھریلو دیکھ بھال / کم خطرہ',
      patientExplanationEn: '',
      patientExplanationUr: '',
    );
  }

  static ThreeTieredClinicalLabel getTaxonomy(String technicalName) {
    return mapToLayman(technicalName).threeTieredLabel;
  }

  static ThreeTieredClinicalLabel getThreeTieredLabel(String technicalName) {
    return getTaxonomy(technicalName);
  }

  static String getLaymanTitle(
    String technicalName, {
    required String languageCode,
  }) {
    final term = mapToLayman(technicalName);
    return languageCode == 'ur' ? term.friendlyNameUr : term.friendlyNameEn;
  }
}
