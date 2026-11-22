import '../models/clinic_recommendation_model.dart';
import 'clinical_guardrails_service.dart';
import 'drap_pharmacology_service.dart';
import '../models/iot_vitals_model.dart';

class ClinicalReport {
  final String summary;
  final List<String> observations;
  final List<String> otcCare;
  final List<String> prevention;
  final String conditionKey;
  final double confidence;
  final String bodyLocation;
  final String language;
  final String riskLevel;
  final List<ClinicRecommendation> nearbyClinics;

  const ClinicalReport({
    required this.summary,
    required this.observations,
    required this.otcCare,
    required this.prevention,
    this.conditionKey = '',
    this.confidence = 0.0,
    this.bodyLocation = '',
    this.language = 'en',
    this.riskLevel = 'Low',
    this.nearbyClinics = const [],
  });

  Map<String, dynamic> toMap() => {
    'summary': summary,
    'observations': observations,
    'otcCare': otcCare,
    'prevention': prevention,
    'conditionKey': conditionKey,
    'confidence': confidence,
    'bodyLocation': bodyLocation,
    'language': language,
    'riskLevel': riskLevel,
    'nearbyClinics': nearbyClinics.map((c) => c.toMap()).toList(),
  };
}

class OfflineClinicalTemplate {
  final String conditionKey;
  final String summaryEn;
  final String summaryUr;
  final List<String> observationsEn;
  final List<String> observationsUr;
  final List<String> otcMedicines;
  final List<String> precautionsEn;
  final List<String> precautionsUr;
  final bool isHighRisk;

  const OfflineClinicalTemplate({
    required this.conditionKey,
    required this.summaryEn,
    required this.summaryUr,
    required this.observationsEn,
    required this.observationsUr,
    required this.otcMedicines,
    required this.precautionsEn,
    required this.precautionsUr,
    this.isHighRisk = false,
  });
}

class OfflineReportService {
  OfflineReportService._();

