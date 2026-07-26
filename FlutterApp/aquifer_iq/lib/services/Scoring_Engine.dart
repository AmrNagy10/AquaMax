import 'package:flutter/material.dart';
import '../models/score_result.dart';
import '../models/app_mode.dart';
import '../models/farm_profile.dart';
import 'ble_service.dart';
import '/scoring_strategies/home_score_calculator.dart';
import '/scoring_strategies/agricultural_score_calculator.dart';
import '/scoring_strategies/score_calculator.dart';

class ScoringEngine {
  // ─── Strategy Registry ──────────────────────────────────────────
  static final Map<AppMode, ScoreCalculator> _strategies = {
    AppMode.home: HomeScoreCalculator(),
    AppMode.agricultural: AgriculturalScoreCalculator(),
  };

  // ─── Grade & message labels per mode ────────────────────────────
  static const Map<String, Map<String, String>> _labels = {
    'home': {
      'tdsUnit': 'PPM',
      'purityUnit': '%',
      'tempUnit': '°C',
      'phUnit': 'pH',
      'scoreLabel': 'Water Quality',
      'dashboardTitle': 'System Health',
    },
    'agricultural': {
      'tdsUnit': 'PPM',
      'purityUnit': '%',
      'tempUnit': '°C',
      'phUnit': 'pH',
      'scoreLabel': 'Irrigation Quality',
      'dashboardTitle': 'Field Analysis',
    },
  };

  /// Returns the labels for the given mode
  static Map<String, String> getLabels(AppMode mode) {
    return _labels[mode.name] ?? _labels['home']!;
  }

  /// Main entry point — delegates to the appropriate strategy
  static WaterScoreResult calculateScore(SensorData data, {AppMode mode = AppMode.home, double aiMultiplier = 1.0, FarmProfile? farmProfile}) {
    if (data.tds == 0 && data.purity == 0 && data.temperature == 0 && data.ph == 0) {
      return WaterScoreResult(
        numericScore: 0,
        grade: "--",
        statusColor: Colors.grey,
        message: "Waiting for Data...",
        tips: ["Connect device or start simulation"],
      );
    }

    final strategy = _strategies[mode] ?? _strategies[AppMode.home]!;
    return strategy.calculate(data, aiMultiplier, farmProfile: farmProfile);
  }

  // pH Color Helper
  static Color getPhColor(double ph) {
    if (ph < 4.0) return Colors.red;
    if (ph < 6.5) return Colors.orange;
    if (ph <= 8.5) return Colors.green;
    if (ph <= 10.0) return Colors.blue;
    return Colors.purple;
  }

  static Color getTdsColor(double tds) {
    if (tds <= 300) return const Color(0xFF2ECC71);
    if (tds <= 600) return const Color(0xFF27AE60);
    if (tds <= 900) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  static Color getPurityColor(double purity) {
    if (purity >= 90) return const Color(0xFF2ECC71);
    if (purity >= 70) return const Color(0xFF27AE60);
    if (purity >= 50) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  static Color getTemperatureColor(double temp) {
    if (temp >= 15 && temp <= 25) return const Color(0xFF3498DB);
    if ((temp >= 10 && temp < 15) || (temp > 25 && temp <= 30)) {
      return const Color(0xFFF39C12);
    }
    return const Color(0xFFE74C3C);
  }

}
