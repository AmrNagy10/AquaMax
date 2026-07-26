import 'package:flutter/material.dart';
import '../../models/score_result.dart';
import '../services/ble_service.dart';
import 'score_calculator.dart';
import '../../models/farm_profile.dart';

/// Home mode scoring strategy.
///
/// Focus: Drinking safety and household water quality.
/// Weights: TDS 30%, Purity 35%, pH 20%, Temp 15%
/// - Purity is the most important factor (drinking safety)
/// - TDS is secondary (mineral content)
class HomeScoreCalculator implements ScoreCalculator {
  @override
  String get label => 'Home';

  @override
  Map<String, double> get weights => {
    'tds':    0.30,
    'purity': 0.35,
    'ph':     0.20,
    'temp':   0.15,
  };

  @override
  Map<String, double> calculateSubScores(SensorData data, {FarmProfile? farmProfile}) {
    // TDS Score (Ideal < 150 PPM for drinking water)
    double tdsScore = (data.tds <= 150)
        ? 100
        : (100 - ((data.tds - 150) / (1200 - 150) * 100)).clamp(0.0, 100.0);

    // Purity Score (0-100)
    double purityScore = data.purity.clamp(0.0, 100.0);

    // pH Score (Ideal 6.5 - 8.5 for drinking water per WHO)
    double phScore = 0;
    if (data.ph >= 6.5 && data.ph <= 8.5) {
      phScore = 100;
    } else if (data.ph < 4.0 || data.ph > 11.0) {
      phScore = 0;
    } else {
      if (data.ph < 6.5) {
        phScore = ((data.ph - 4.0) / (6.5 - 4.0)) * 100;
      } else {
        phScore = (1 - (data.ph - 8.5) / (11.0 - 8.5)) * 100;
      }
    }

    // Temperature Score (Ideal 10-25°C for drinking)
    double tempScore = (data.temperature >= 10 && data.temperature <= 25)
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
    if (score >= 90) return "Excellent Quality";
    if (score >= 75) return "Good Quality";
    if (score >= 60) return "Acceptable Quality";
    if (score >= 40) return "Poor Quality";
    return "Hazardous";
  }

  @override
  List<String> getTips(double score) {
    if (score >= 90) {
      return ["Perfect pH balance", "Safe for all uses"];
    } else if (score >= 75) {
      return ["Healthy mineral levels", "Safe for drinking"];
    } else if (score >= 60) {
      return ["Slightly off balance", "Boil if drinking"];
    } else if (score >= 40) {
      return ["Acidic/Alkaline issues", "Unsafe for drinking"];
    } else {
      return ["Chemical imbalance", "Harmful to humans"];
    }
  }

  @override
  WaterScoreResult calculate(SensorData data, double aiMultiplier, {FarmProfile? farmProfile}) {
    final subScores = calculateSubScores(data, farmProfile: farmProfile);
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