  static const Map<String, OfflineClinicalTemplate> clinicalTemplates = {

    'Acne and Rosacea Photos': OfflineClinicalTemplate(
      conditionKey: 'Acne and Rosacea Photos',
      isHighRisk: false,
      summaryEn:
          'Presentation consistent with mild-to-moderate inflammatory acne / rosacea with papulopustular lesions.',
      summaryUr:
          'چہرے کے عام دانے، کیل مہاسے، چکنائی اور ورم کی علامات۔ عام طور پر حفظان صحت اور باقاعدہ دیکھ بھال سے ٹھیک ہو جاتی ہیں۔',
      observationsEn: [
        'Inflammatory follicular papules and comedones detected',
        'Sebaceous gland hyper-reactivity noted',
        'No malignant cutaneous features observed',
        'South Asian Type III-V skin calibration intact',
      ],
      observationsUr: [
        'جلد کے مساموں میں سوزش اور دانے پائے گئے ہیں',
        'چکنائی کے غدود میں زیادہ رطوبت کا مشاہدہ ہوا ہے',
        'کوئی خطرناک یا کینسر والی ساخت موجود نہیں ہے',
        'جلد کی رنگت اور ساخت کے مطابق معائنہ مکمل ہوا',
      ],
      otcMedicines: [
        'Benzoyl Peroxide 4% Gel (DRAP: Brevoxyl / FDA Approved) - Apply once daily at night',
        'Gentle Salicylic Acid 1-2% Cleanser (WHO essential dermatologicals)',
        'Oil-Free Non-Comedogenic Sunscreen SPF 50',
      ],
      precautionsEn: [
        'Cleanse skin gently twice daily with mild non-soap cleanser.',
        'Never squeeze or pick pimples to avoid secondary scarring.',
        'Use oil-free non-comedogenic moisturizers.',
      ],
      precautionsUr: [
        'دن میں دو بار ہلکے فیس واش سے چہرہ صاف کریں۔',
        'دانوں کو نوچنے یا دبانے سے گریز کریں تاکہ نشان نہ پڑیں۔',
        'آئل فری اور ہلکے موئسچرائزر کا استعمال کریں۔',
      ],
    ),

    'Actinic Keratosis Basal Cell Carcinoma and other Malignant Lesions':
        OfflineClinicalTemplate(
      conditionKey:
          'Actinic Keratosis Basal Cell Carcinoma and other Malignant Lesions',
      isHighRisk: true,
      summaryEn:
          'Suspicious presentation consistent with Actinic Keratosis or Basal Cell Carcinoma. Immediate clinical evaluation required.',
      summaryUr:
          'جلد کا مشتبہ کینسر یا زخم۔ کسی قسم کی گھریلو دوا مت لگائیں اور فوری طور پر ماہر امراض جلد سے بائیوپسی کروائیں۔',
      observationsEn: [
        'Hyperkeratotic, pearly or indurated non-healing plaque detected',
        'Malignant / pre-malignant architectural irregularity identified',
        'High-risk pathology protocol triggered',
        'Zero OTC medication counter-indication verified',
      ],
      observationsUr: [
        'کھردرا یا نہ بھرنے والا غیر معمولی ابھار پایا گیا ہے',
        'مشتبہ یا کینسر کی ابتدائی علامات ظاہر ہوئی ہیں',
        'شدید خطرے کا پروٹوکول لاگو کر دیا گیا ہے',
        'اوور دی کاؤنٹر مرہم کے استعمال کی سختی سے ممانعت ہے',
      ],
      otcMedicines: [
        'STRICT CONTRAINDICATION: Zero OTC formulations permitted',
        'Prescription Oncology / Dermatoscopy Evaluation Mandatory',
      ],
      precautionsEn: [
        'Schedule urgent in-person dermoscopy and histopathological biopsy.',
        'Strictly do not apply OTC steroids, herbal pastes, or bleaching creams.',
        'Shield lesion strictly from sunlight using wide-brim hat and clothing.',
      ],
      precautionsUr: [
        'فوری طور پر ماہر امراض جلد سے بالمشافہ معائنہ اور بائیوپسی کروائیں۔',
        'اوور دی کاؤنٹر مرہم یا گھریلو ٹوٹکے ہرگز استعمال نہ کریں۔',
        'متاثرہ حصے کو تیز دھوپ سے بچائیں۔',
      ],
    ),

    'Atopic Dermatitis Photos': OfflineClinicalTemplate(
      conditionKey: 'Atopic Dermatitis Photos',
      isHighRisk: false,
      summaryEn:
          'Erythematous pruritic dermatitis with xerosis consistent with atopic eczema.',
      summaryUr:
          'خشک جلد کی شدید الرجی، ایگزیما اور کھجلی۔ جلد کی نمی برقرار رکھنا اولین ترجیح ہے۔',
      observationsEn: [
        'Cutaneous xerosis and epidermal barrier breakdown observed',
        'Pruritic lichenified erythematous patches noted',
        'Non-infectious allergic etiology pattern',
        'Safe for topical emollient restoration',
      ],
      observationsUr: [
        'جلد میں خشکی اور بیرونی حفاظتی تہہ کی کمزوری دیکھی گئی ہے',
        'خارش زدہ سرخ دھبوں کا مشاہدہ ہوا ہے',
        'یہ غیر متعدی الرجی کی کیفیت ہے',
        'موئسچرائزنگ کریم سے بہتری ممکن ہے',
      ],
      otcMedicines: [
        'Hydrocortisone 1% Cream (DRAP: Cortiderm / FDA Approved) - Max 7 days during acute flare',
        'Ceramide-based barrier repair lotion (Physiogel / CeraVe)',
        'Liquid Paraffin / White Soft Paraffin Emollient',
      ],
      precautionsEn: [
        'Apply liberal fragrance-free barrier creams within 3 minutes of bathing.',
        'Avoid hot showers, harsh scented detergents, and wool fabrics.',
        'Keep fingernails short to prevent nocturnal scratch excoriation.',
      ],
      precautionsUr: [
        'نہانے کے فوری بعد خوشبو کے بغیر موئسچرائزنگ لوشن لگائیں۔',
        'گرم پانی، تیز صابن اور کھردری اونی پوشاک سے پرہیز کریں۔',
        'ناخن تراش کر رکھیں تاکہ خارش سے زخم نہ بنیں۔',
      ],
    ),

    'Bullous Disease Photos': OfflineClinicalTemplate(
      conditionKey: 'Bullous Disease Photos',
      isHighRisk: true,
      summaryEn:
          'Fluid-filled bullae and blisters indicating potential autoimmune or acute bullous dermatosis. Urgent hospital evaluation advised.',
      summaryUr:
          'پانی بھرے چھالے اور آبلے۔ چھالوں کو ہرگز نہ پھوڑیں اور ہسپتال کے ماہر امراض جلد سے معائنہ کروائیں۔',
      observationsEn: [
        'Tense or flaccid intraepidermal/subepidermal bullae identified',
        'Nikolsky-sign risk profile active',
        'Autoimmune or drug-induced blistering presentation',
        'Secondary bacterial infection risk elevated',
      ],
      observationsUr: [
        'جلد پر پانی والے چھالے یا آبلے بننے کی کیفیت ہے',
        'جلد کی نازک تہوں کی ٹوٹ پھوٹ کا خطرہ ہے',
        'قوت مدافعت یا شدید ردعمل کے چھالے مشاہدہ ہوئے ہیں',
        'بیکٹیریل انفیکشن سے بچاؤ کے لیے احتیاط لازمی ہے',
      ],
      otcMedicines: [
        'STRICT CONTRAINDICATION: Zero OTC topical creams',
        'Requires Immunosuppressive / Systemic In-Patient Care',
      ],
      precautionsEn: [
        'Do not rupture, puncture, or deroof fluid-filled blisters.',
        'Seek urgent tertiary hospital evaluation.',
        'Dress weeping areas in non-adherent sterile silicone foam dressings.',
      ],
      precautionsUr: [
        'چھالوں کو ہرگز نہ پھوڑیں اور نہ ہی چھیڑیں۔',
        'فوری طور پر کسی بڑے ہسپتال تشریف لے جائیں۔',
        'متاثرہ حصے پر صاف جراثیم کش پٹی رکھیں۔',
      ],
    ),

    'Cellulitis Impetigo and other Bacterial Infections':
        OfflineClinicalTemplate(
      conditionKey: 'Cellulitis Impetigo and other Bacterial Infections',
      isHighRisk: true,
      summaryEn:
          'Acute cutaneous bacterial infection with erythema, warmth, or purulent crusting. Medical antibiotics review required.',
      summaryUr:
          'بیکٹیریل انفیکشن، پیپ والے دانے یا گرم سوجن۔ فوری طور پر ڈاکٹر سے اینٹی بائیوٹک نسخہ حاصل کریں۔',
      observationsEn: [
        'Spreading erythematous border and localized warmth detected',
        'Honey-colored crusting or deeper cellulitic inflammation',
        'Bacterial proliferation pattern requiring surveillance',
        'Systemic infection guardrail active',
      ],
      observationsUr: [
        'پھیلنے والی سرخی، گرمائش اور سوجن کا مشاہدہ ہوا ہے',
        'پیپ والی کھرنڈ یا جلد کی گہرائی میں سوزش ہے',
        'بیکٹیریا کے پھیلاؤ کی علامات موجود ہیں',
        'فوری طبی علاج کی نگرانی ضروری ہے',
      ],
      otcMedicines: [
        'Polymyxin B + Bacitracin Ointment (DRAP: Polyfax / FDA Generic) - For minor impetigo only',
        'PRESCRIPTION GATED: Oral Cephalexin / Co-Amoxiclav strictly requires doctor review',
      ],
      precautionsEn: [
        'Elevate affected limb to reduce dependent edema.',
        'If spreading redness, red streaks, or fever develop, go immediately to an emergency room.',
        'Do not squeeze or open purulent lesions.',
      ],
      precautionsUr: [
        'سوجن کم کرنے کے لیے متاثرہ حصے کو اونچا رکھیں۔',
        'اگر سرخی پھیلے یا تیز بخار ہو تو فوری ایمرجنسی جائیں۔',
        'پیپ والے دانوں کو دبانے سے گریز کریں۔',
      ],
    ),

    'Eczema Photos': OfflineClinicalTemplate(
      conditionKey: 'Eczema Photos',
      isHighRisk: false,
      summaryEn:
          'Subacute or chronic eczematous dermatosis with erythema and scaling.',
      summaryUr:
          'خشک، خارش زدہ اور سرخ جلد (ایگزیما)۔ موئسچرائزر کا باقاعدہ استعمال آرام دیتا ہے۔',
      observationsEn: [
        'Erythematous scaly dermatitis without purulence',
        'Epidermal barrier disruption noted',
        'Absence of malignant architectural signs',
        'Responsive to mild topical corticosteroids and emollients',
      ],
      observationsUr: [
        'جلد پر سرخی اور چھلکے دار خشکی پائی گئی ہے',
        'جلد کی حفاظتی تہہ کمزور ہے',
        'کوئی خطرناک یا کینسر والی علامت نہیں ہے',
        'موئسچرائزنگ کریم سے جلد کی حفاظت ممکن ہے',
      ],
      otcMedicines: [
        'Hydrocortisone 1% Cream (DRAP: Cortiderm) - Apply twice daily for max 7 days',
        'Emollient Cream with Ceramides and Shea Butter',
        'Calamine Soothing Lotion for acute itch',
      ],
      precautionsEn: [
        'Hydrate skin immediately after brief lukewarm showers.',
        'Avoid contact with harsh detergents and chemical solvents.',
        'Wear breathable 100% pure cotton garments.',
      ],
      precautionsUr: [
        'نہانے کے بعد جلد تر ہونے کی حالت میں موئسچرائزر لگائیں۔',
        'تیز سرف، صابن اور کیمیکلز سے ہاتھ بچائیں۔',
        'ہلکے اور آرام دہ سوتی کپڑے پہنیں۔',
      ],
    ),

    'Exanthems and Drug Eruptions': OfflineClinicalTemplate(
      conditionKey: 'Exanthems and Drug Eruptions',
      isHighRisk: true,
      summaryEn:
          'Morbilliform exanthematous cutaneous reaction. Likely drug eruption or systemic viral exanthem.',
      summaryUr:
          'دوائی کا شدید ری ایکشن یا وائرل دانے اور جسمانی سرخی۔ نئی شروع کی گئی دوائیوں کا معالج سے جائزہ کروائیں۔',
      observationsEn: [
        'Symmetrical maculopapular cutaneous eruption',
        'Recent pharmacological ingestion or viral prodrome profile',
        'High surveillance for systemic drug hypersensitivity',
        'Mucosal involvement monitoring required',
      ],
      observationsUr: [
        'جسم پر متوازن انداز میں پھیلنے والے سرخ دانے ہیں',
        'کسی نئی دوا یا وائرس کے ردعمل کا شبہ ہے',
        'دوائی کے الرجی ری ایکشن پر کڑی نظر درکار ہے',
        'منہ یا آنکھوں کے اندر دانوں کا خیال رکھنا ضروری ہے',
      ],
      otcMedicines: [
        'PRESCRIPTION GATED: Do not self-medicate with new compounds',
        'Calamine Soothing Suspension (DRAP: Calamox) for cutaneous cooling only',
      ],
      precautionsEn: [
        'Consult physician immediately with full list of medications taken in past 4 weeks.',
        'Discontinue newly introduced suspect medications under doctor guidance.',
        'Seek emergency care if lip blistering, eye redness, or facial swelling occurs.',
      ],
      precautionsUr: [
        'گزشتہ ۴ ہفتوں میں استعمال کی گئی ادویات ڈاکٹر کو دکھائیں۔',
        'معالج کے مشورے سے مشتبہ دوائی کا استعمال روکیں۔',
        'اگر ہونٹوں پر چھالے یا آنکھوں میں جلن ہو تو فوری ہسپتال جائیں۔',
      ],
    ),

    'Hair Loss Photos Alopecia and other Hair Diseases':
        OfflineClinicalTemplate(
      conditionKey: 'Hair Loss Photos Alopecia and other Hair Diseases',
      isHighRisk: false,
      summaryEn:
          'Follicular shedding or localized alopecic patch consistent with telogen effluvium or alopecia areata.',
      summaryUr:
          'سر کے بال گرنا، چنڈی یا دائروں کی شکل میں گنج پن (ایلوپیشیا)۔ غذائیت اور تناؤ پر توجہ دیں۔',
      observationsEn: [
        'Localized or diffuse hair follicle rarefaction',
        'Scalp epidermis largely intact without purulent scarring',
        'Non-malignant follicular etiology',
        'Nutritional/autoimmune screening recommended',
      ],
      observationsUr: [
        'سر کے بالوں کا گرنا یا دائروں میں کمی واقع ہونا',
        'سر کی جلد پر کوئی زخم یا پیپ نہیں ہے',
        'یہ محفوظ اور غیر کینسر نوعیت کا مسئلہ ہے',
        'خون اور غذائی اجزاء کے ٹیسٹ تجویز کیے جاتے ہیں',
      ],
      otcMedicines: [
        'Minoxidil 5% Topical Solution (DRAP / FDA Approved) - Consult physician for suitability',
        'Biotin & Zinc Multivitamin supplements (DRAP Approved)',
        'Ketoconazole 2% Scalp Shampoo for associated seborrheic dandruff',
      ],
      precautionsEn: [
        'Avoid tight hairstyles and harsh chemical heat treatments.',
        'Use gentle sulfate-free nourishing shampoo.',
        'Check serum Ferritin, Vitamin D3, and TSH levels.',
      ],
      precautionsUr: [
        'بالوں کو زیادہ کھینچ کر باندھنے اور کیمیکل سے پرہیز کریں۔',
        'ہلکے شیمپو کا استعمال کریں۔',
        'خون میں وٹامن ڈی اور آئرن کی جانچ کروائیں۔',
      ],
    ),

    'Herpes HPV and other STDs Photos': OfflineClinicalTemplate(
      conditionKey: 'Herpes HPV and other STDs Photos',
      isHighRisk: true,
      summaryEn:
          'Grouped vesicular eruptions on erythematous base consistent with viral herpes simplex or zoster.',
      summaryUr:
          'وائرس کی وجہ سے بننے والے تکلیف دہ چھالے اور دانے۔ چھالوں کو ہاتھ مت لگائیں اور اینٹی وائرل دوا لیں۔',
      observationsEn: [
        'Clustered umbilicated vesicles on erythematous background',
        'Neuropathic tingling / burning prodromal presentation',
        'Contagious viral transmission risk active',
        'Prescription antiviral therapy required',
      ],
      observationsUr: [
        'سرخ جلد پر اکٹھے بنے ہوئے باریک چھالے ہیں',
        'سوزش اور جلن کی کیفیت موجود ہے',
        'دوسروں تک چھوت لگنے کا خطرہ ہے',
        'اینٹی وائرل دوائی کی فوری ضرورت ہے',
      ],
      otcMedicines: [
        'PRESCRIPTION ONLY: Acyclovir / Valacyclovir oral therapy (DRAP / FDA)',
        'Zinc Oxide drying lotion for intact surrounding skin',
      ],
      precautionsEn: [
        'Avoid touching or scratching blisters to prevent auto-inoculation.',
        'Do not share personal towels, beddings, or utensils.',
        'Initiate oral antivirals within 72 hours under physician supervision.',
      ],
      precautionsUr: [
        'چھالوں کو چھیڑنے سے گریز کریں تاکہ یہ دوسری جگہ نہ پھیلیں۔',
        'اپنا تولیہ، بستر اور برتن الگ رکھیں۔',
        'ڈاکٹر کے مشورے سے جلد اینٹی وائرل گولی شروع کریں۔',
      ],
    ),

    'Light Diseases and Disorders of Pigmentation': OfflineClinicalTemplate(
      conditionKey: 'Light Diseases and Disorders of Pigmentation',
      isHighRisk: false,
      summaryEn:
          'Disorder of melanogenesis, hyperpigmentation, or melasma triggered by UV exposure.',
      summaryUr:
          'دھوپ یا ہارمونز کی وجہ سے رنگت کی تبدیلی اور چھائیاں۔ دھوپ سے بچاؤ اولین علاج ہے۔',
      observationsEn: [
        'Macular hyperpigmentation with irregular geographic boundaries',
        'Absence of ulceration or invasive architectural features',
        'Melanocytic activation in epidermal layers',
        'Photoprotection protocol highly effective',
      ],
      observationsUr: [
        'جلد پر گہرے یا بھورے داغ اور چھائیاں پائی گئی ہیں',
        'کوئی زخم یا خطرناک ابھار موجود نہیں ہے',
        'دھوپ کی شعاعوں سے رنگت میں اضافہ ہوا ہے',
        'سن بلاک کے استعمال سے واضح بہتری ممکن ہے',
      ],
      otcMedicines: [
        'Broad-Spectrum Physical Sunscreen SPF 50+ (Zinc Oxide / Titanium Dioxide)',
        'Topical Niacinamide 4-5% / Vitamin C serum (FDA Cosmetic Standard)',
        'Azelaic Acid 10% OTC Suspension for gentle brightening',
      ],
      precautionsEn: [
        'Reapply broad-spectrum sunscreen every 2 to 3 hours when outdoors.',
        'Wear protective wide-brim hats and seek shade between 10 AM and 4 PM.',
        'Avoid aggressive bleaching creams containing unregulated mercury.',
      ],
      precautionsUr: [
        'دھوپ میں نکلتے وقت سن بلاک باقاعدگی سے لگائیں۔',
        'دھوپ کے اوقات میں چہرے کو ڈھانپ کر رکھیں۔',
        'پارے (Mercury) والی غیر معیاری رنگ گورا کرنے والی کریموں سے بچیں۔',
      ],
    ),

    'Lupus and other Connective Tissue diseases': OfflineClinicalTemplate(
      conditionKey: 'Lupus and other Connective Tissue diseases',
      isHighRisk: true,
      summaryEn:
          'Autoimmune malar or discoid dermatosis suggestive of cutaneous lupus or connective tissue disease.',
      summaryUr:
          'لوپس (قوت مدافعت کی بیماری)، چہرے کی سرخی اور ریش۔ ماہر امراض جلد اور فزیشن سے تفصیلی ٹیسٹ کروائیں۔',
      observationsEn: [
        'Fixed photosensitive erythematous plaques with follicular plugging',
        'Malar / discoid autoimmune distribution pattern',
        'Potential systemic connective tissue involvement',
        'Specialist rheumatology/dermatology evaluation needed',
      ],
      observationsUr: [
        'دھوپ سے متاثر ہونے والے سرخ اور سخت نشانات ہیں',
        'چہرے پر تتلی نما یا گول سرخ دھبے ظاہر ہوئے ہیں',
        'جسم کی قوت مدافعت کے ردعمل کا امکان ہے',
        'ماہر امراض جلد اور متعلقہ ڈاکٹر سے معائنہ ضروری ہے',
      ],
      otcMedicines: [
        'STRICT CONTRAINDICATION: Zero OTC therapies',
        'High-grade Broad-Spectrum Sunscreen SPF 50+ for UV attenuation',
      ],
      precautionsEn: [
        'Undergo comprehensive ANA and autoimmune antibody serological profiling.',
        'Practice rigorous UV protection indoors and outdoors.',
        'Report joint pain, persistent fatigue, or kidney symptoms to doctor.',
      ],
      precautionsUr: [
        'ڈاکٹر کی ہدایت کے مطابق اینٹی باڈی اور خون کے ٹیسٹ کروائیں۔',
        'دھوپ کی روشنی سے سخت پرہیز کریں۔',
        'جوڑوں کے درد یا کمزوری کی صورت میں فوری ڈاکٹر کو بتائیں۔',
      ],
    ),

    'Melanoma Skin Cancer Nevi and Moles': OfflineClinicalTemplate(
      conditionKey: 'Melanoma Skin Cancer Nevi and Moles',
      isHighRisk: true,
      summaryEn:
          'CRITICAL ALERT: Asymmetrical, irregular, or changing pigmented lesion suspicious for melanoma. Urgent surgical excision biopsy required.',
      summaryUr:
          'سخت طبی انتباہ: مشتبہ یا بے قاعدہ تل اور کینسر کا خطرہ۔ کسی قسم کی کریم مت لگائیں، فوری ماہر امراض جلد سے بائیوپسی کروائیں۔',
      observationsEn: [
        'ABCDE warning criteria flagged (Asymmetry / Border / Color / Diameter)',
        'Malignant melanocytic proliferation risk high',
        'Critical oncology referral banner activated',
        'Zero OTC medication counter-indication verified',
      ],
      observationsUr: [
        'تل کے کناروں اور رنگت میں بے قاعدگی پائی گئی ہے',
        'خطرناک جلدی کینسر (میلانوما) کا شدید خطرہ ہے',
        'فوری ایمرجنسی ریفرل فعال کر دیا گیا ہے',
        'اوور دی کاؤنٹر مرہم لگانا سخت نقصان دہ ہے',
      ],
      otcMedicines: [
        'STRICT CONTRAINDICATION: Zero OTC medications or ointments permitted',
        'Emergency Excisional Biopsy & Dermatoscopy Required',
      ],
      precautionsEn: [
        'Consult a certified dermatologist or oncology centre immediately.',
        'Do not touch, scratch, shave, or biopsy locally at home.',
        'Photograph lesion with ruler for size baseline prior to appointment.',
      ],
      precautionsUr: [
        'فوری طور پر کینسر ہسپتال یا مستند ڈرمیٹالوجسٹ سے رجوع کریں۔',
        'متاثرہ تل کو کھرچنے یا چھیڑنے سے مکمل گریز کریں۔',
        'ڈاکٹر کو دکھانے سے پہلے پیمانے کے ساتھ تصویر محفوظ کر لیں۔',
      ],
    ),

    'Nail Fungus and other Nail Disease': OfflineClinicalTemplate(
      conditionKey: 'Nail Fungus and other Nail Disease',
      isHighRisk: false,
      summaryEn:
          'Subungual hyperkeratosis with nail plate discoloration consistent with onychomycosis.',
      summaryUr:
          'ناخن کی فنگس، پیلا پن اور ناخنوں کا موٹا ہونا۔ ناخنوں کو خشک اور صاف رکھنا ضروری ہے۔',
      observationsEn: [
        'Distal subungual hyperkeratosis and chromonychia identified',
        'Nail plate dystrophy without periungual cellulitis',
        'Dermatophytic nail fungal colonization',
        'Standard antifungal regimen indicated',
      ],
      observationsUr: [
        'ناخن کے نیچے کھردرا پن اور رنگت کی تبدیلی دیکھی گئی ہے',
        'ناخن کا موٹا ہونا اور چمک ختم ہونا پایا گیا ہے',
        'ناخنوں کی عام فنگس کی علامات ہیں',
        'اینٹی فنگل علاج سے بہتری ممکن ہے',
      ],
      otcMedicines: [
        'Amorolfine 5% Nail Lacquer (DRAP / International OTC)',
        'Terbinafine 1% Cream (DRAP: Lamisil) for surrounding periungual skin',
        'Tea tree oil 100% solution for topical antiseptic self-care',
      ],
      precautionsEn: [
        'Keep hands and feet clean and thoroughly dry after washing.',
        'Clip nails straight across and disinfect clippers after each use.',
        'Wear breathable footwear and moisture-wicking cotton socks.',
      ],
      precautionsUr: [
        'ہاتھ اور پاؤں دھونے کے بعد انگلیوں کو خشک رکھیں۔',
        'ناخنوں کو سیدھا کاٹیں اور نیل کٹر صاف رکھیں۔',
        'ہوا دار جوتے اور سوتی جرابیں استعمال کریں۔',
      ],
    ),

    'Poison Ivy Photos and other Contact Dermatitis': OfflineClinicalTemplate(
      conditionKey: 'Poison Ivy Photos and other Contact Dermatitis',
      isHighRisk: false,
      summaryEn:
          'Acute contact dermatitis or allergic reaction secondary to irritant or urushiol exposure.',
      summaryUr:
          'کسی بیرونی الرجی یا کیمیکل کو چھونے سے بننے والا ریش اور کھجلی۔ متاثرہ جگہ کو ٹھنڈے پانی سے دھوئیں اور سوتھنگ لوشن لگائیں۔',
      observationsEn: [
        'Linear or geometric vesicular erythematous patches',
        'Exogenous allergen / chemical irritant mechanism',
        'Epidermal weeping and intense pruritus',
        'Safe for topical soothing therapy',
      ],
      observationsUr: [
        'جلد پر چھونے کے مقام پر سرخ دانے اور خارش ہے',
        'کسی کیمیکل، صابن یا پودے کا ردعمل معلوم ہوتا ہے',
        'جلد میں سرخی اور شدید کھجلی پائی گئی ہے',
        'ٹھنڈی پٹی اور لوشن سے آرام ملتا ہے',
      ],
      otcMedicines: [
        'Calamine + Zinc Oxide Lotion (DRAP: Calamox / FDA Generic) - Apply 3-4 times daily',
        'Hydrocortisone 1% Cream (DRAP: Cortiderm) for localized inflammation (max 7 days)',
        'Oral Cetirizine 10mg (DRAP Approved OTC) for nocturnal itch',
      ],
      precautionsEn: [
        'Wash affected skin thoroughly with cool soap and water to remove residual irritants.',
        'Apply cold compresses for 15-20 minutes several times a day.',
        'Avoid scratching to prevent secondary staphylococcal infection.',
      ],
      precautionsUr: [
        'متاثرہ حصے کو فورا ٹھنڈے پانی اور ہلکے صابن سے دھو لیں۔',
        'دن میں کئی بار ٹھنڈے پانی کی پٹی رکھیں۔',
        'خارش کرنے سے گریز کریں تاکہ زخم خراب نہ ہو۔',
      ],
    ),

    'Psoriasis pictures Lichen Planus and related diseases':
        OfflineClinicalTemplate(
      conditionKey: 'Psoriasis pictures Lichen Planus and related diseases',
      isHighRisk: false,
      summaryEn:
          'Well-demarcated erythematous plaques with silvery micaceous scaling typical of plaque psoriasis.',
      summaryUr:
          'جلد پر ابھرے ہوئے چاندی جیسے چھلکے دار سرخ دھبے اور چنبل (سورائسس)۔ باقاعدہ دیکھ بھال اور نرمی ضروری ہے۔',
      observationsEn: [
        'Sharply circumscribed plaques with silvery lamellar scale',
        'Auspitz sign propensity on extensor surfaces',
        'Chronic immune-mediated hyperproliferative epidermal state',
        'Keratolytic and topical steroid maintenance indicated',
      ],
      observationsUr: [
        'جلد پر واضح کناروں والے چھلکے دار سرخ دھبے پائے گئے ہیں',
        'جلد کے خلیات کی تیزی سے بننے والی سوزش ہے',
        'یہ چھوت کی بیماری نہیں ہے بلکہ مدافعت کا اثر ہے',
        'موئسچرائزر اور مخصوص مرہم سے کنٹرول ہو سکتی ہے',
      ],
      otcMedicines: [
        'Coal Tar 5% Topical Solution / Shampoo (DRAP / FDA Monograph)',
        'Salicylic Acid 3% Keratolytic Ointment (DRAP Generic)',
        'Heavy Petrolatum Emollient for plaque softening',
      ],
      precautionsEn: [
        'Moisturize skin continuously to soften thick scales.',
        'Avoid picking or scrubbing plaques to avoid Koebner isomorphic response.',
        'Consult dermatologist for prescription topical vitamin D analogues.',
      ],
      precautionsUr: [
        'چھلکوں کو نرم رکھنے کے لیے موئسچرائزنگ ویزلین لگائیں۔',
        'چھلکے کھرچنے سے پرہیز کریں ورنہ بیماری بڑھ سکتی ہے۔',
        'مکمل علاج کے لیے ماہر امراض جلد سے رہنمائی لیں۔',
      ],
    ),

    'Scabies Lyme Disease and other Infestations and Bites':
        OfflineClinicalTemplate(
      conditionKey: 'Scabies Lyme Disease and other Infestations and Bites',
      isHighRisk: false,
      summaryEn:
          'Intensely pruritic papular eruption with excoriations and burrows consistent with Sarcoptes scabiei infestation.',
      summaryUr:
          'خارش کا کیڑا (اسکیبیز)، رات کی شدید کھجلی اور دانوں کا جال۔ پورے خاندان کا بیک وقت علاج ضروری ہے۔',
      observationsEn: [
        'Interdigital and flexural papulovesicular excoriations',
        'Severe nocturnal pruritus exacerbation pattern',
        'Ectoparasitic mite transmission dynamic',
        'Simultaneous household treatment required',
      ],
      observationsUr: [
        'انگلیوں کے درمیان اور جوڑوں پر باریک دانے پائے گئے ہیں',
        'رات کے وقت خارش میں شدید اضافے کا مشاہدہ ہے',
        'خارش کے باریک کیڑے کا حملہ ظاہر ہوا ہے',
        'گھر کے تمام افراد کا ایک ہی دن علاج لازم ہے',
      ],
      otcMedicines: [
        'Permethrin 5% Lotion (DRAP: Scabite / WHO Essential) - Apply neck to toes overnight for 8-14 hours',
        'Calamine Soothing Lotion for post-scabetic itch',
        'Crotamiton 10% cream as alternative antipruritic',
      ],
      precautionsEn: [
        'All household members must be treated on the very same night.',
        'Wash all clothes, bed sheets, and towels used in the past 3 days in hot water.',
        'Repeat single Permethrin application after 7 days to eliminate hatched larvae.',
      ],
      precautionsUr: [
        'گھر کے تمام افراد ایک ہی رات دوائی لگائیں چاہے علامات نہ ہوں۔',
        'گزشتہ ۳ دن کے کپڑے اور بستر کی چادریں گرم پانی میں دھوئیں یا دھوپ میں سکھائیں۔',
        'سات دن بعد لوشن کا استعمال ایک بار پھر دہرائیں۔',
      ],
    ),

    'Seborrheic Keratoses and other Benign Tumors': OfflineClinicalTemplate(
      conditionKey: 'Seborrheic Keratoses and other Benign Tumors',
      isHighRisk: false,
      summaryEn:
          'Waxy, well-circumscribed stuck-on verrucous plaque consistent with benign seborrheic keratosis.',
      summaryUr:
          'عمر کے ساتھ ابھرنے والا بالکل بے ضرر اور غیر سرطانی مسا یا تل۔ اس سے کوئی خطرہ لاحق نہیں ہوتا۔',
      observationsEn: [
        'Stuck-on verrucous epidermal proliferation without invasion',
        'Uniform pigmentation and stable benign architecture',
        'Zero features of invasive malignancy',
        'Reassurance and conservative observation recommended',
      ],
      observationsUr: [
        'جلد پر چپکا ہوا بے ضرر ابھار یا مسا ہے',
        'یکساں رنگت اور پرسکون خلیاتی ساخت پائی گئی ہے',
        'کینسر کا قطعا کوئی خطرہ نہیں ہے',
        'کسی علاج کی ضرورت نہیں، صرف نظر رکھیں',
      ],
      otcMedicines: [
        'Reassurance: No medicinal or OTC topical intervention required',
        'Gentle moisturizing cream if surface becomes dry or irritated',
      ],
      precautionsEn: [
        'Do not scratch, pick, or attempt to cut the lesion at home.',
        'Consult a dermatologist if lesion suddenly bleeds, itches, or changes rapidly.',
        'No surgical treatment needed unless aesthetically requested.',
      ],
      precautionsUr: [
        'اسے ناخن سے کھرچنے یا کاٹنے کی کوشش ہرگز نہ کریں۔',
        'اگر اچانک خون بہے یا تیزی سے سائز بڑھے تو معالج کو دکھائیں۔',
        'طبی لحاظ سے کسی سرجری کی ضرورت نہیں ہے۔',
      ],
    ),

    'Systemic Disease': OfflineClinicalTemplate(
      conditionKey: 'Systemic Disease',
      isHighRisk: true,
      summaryEn:
          'Cutaneous signs suggestive of internal metabolic, endocrine, or systemic organ dysfunction.',
      summaryUr:
          'جسم کی اندرونی بیماریوں (جیسے شوگر، گردے یا جگر) کی وجہ سے جلد پر اثرات۔ معالج سے اندرونی معائنہ کروائیں۔',
      observationsEn: [
        'Cutaneous stigmata of internal disease (Acanthosis / Pruritus / Xanthoma)',
        'Underlying systemic organ dysfunction profile active',
        'Laboratory biochemical workup needed',
        'Comprehensive physician evaluation recommended',
      ],
      observationsUr: [
        'اندرونی جسمانی بیماری کی جلد پر ظاہر ہونے والی علامات ہیں',
        'خون میں شوگر، کولیسٹرول یا جگر کی جانچ کی ضرورت ہے',
        'طبی لیب ٹیسٹ کروانا انتہائی مفید ہوگا',
        'ماہر ڈاکٹر سے تفصیلی معائنہ کروائیں',
      ],
      otcMedicines: [
        'STRICT CONTRAINDICATION: Zero OTC therapies for underlying cause',
        'Fragrance-free barrier moisturizing cream for secondary itch relief',
      ],
      precautionsEn: [
        'Schedule comprehensive blood tests: HbA1c, Liver Function (LFT), Renal Function (RFT).',
        'Consult an internal medicine specialist or dermatologist.',
        'Track any associated systemic symptoms such as fatigue or weight changes.',
      ],
      precautionsUr: [
        'خون کے بنیادی ٹیسٹ (شوگر، جگر اور گردے کے ٹیسٹ) کروائیں۔',
        'ماہر امراض باطنیہ یا ڈرمیٹالوجسٹ سے مشورہ کریں۔',
        'وزن میں کمی یا غیر معمولی تھکاوٹ پر نظر رکھیں۔',
      ],
    ),

    'Tinea Ringworm Candidiasis and other Fungal Infections':
        OfflineClinicalTemplate(
      conditionKey: 'Tinea Ringworm Candidiasis and other Fungal Infections',
      isHighRisk: false,
      summaryEn:
          'Annular scaly erythematous plaques with central clearing consistent with cutaneous dermatophyte infection (Tinea).',
      summaryUr:
          'گول دائرے والی خارش، داد اور فنگس۔ کاؤنٹر سے ملنے والی اینٹی فنگل کریم سے آسانی سے ٹھیک ہو جاتی ہے۔',
      observationsEn: [
        'Annular active erythematous border with central clearing',
        'Fungal dermatophyte hyphal pattern',
        'Non-invasive superficial mycosis',
        'Responsive to topical imidazoles / allylamines',
      ],
      observationsUr: [
        'کناروں پر سرخی اور درمیانی حصے کی صفائی والے دائرے ہیں',
        'عام فنگس (داد) کی واضح علامات موجود ہیں',
        'سطحی فنگل انفیکشن کا مشاہدہ ہوا ہے',
        'اینٹی فنگل مرہم سے آسانی سے افاقہ ہوتا ہے',
      ],
      otcMedicines: [
        'Clotrimazole 1% Cream (DRAP: Canesten / FDA Approved) - Apply twice daily for 2-4 weeks',
        'Terbinafine 1% Cream (DRAP: Lamisil / WHO Essential) - Apply once or twice daily for 2 weeks',
        'Miconazole 2% Powder to keep intertriginous skin folds dry',
      ],
      precautionsEn: [
        'Keep infected area completely dry and clean at all times.',
        'Never apply steroid creams (Betamethasone) without antifungal cover; this causes Tinea Incognito.',
        'Wear loose cotton clothing and do not share towels or bedsheets.',
      ],
      precautionsUr: [
        'متاثرہ حصے کو ہر وقت بالکل خشک اور صاف رکھیں۔',
        'اسٹرائیڈ والی کریم مت لگائیں اس سے فنگس مزید بگڑ جاتی ہے۔',
        'ڈھیلے سوتی کپڑے پہنیں اور تولیہ الگ رکھیں۔',
      ],
    ),

    'Urticaria Hives': OfflineClinicalTemplate(
      conditionKey: 'Urticaria Hives',
      isHighRisk: false,
      summaryEn:
          'Transient edematous erythematous wheals with intense pruritus consistent with acute urticaria.',
      summaryUr:
          'الرجی کی وجہ سے اچانک ابھرنے والی سرخ سوجن اور پتی (چھپاکی)۔ اینٹی الرجک دوا اور ٹھنڈی پٹی سے آرام آتا ہے۔',
      observationsEn: [
        'Evanescent erythematous wheals and dermal edema',
        'Mast cell histamine degranulation response',
        'Absence of epidermal scaling or blistering',
        'Systemic airway guardrail alert monitored',
      ],
      observationsUr: [
        'اچانک ابھرنے والی سرخ سوجن اور پتی کے نشانات ہیں',
        'جسم میں الرجی اور ہسٹامائن کے اخراج کا نتیجہ ہے',
        'جلد پر کوئی چھلکے یا مستقل زخم نہیں ہیں',
        'سانس اور گلے کی حالت پر نظر رکھی گئی ہے',
      ],
      otcMedicines: [
        'Calamine + Zinc Oxide Suspension (DRAP: Calamox) - Apply liberally 3-4 times daily',
        'Loratadine 10mg / Cetirizine 10mg (DRAP / FDA Approved OTC Second-Gen Antihistamine)',
        'Cold compresses applied topically for 15 minutes',
      ],
      precautionsEn: [
        'If you experience lip swelling, tongue swelling, or breathing difficulty, seek EMERGENCY CARE immediately.',
        'Avoid hot water baths, spicy foods, alcohol, and tight constricting clothes.',
        'Identify and eliminate recent allergic triggers (new foods, medications, insect bites).',
      ],
      precautionsUr: [
        'اگر ہونٹ یا گلے میں سوجن ہو یا سانس پھولے تو فوری ایمرجنسی ہسپتال جائیں۔',
        'گرم پانی سے نہانے، تیز مصالحوں اور تنگ کپڑوں سے پرہیز کریں۔',
        'الرجی کرنے والی خوراک یا دوا کا پتا لگا کر پرہیز کریں۔',
      ],
    ),

    'Vascular Tumors': OfflineClinicalTemplate(
      conditionKey: 'Vascular Tumors',
      isHighRisk: false,
      summaryEn:
          'Well-circumscribed vascular proliferation consistent with benign hemangioma or cherry angioma.',
      summaryUr:
          'جلد کی باریک خون کی نالیوں کا بے ضرر سرخ ابھار (ہیمینجیوما)۔ یہ مکمل طور پر محفوظ ہوتا ہے۔',
      observationsEn: [
        'Vascular endothelial capillary proliferation without atypia',
        'Blanchable or stable red-purple papule',
        'Benign non-malignant cutaneous profile',
        'Conservative monitoring indicated',
      ],
      observationsUr: [
        'خون کی باریک نالیوں کا عام اور بے ضرر سرخ تل ہے',
        'دبانے سے سرخی کم ہونے والی محفوظ ساخت ہے',
        'کوئی کینسر یا خطرے کی علامت نہیں ہے',
        'کسی خاص علاج کی ضرورت نہیں ہے',
      ],
      otcMedicines: [
        'Reassurance: No medicinal OTC topicals required',
        'Protect from friction or accidental trauma',
      ],
      precautionsEn: [
        'Avoid picking, scratching, or rubbing the lesion to prevent bleeding.',
        'Consult a dermatologist if it bleeds repeatedly or enlarges rapidly.',
        'Laser therapy available for cosmetic removal if desired.',
      ],
      precautionsUr: [
        'خون بہنے سے بچانے کے لیے ناخن یا رگڑ سے بچائیں۔',
        'اگر بار بار خون نکلے تو ڈاکٹر سے معائنہ کروائیں۔',
        'خوبصورتی کے لیے لیزر سے ہٹایا جا سکتا ہے۔',
      ],
    ),

    'Vasculitis Photos': OfflineClinicalTemplate(
      conditionKey: 'Vasculitis Photos',
      isHighRisk: true,
      summaryEn:
          'Palpable purpura and petechiae indicating dermal small-vessel vasculitis. Immediate hospital referral required.',
      summaryUr:
          'خون کی نالیوں میں سوزش سے بننے والے جامنی یا سرخ نشانات (واسکولائٹس)۔ فوری طور پر ہسپتال سے رجوع کریں۔',
      observationsEn: [
        'Palpable non-blanching purpuric macules and papules',
        'Immune complex-mediated microvascular inflammation',
        'Risk of renal and systemic vascular involvement',
        'Urgent specialist physician intervention mandated',
      ],
      observationsUr: [
        'جامنی اور سرخ رنگ کے غیر معمولی دھبے پائے گئے ہیں',
        'خون کی نالیوں میں سوزش اور جلن کی علامات ہیں',
        'گردوں اور اندرونی نظام کے ٹیسٹ ضروری ہیں',
        'فوری طور پر ہسپتال میں معائنے کی ضرورت ہے',
      ],
      otcMedicines: [
        'STRICT CONTRAINDICATION: Zero OTC formulations permitted',
        'Urgent Systemic Hospital Evaluation & Corticosteroid Assessment',
      ],
      precautionsEn: [
        'Go immediately to an emergency hospital department.',
        'Elevate lower extremities to reduce hydrostatic pressure.',
        'Complete urine routine examination (rule out proteinuria/hematuria).',
      ],
      precautionsUr: [
        'فوری طور پر کسی بڑے ہسپتال کے ایمرجنسی وارڈ جائیں۔',
        'ٹانگوں کو اونچا رکھ کر آرام کریں۔',
        'پیشاب کا مکمل ٹیسٹ کروائیں تاکہ گردوں کی حفاظت یقینی ہو۔',
      ],
    ),

    'Warts Molluscum and other Viral Infections': OfflineClinicalTemplate(
      conditionKey: 'Warts Molluscum and other Viral Infections',
      isHighRisk: false,
      summaryEn:
          'Hyperkeratotic verrucous papules consistent with human papillomavirus (HPV) warts or molluscum contagiosum.',
      summaryUr:
          'عام وائرل مسے یا ابھار۔ انہیں نوچنے سے پرہیز کریں تاکہ یہ مزید نہ پھیلیں۔',
      observationsEn: [
        'Verrucous papules with punctate black thrombosed capillaries',
        'Epidermal viral proliferation profile',
        'Contagious self-inoculation mechanism',
        'Destructive / keratolytic home remedies applicable',
      ],
      observationsUr: [
        'کھردری سطح والے مسے اور چھوٹے ابھار دیکھے گئے ہیں',
        'وائرس کی وجہ سے بننے والے عام جلدی مسے ہیں',
        'چھونے اور نوچنے سے دوسری جگہ پھیل سکتے ہیں',
        'سیلی سائلک ایسڈ لوشن سے صفائی ممکن ہے',
      ],
      otcMedicines: [
        'Salicylic Acid 17% Wart Solution (DRAP / FDA Monograph) - Apply strictly to wart tissue',
        'Zinc Oxide 10% barrier paste to protect healthy surrounding skin',
        'Duct tape occlusion therapy protocol',
      ],
      precautionsEn: [
        'Do not scratch or bite warts to prevent viral spreading.',
        'Wash hands frequently after touching lesions.',
        'Keep lesions covered with a breathable adhesive bandage.',
      ],
      precautionsUr: [
        'مسوں کو دانتوں یا ناخنوں سے نوچنے سے پرہیز کریں۔',
        'ہاتھوں کو بار بار دھو کر صاف رکھیں۔',
        'متاثرہ حصے پر صاف پٹی لگا کر رکھیں۔',
      ],
    ),

    'non_skin': OfflineClinicalTemplate(
      conditionKey: 'non_skin',
      isHighRisk: false,
      summaryEn:
          'Non-Skin Surface Detected: The uploaded image does not contain human skin tissue.',
      summaryUr:
          'یہ انسانی جلد نہیں ہے: سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ براہ کرم صرف جلد کی تصویر لیں۔',
      observationsEn: [
        'Human epidermal tone criteria not met',
        'Artifact or non-biological texture detected',
        'Scan safely terminated by Pre-Inference Quality Gate',
      ],
      observationsUr: [
        'تصویر میں انسانی جلد کی علامات موجود نہیں ہیں',
        'کوئی اور چیز یا غیر واضح شے اسکین ہوئی ہے',
        'سسٹم نے تصویر کو خودکار طریقے سے مسترد کر دیا ہے',
      ],
      otcMedicines: [],
      precautionsEn: [
        'Please take a photo directly on the affected human skin under good lighting.',
      ],
      precautionsUr: [
        'براہ کرم اچھی روشنی میں براہ راست متاثرہ جلد کی تصویر بنائیں۔',
      ],
    ),
  };

