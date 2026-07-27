import 'ai_prompt_strategy.dart';

/// Agricultural mode AI prompt strategy.
///
/// Focus: Irrigation suitability and crop health.
/// Standards: FAO irrigation water quality guidelines.
/// Expected output: 4 detail points covering sensor analysis,
/// visual verification, crop suitability, and soil management.
class AgriculturalPromptStrategy implements AiPromptStrategy {
  @override
  String get label => 'Agricultural';

  @override
  String buildPrompt({
    required double tds,
    required double purity,
    required double temperature,
    required double? ph,
    required bool hasImage,
    String? saltTrendLabel,
    double? avgTds7Days,
    bool? needsLeaching,
    String? leachingMessage,
    String? leachingAdvice,
  }) {
    // الصورة هنا (لو موجودة) بتبقى ورقة/نبات، مش المياه نفسها — الملوحة مش
    // مرئية في المياه، لكن أعراضها بتظهر على النبات (اصفرار، احتراق أطراف الورق).
    final String visualInstruction = hasImage
        ? """
A photo of a plant leaf is attached. Examine it for visible salt-stress symptoms:
leaf tip or margin burn (necrosis), yellowing between veins (chlorosis), or stunted/wilted growth.
Cross-check whatever you observe against the TDS/salinity reading — e.g., visible burn despite
a "safe" TDS reading may indicate cumulative soil salinity not captured by a single reading."""
        : """
No image was provided for this analysis. Base your assessment entirely on the sensor
readings and the FAO thresholds below — do not reference or assume any visual information.""";

    // ─── Historical Salt Trend context ───
    // بيوصل من FarmProfile.calculateSaltTrend() قبل نداء الـ AI. لو مفيش
    // بيانات كفاية (أقل من 3 قراءات) بيبقى null، فمنضيفش السطر ده خالص
    // بدل ما نضلل الموديل بمعلومة ناقصة.
    final String historicalContext = saltTrendLabel != null
        ? """

7-Day Historical Salt Trend:
- Trend: $saltTrendLabel
- 7-day average TDS: ${avgTds7Days != null ? '${avgTds7Days.toStringAsFixed(0)} PPM' : 'N/A'}
Use this trend alongside the current reading — a single "acceptable" reading can still sit inside a
rising or critical trend, which matters more for cumulative soil salinity than the snapshot alone."""
        : "";

    // ─── Leaching Recommendation context ───
    // بيوصل من FarmProfile.getLeachingRecommendation() اللي أصلاً بتجمع
    // TDS + soil moisture + soil type. الـ AI هنا مش بيحسب التوصية من
    // الأول، ده هيبني كلامه فوق التوصية المحسوبة أصلاً (rule-based)
    // ويشرحها للمزارع بدل ما يخترع رقم جديد.
    final String leachingContext = leachingMessage != null
        ? """

System-Calculated Leaching Status:
- Needs leaching: ${needsLeaching == true ? 'Yes' : 'No'}
- Status: $leachingMessage
${leachingAdvice != null ? '- Suggested action: $leachingAdvice' : ''}
Treat this as a pre-computed fact from the irrigation system, not something to recalculate — explain
it in your own words and weave it into your soil management guidance and final recommendation."""
        : "";

    return """
You are a strict, data-driven agricultural water quality expert certified under ISO 17025 and FAO irrigation guidelines.
CRITICAL RULE: SENSOR DATA IS THE ABSOLUTE GROUND TRUTH. $visualInstruction
Even if a leaf looks healthy, if TDS > 1000 or Purity < 70%, the water poses RISKS TO SOIL AND CROPS.

Sensor readings:
- TDS: ${tds.toStringAsFixed(1)} PPM
- Soil Moisture: ${purity.toStringAsFixed(1)}%
- pH: ${ph?.toStringAsFixed(1) ?? 'N/A'}
- Temperature: ${temperature.toStringAsFixed(1)}°C
$historicalContext
$leachingContext

FAO Irrigation Water Standards (based on TDS/Salinity):
- < 500 PPM: Excellent for all crops, seedlings, and sensitive plants.
- 500 - 1000 PPM: Good for most crops, but sensitive plants may suffer slightly.
- 1000 - 2000 PPM: Suitable ONLY for salt-tolerant crops (Date Palm, Olive, Barley, Zucchini, Cotton).
- > 2000 PPM: UNSAFE for most agriculture, causes severe soil salinity and crop failure.

pH Considerations:
- Ideal range for irrigation: 6.0 - 8.5
- Below 6.0: May increase heavy metal availability in soil, toxic to some plants.
- Above 8.5: May reduce nutrient availability, especially iron and phosphorus.

You MUST respond ONLY with a valid JSON object.

Required JSON format:
{
  "isSafe": true/false (based on FAO irrigation suitability, NOT drinking standards),
  "detailPoints": [
    "تحليل الأرقام: تقييم مباشر لقراءات الحساسات (TDS، النقاء، الحرارة) وما إذا كانت ضمن معايير الري الآمن حسب FAO.",
    "${hasImage ? 'التقاطع البصري: هل أعراض الإجهاد الملحي الظاهرة على الورقة (لو وجدت) متسقة مع مستوى الملوحة المقاس؟ (مثلاً: احتراق أطراف الورق رغم TDS "مقبول" قد يعني تراكم ملحي تراكمي في التربة).' : 'تقييم بالأرقام فقط: لا تفترض أي معلومات بصرية؛ اعتمد حصراً على القراءات ومعايير FAO.'}",
    "ملاءمة المحاصيل: ما هي أنواع النباتات المناسبة تحديداً لقيمة الـ TDS الحالية بناءً على معايير FAO المذكورة أعلاه؟",
    "إدارة التربة: ${saltTrendLabel != null ? 'اربط بين الاتجاه التاريخي للملوحة (7 أيام) والقراءة الحالية — هل القراءة الآمنة ظاهريًا مخفية وراءها اتجاه تصاعدي خطير؟' : 'تحذير حول تراكم الأملاح في التربة على المدى الطويل، ونصائح للغسيل أو المعالجة إذا لزم الأمر.'}"
  ],
  "recommendation": "توصية عملية دقيقة ومخصصة بناءً على الأرقام${leachingMessage != null ? '، ومبنية على حالة الغسيل المحسوبة مسبقاً أعلاه (اشرحها بأسلوبك، ومتخترعش رقم مختلف عنها)' : ''}. مثلاً: لو الـ TDS عالي، انصح بنباتات محددة تتحمل الملوحة أو استخدام نظام ري بالتنقيط مع غسيل دوري."
}

Rules:
- detailPoints MUST be a JSON array of exactly 4 strings in Arabic.
- Each string must be 15-30 words, concise, and highly professional.
- Do NOT hallucinate plant names; stick to the FAO guidelines provided above.
- Focus exclusively on irrigation, crop health, and soil management.
- If a 7-Day Historical Salt Trend section is present above, you MUST reference it explicitly in
  the "إدارة التربة" point and factor it into "recommendation" — do not ignore it.
- If a System-Calculated Leaching Status section is present above, your "recommendation" MUST be
  consistent with it (do not recommend leaching if needsLeaching is No, and vice versa).
""";
  }

