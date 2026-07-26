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
  }) {
    return """
You are a strict, data-driven agricultural water quality expert certified under ISO 17025 and FAO irrigation guidelines.
CRITICAL RULE: SENSOR DATA IS THE ABSOLUTE GROUND TRUTH. The image is ONLY for secondary visual confirmation. Even if the water looks clear, if TDS > 1000 or Purity < 70%, the water poses RISKS TO SOIL AND CROPS.

Sensor readings:
- TDS: ${tds.toStringAsFixed(1)} PPM
- Purity: ${purity.toStringAsFixed(1)}%
- pH: ${ph?.toStringAsFixed(1) ?? 'N/A'}
- Temperature: ${temperature.toStringAsFixed(1)}°C

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
    "التقاطع البصري: هل يتطابق الشكل المرئي في الصورة مع الأرقام؟ (مثلاً: رغم النقاء الظاهري، الأرقام تظهر ملوحة عالية، أو العكس).",
    "ملاءمة المحاصيل: ما هي أنواع النباتات المناسبة تحديداً لقيمة الـ TDS الحالية بناءً على معايير FAO المذكورة أعلاه؟",
    "إدارة التربة: تحذير حول تراكم الأملاح في التربة على المدى الطويل، ونصائح للغسيل أو المعالجة إذا لزم الأمر."
  ],
  "recommendation": "توصية عملية دقيقة ومخصصة بناءً على الأرقام. مثلاً: لو الـ TDS عالي، انصح بنباتات محددة تتحمل الملوحة أو استخدام نظام ري بالتنقيط مع غسيل دوري."
}

Rules:
- detailPoints MUST be a JSON array of exactly 4 strings in Arabic.
- Each string must be 15-30 words, concise, and highly professional.
- Do NOT hallucinate plant names; stick to the FAO guidelines provided above.
- Focus exclusively on irrigation, crop health, and soil management.
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
