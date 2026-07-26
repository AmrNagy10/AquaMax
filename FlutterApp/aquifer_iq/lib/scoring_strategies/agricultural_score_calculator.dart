import 'package:flutter/material.dart';
import '../../models/score_result.dart';
import '../services/ble_service.dart';
import 'score_calculator.dart';

/// Agricultural mode scoring strategy.
///
/// Focus: Irrigation suitability and soil health.
/// Weights: TDS 40%, Purity 25%, pH 20%, Temp 15%
/// - TDS is the most important factor (soil salinity / SAR)
/// - Purity is secondary (sediment can clog irrigation systems)
class AgriculturalScoreCalculator implements ScoreCalculator {
  @override
  String get label => 'Agricultural';

  @override
  Map<String, double> get weights => {
    'tds':    0.40,
    'purity': 0.25,
    'ph':     0.20,
    'temp':   0.15,
  };

  @override
  Map<String, double> calculateSubScores(SensorData data) {
    // TDS Score (Ideal < 300 for irrigation, 300-600 acceptable)
    double tdsScore = (data.tds <= 300)
        ? 100
        : (data.tds <= 600)
        ? 100 - ((data.tds - 300) / (600 - 300) * 30) // 100 -> 70
        : (data.tds <= 1200)
        ? 70 - ((data.tds - 600) / (1200 - 600) * 70) // 70 -> 0
        : 0;
    tdsScore = tdsScore.clamp(0.0, 100.0);

    // Purity Score (0-100) — sediment affects irrigation systems
    double purityScore = data.purity.clamp(0.0, 100.0);

    // pH Score (Ideal 6.0 - 8.5 for irrigation per FAO)
    double phScore = 0;
    if (data.ph >= 6.0 && data.ph <= 8.5) {
      phScore = 100;
    } else if (data.ph < 3.0 || data.ph > 11.0) {
      phScore = 0;
    } else {
      if (data.ph < 6.0) {
        phScore = ((data.ph - 3.0) / (6.0 - 3.0)) * 100;
      } else {
        phScore = (1 - (data.ph - 8.5) / (11.0 - 8.5)) * 100;
      }
    }

    // Temperature Score (Ideal 10-30°C for irrigation)
    double tempScore = (data.temperature >= 10 && data.temperature <= 30)
        ? 100
        : (data.temperature < 0 || data.temperature > 50)
        ? 0
        : 50;

    return {
      'tds':    tdsScore,
      'purity': purityScore,
      'ph':     phScore,
      'temp':   tempScore,
    };
  }

  @override
  String getGrade(double score) {
    if (score >= 90) return "A+";
    if (score >= 75) return "A";
    if (score >= 60) return "B";
    if (score >= 40) return "C";
    return "D";
  }

  @override
  Color getColor(double score) {
    if (score >= 90) return const Color(0xFF2E7D32);
    if (score >= 75) return const Color(0xFF639922);
    if (score >= 60) return const Color(0xFFEF9F27);
    if (score >= 40) return const Color(0xFFD85A30);
    return const Color(0xFFE24B4A);
  }

  @override
  String getMessage(double score) {
    if (score >= 90) return "Excellent Irrigation";
    if (score >= 75) return "Good Irrigation";
    if (score >= 60) return "Acceptable Irrigation";
    if (score >= 40) return "Poor Irrigation";
    return "Unsuitable";
  }

  @override
  List<String> getTips(double score) {
    if (score >= 90) {
      return ["Ideal for all crops", "No salinity concerns"];
    } else if (score >= 75) {
      return ["Suitable for most crops", "Monitor TDS levels"];
    } else if (score >= 60) {
      return ["Use for salt-tolerant crops", "Monitor soil accumulation"];
    } else if (score >= 40) {
      return ["High salinity risk", "Only for drought-tolerant crops"];
    } else {
      return ["Severe salinity", "Harmful to soil and crops"];
    }
  }

  @override
  WaterScoreResult calculate(SensorData data, double aiMultiplier) {
    final subScores = calculateSubScores(data);
    final w = weights;

    double finalScore = (subScores['tds']! * w['tds']!) +
        (subScores['purity']! * w['purity']!) +
        (subScores['ph']! * w['ph']!) +
        (subScores['temp']! * w['temp']!);

    finalScore = (finalScore * aiMultiplier).clamp(0.0, 100.0);

    return WaterScoreResult(
      numericScore: finalScore,
      grade: getGrade(finalScore),
      statusColor: getColor(finalScore),
      message: getMessage(finalScore),
      tips: getTips(finalScore),
    );
  }
}
