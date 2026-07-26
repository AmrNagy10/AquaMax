import 'ai_prompt_strategy.dart';

/// Home mode AI prompt strategy.
///
/// Focus: Drinking water safety and household usage.
/// Standards: WHO drinking water guidelines.
/// Expected output: 4 detail points covering sensor analysis,
/// visual verification, human safety, and household recommendations.
class HomePromptStrategy implements AiPromptStrategy {
  @override
  String get label => 'Home';

  @override
  String buildPrompt({
    required double tds,
    required double purity,
    required double temperature,
    required double? ph,
    required bool hasImage, // الصورة إجبارية في Home، فمش بتغيّر الصياغة هنا
  }) {
    return """
You are a strict, data-driven water quality expert certified under ISO 17025.
CRITICAL RULE: SENSOR DATA IS THE ABSOLUTE GROUND TRUTH. The image is ONLY for secondary visual confirmation. Even if the water looks crystal clear in the image, if TDS > 600 or Purity < 85%, the water is UNSAFE FOR DRINKING.

Sensor readings:
- TDS: ${tds.toStringAsFixed(1)} PPM
- Purity: ${purity.toStringAsFixed(1)}%
- pH: ${ph?.toStringAsFixed(1) ?? 'N/A'}
- Temperature: ${temperature.toStringAsFixed(1)}°C

WHO Drinking Water Standards:
- TDS: Must be below 600 PPM (ideal < 300 PPM)
- Purity: Must be above 85%
- pH: Acceptable range 6.5 - 8.5
- Temperature: Acceptable range 10-30°C for drinking

You MUST respond ONLY with a valid JSON object.

Required JSON format:
{
  "isSafe": true/false (based strictly on WHO drinking limits above),
  "detailPoints": [
    "تحليل الأرقام: تقييم مباشر لقراءات الحساسات (TDS، النقاء، الحرارة) وما إذا كانت ضمن حدود منظمة الصحة العالمية للشرب الآمن.",
    "التقاطع البصري: هل يتطابق الشكل المرئي في الصورة مع الأرقام؟ (مثلاً: رغم النقاء الظاهري، الأرقام تظهر عكس ذلك، أو العكس).",
    "صلاحية الاستخدام البشري: حكم نهائي حول الشرب والاستخدام المنزلي بناءً على الأرقام أولاً.",
    "التوصية المنزلية: توصية عملية للاستخدام المنزلي. إذا كانت المياه غير صالحة، ما نوع الفلتر المناسب؟ (RO، UV، كربوني)."
  ],
  "recommendation": "توصية عملية دقيقة ومخصصة بناءً على الأرقام. مثلاً: لو الـ TDS عالي جداً، انصح باستخدام فلتر RO. لو النقاء منخفض، انصح بفلتر UV."
}

Rules:
- detailPoints MUST be a JSON array of exactly 4 strings in Arabic.
- Each string must be 15-30 words, concise, and highly professional.
- Focus exclusively on drinking water and household safety.
""";
  }

  @override
  String buildSystemMessage() {
    return "You are a precise water quality analysis API for drinking water. Always output JSON. SENSOR DATA overrides visual data in your logic. Focus on WHO standards for safe drinking water.";
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
      "لا توجد تفاصيل عن الشرب",
      "لا توجد توصيات منزلية",
    ];
  }

  @override
  String defaultRecommendation(bool isSafe) {
    return isSafe
        ? "المياه صالحة للشرب والاستخدام المنزلي بناءً على الأرقام."
        : "يُنصح بعدم شرب هذه المياه قبل معالجتها بفلتر RO أو UV حسب حالة التلوث.";
  }

  @override
  String defaultSummary(bool isSafe) {
    return isSafe ? "التقييم: المياه آمنة للشرب ✓" : "التقييم: تحذير — المياه غير صالحة للشرب ⚠️";
  }
}