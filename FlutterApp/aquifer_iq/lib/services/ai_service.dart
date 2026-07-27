import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import '/ai_strategies/ai_prompt_strategy.dart';
import '/ai_strategies/home_prompt_strategy.dart';
import '/ai_strategies/agricultural_prompt_strategy.dart';

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

  // ─── Strategy Registry ──────────────────────────────────────────
  static final Map<AppMode, AiPromptStrategy> _promptStrategies = {
    AppMode.home: HomePromptStrategy(),
    AppMode.agricultural: AgriculturalPromptStrategy(),
  };

  Future<AiAnalysisResult> analyzeWaterImage({
    required File? imageFile, // nullable الآن — Agricultural mode ممكن يشتغل بالحساسات بس
    required double tds,
    required double purity,
    required double temperature,
    double? ph,
    AppMode mode = AppMode.home,
    // ─── Historical trend + Leaching context (Agricultural mode فقط) ───
    // بتوصل جاهزة من الشاشة اللي بتنادي الـ service (محسوبة أصلاً من
    // FarmProfile.calculateSaltTrend / getLeachingRecommendation)، عشان
    // الـ AiService يفضل مسؤول بس عن التواصل مع الـ API، مش عن حسابات
    // الزراعة. لو null (زي Home mode)، الـ strategy بتتجاهلها بأمان.
    String? saltTrendLabel,
    double? avgTds7Days,
    bool? needsLeaching,
    String? leachingMessage,
    String? leachingAdvice,
  }) async {
    try {
      // Get the appropriate strategy for this mode
      final strategy = _promptStrategies[mode] ?? _promptStrategies[AppMode.home]!;
      final bool hasImage = imageFile != null;

      final prompt = strategy.buildPrompt(
        tds: tds,
        purity: purity,
        temperature: temperature,
        ph: ph,
        hasImage: hasImage,
        saltTrendLabel: saltTrendLabel,
        avgTds7Days: avgTds7Days,
        needsLeaching: needsLeaching,
        leachingMessage: leachingMessage,
        leachingAdvice: leachingAdvice,
      );

      // نبني محتوى الرسالة ديناميكيًا: النص دايمًا موجود، وصورة الـ base64
      // بتتضاف بس لو فعليًا اتصورت.
      final List<Map<String, dynamic>> userContent = [
        {"type": "text", "text": prompt},
      ];
      if (hasImage) {
        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        userContent.add({
          "type": "image_url",
          "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
        });
      }

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
              "content": strategy.buildSystemMessage(),
            },
            {
              "role": "user",
              "content": userContent,
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

        List<String> detailPoints = strategy.parseDetailPoints(aiJson['detailPoints']);

        while (detailPoints.length < 4) {
          detailPoints.add("بيانات غير متاحة");
        }

        final String recommendation = aiJson['recommendation'] ?? strategy.defaultRecommendation(isSafe);

        return AiAnalysisResult(
          summary: aiJson['summary'] ?? strategy.defaultSummary(isSafe),
          recommendation: recommendation,
          isSafe: isSafe,
          detailPoints: detailPoints,
        );

      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }

    } catch (e) {
      debugPrint("AI Service Error: $e");
      final strategy = _promptStrategies[mode] ?? _promptStrategies[AppMode.home]!;
      return AiAnalysisResult(
        summary: "فشل التحليل 🔌",
        recommendation: "لم نتمكن من تحليل البيانات. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.",
        isSafe: false,
        detailPoints: strategy.parseDetailPoints(null),
      );
    }
  }
}