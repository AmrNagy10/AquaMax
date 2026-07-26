import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AiAnalysisResult {
  final String summary;
  final String recommendation;
  final bool isSafe;
  final List<String> detailPoints;

  AiAnalysisResult({
    required this.summary,
    required this.recommendation,
    required this.isSafe,
    required this.detailPoints,
  });

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'recommendation': recommendation,
    'isSafe': isSafe,
    'detailPoints': detailPoints,
  };

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) => AiAnalysisResult(
    summary: json['summary'] ?? "تحليل",
    recommendation: json['recommendation'] ?? "",
    isSafe: json['isSafe'] ?? false,
    detailPoints: List<String>.from(json['detailPoints'] ?? [
      "لا توجد تفاصيل متاحة عن الأرقام",
      "لا توجد تفاصيل مرئية",
      "لا توجد تفاصيل عن الشرب",
      "لا توجد تفاصيل عن الزراعة",
    ]),
  );
}

class AiService {
  static const String _githubToken = "";
  static const String _endpoint = "";

  Future<AiAnalysisResult> analyzeWaterImage({
    required File imageFile,
    required double tds,
    required double purity,
    required double temperature,
    double? ph,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = """
You are a strict, data-driven water quality expert (ISO 17025). 
CRITICAL RULE: SENSOR DATA IS THE ABSOLUTE GROUND TRUTH. The image is ONLY for secondary visual confirmation. Even if the water looks crystal clear in the image, if TDS > 600 or Purity < 85%, the water is UNSAFE.

Sensor readings:
- TDS: ${tds.toStringAsFixed(1)} PPM
- Purity: ${purity.toStringAsFixed(1)}%
- pH: ${ph?.toStringAsFixed(1) ?? 'N/A'}
- Temperature: ${temperature.toStringAsFixed(1)}°C

Scientific Standards for Evaluation:
1. Drinking Water (WHO): TDS < 600 PPM, Purity > 85%, Temp 10–30°C.
2. Agricultural Water (FAO Guidelines based on TDS):
   - < 500 PPM: Excellent for all plants and seedlings.
   - 500 - 1000 PPM: Good for most crops, but sensitive plants may suffer slightly.
   - 1000 - 2000 PPM: Unsafe for drinking. Only suitable for salt-tolerant crops (e.g., Date Palm, Olive, Barley, Zucchini).
   - > 2000 PPM: Unsafe for most agriculture, causes severe soil salinity.

You MUST respond ONLY with a valid JSON object.

Required JSON format:
{
  "isSafe": true/false (based strictly on WHO drinking limits),
  "detailPoints": [
    "تحليل الأرقام: تقييم مباشر لقراءات الحساسات (TDS، النقاء، الحرارة) وما إذا كانت ضمن الحدود.",
    "التقاطع البصري: هل يتطابق الشكل المرئي في الصورة مع الأرقام؟ (مثلاً: رغم النقاء الظاهري، الأرقام تظهر عكس ذلك، أو العكس).",
    "صلاحية الاستخدام البشري: حكم نهائي حول الشرب والاستخدام المنزلي بناءً على الأرقام أولاً.",
    "التوافق الزراعي: ما هي أنواع النباتات المناسبة تحديداً لقيمة الـ TDS الحالية بناءً على معايير FAO المذكورة أعلاه؟"
  ],
  "recommendation": "توصية عملية دقيقة ومخصصة بناءً على الأرقام. مثلاً: لو الـ TDS عالي جداً، انصح بنباتات محددة تتحمل الملوحة أو استخدام فلاتر RO."
}

Rules:
- detailPoints MUST be a JSON array of exactly 4 strings in Arabic.
- Each string must be 15-30 words, concise, and highly professional.
- Do NOT hallucinate plant names; stick to the FAO guidelines provided.
""";

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_githubToken',
        },
        body: jsonEncode({
          "model": "gpt-4.1-mini",
          "messages": [
            {
              "role": "system",
              "content": "You are a precise data-processing API. Always output JSON. SENSOR DATA overrides visual data in your logic."
            },
            {
              "role": "user",
              "content": [
                {"type": "text", "text": prompt},
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
                }
              ]
            }
          ],
          "max_tokens": 1000,
          "temperature": 0.0,
          "response_format": {"type": "json_object"}
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        String textContent = responseData['choices'][0]['message']['content'] ?? "{}";

        textContent = textContent
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> aiJson = jsonDecode(textContent);

        final bool isSafe = aiJson['isSafe'] == true;

        List<String> detailPoints;
        final rawDetails = aiJson['detailPoints'];

        if (rawDetails is List) {
          detailPoints = rawDetails.map((e) => e.toString()).toList();
        } else if (rawDetails is String) {
          detailPoints = rawDetails
              .split(RegExp(r'\d+\.'))
              .where((s) => s.trim().isNotEmpty)
              .map((s) => s.trim())
              .toList();
        } else {
          detailPoints = ["لا توجد تفاصيل", "لا توجد تفاصيل", "لا توجد تفاصيل", "لا توجد تفاصيل"];
        }

        while (detailPoints.length < 4) {
          detailPoints.add("بيانات غير متاحة");
        }

        final String recommendation = aiJson['recommendation'] ?? (
            isSafe ? "المياه صالحة للاستخدام بناءً على الأرقام." : "يُنصح بعدم استخدام هذه المياه قبل معالجتها."
        );

        return AiAnalysisResult(
          summary: isSafe ? "التقييم: المياه آمنة ✓" : "التقييم: تحذير من الجودة ⚠️",
          recommendation: recommendation,
          isSafe: isSafe,
          detailPoints: detailPoints,
        );

      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }

    } catch (e) {
      debugPrint("AI Service Error: $e");
      return AiAnalysisResult(
        summary: "فشل التحليل 🔌",
        recommendation: "لم نتمكن من تحليل البيانات. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.",
        isSafe: false,
        detailPoints: [
          "تعذّر تحليل الأرقام بسبب خطأ في الشبكة.",
          "تعذّر فحص الصورة المرفقة.",
          "التقييم البشري غير متاح حالياً.",
          "بيانات الزراعة غير متوفرة.",
        ],
      );
    }
  }
}