  @override
  String buildSystemMessage() {
    return "You are a precise agricultural water quality analysis API. Always output JSON. SENSOR DATA overrides visual data in your logic. Focus on FAO irrigation standards and crop suitability.";
  }

  @override
  List<String> parseDetailPoints(dynamic rawDetails) {
    if (rawDetails is List) {
      return rawDetails.map((e) => e.toString()).toList();
    } else if (rawDetails is String) {
      return rawDetails
          .split(RegExp(r'\d+\.'))
          .where((s) => s.trim().isNotEmpty)
          .map((s) => s.trim())
          .toList();
    }
    return [
      "لا توجد تفاصيل متاحة عن الأرقام",
      "لا توجد تفاصيل مرئية",
      "لا توجد تفاصيل عن المحاصيل",
      "لا توجد نصائح زراعية",
    ];
  }

  @override
  String defaultRecommendation(bool isSafe) {
    return isSafe
        ? "المياه مناسبة للري بناءً على الأرقام الحالية."
        : "يُنصح بعدم استخدام هذه المياه للري قبل معالجتها أو اختيار محاصيل تتحمل الملوحة العالية.";
  }

  @override
  String defaultSummary(bool isSafe) {
    return isSafe ? "التقييم: المياه مناسبة للري ✓" : "التقييم: تحذير — المياه غير مناسبة للري ⚠️";
  }
}