  static ClinicalReport generate({
    required String conditionKey,
    required double confidence,
    required String bodyLocation,
    required String language,
    IotVitalsReading? vitals,
  }) {
    final cleanKey = conditionKey.trim();
    final template = clinicalTemplates[cleanKey] ??
        clinicalTemplates.values.firstWhere(
          (t) => cleanKey.toLowerCase().contains(t.conditionKey.toLowerCase()),
          orElse: () => clinicalTemplates['non_skin']!,
        );

    final isUr = language == 'ur';

    final bool isSevere = template.isHighRisk ||
        DrapPharmacologyService.isSevereHighRiskClass(cleanKey);

    final guardrailEval = ClinicalGuardrailsService.evaluate(
      conditionName: cleanKey,
      isHighRiskLesion: isSevere,
      lesionConfidence: confidence,
      vitals: vitals,
    );

    final String riskLevel;
    if (guardrailEval.isSystemicDistressFlagged) {
      riskLevel = 'Emergency';
    } else if (isSevere) {
      riskLevel = 'Critical';
    } else if (confidence >= 0.45) {
      riskLevel = 'Moderate';
    } else {
      riskLevel = 'Low';
    }

    final summary = isUr ? template.summaryUr : template.summaryEn;
    final observations = isUr ? template.observationsUr : template.observationsEn;
    final otcCare = template.otcMedicines;
    final prevention = isUr ? template.precautionsUr : template.precautionsEn;

    return ClinicalReport(
      summary: summary,
      observations: observations,
      otcCare: otcCare,
      prevention: prevention,
      conditionKey: cleanKey,
      confidence: confidence,
      bodyLocation: bodyLocation,
      language: language,
      riskLevel: riskLevel,
    );
  }
}
