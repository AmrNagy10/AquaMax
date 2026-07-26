import 'package:flutter/material.dart';
import '../../models/score_result.dart';
import '../../models/farm_profile.dart';
import '../services/ble_service.dart';

/// Abstract interface for all scoring strategies.
/// Each mode (Home, Agricultural, Industrial, ...) implements this interface
/// with its own weights, thresholds, and grading logic.
///
/// To add a new mode, simply create a new class that implements
/// [ScoreCalculator] and register it in [ScoringEngine._strategies].
abstract class ScoreCalculator {
  /// The display name for this strategy (e.g., "Home", "Agricultural")
  String get label;

  /// Returns the weights map for this strategy.
  /// Keys: 'tds', 'purity', 'ph', 'temp'
  /// Values must sum to 1.0
  Map<String, double> get weights;

  /// Calculate the sub-scores for each metric from raw sensor data.
  /// [farmProfile] اختياري — لو موجود، Agricultural strategy بتستخدمه
  /// لتعديل عتبات TDS حسب تحمّل المحصول المحدد بدل عتبة عامة ثابتة.
  /// Returns a map with keys 'tds', 'purity', 'ph', 'temp'.
  Map<String, double> calculateSubScores(SensorData data, {FarmProfile? farmProfile});

  /// Returns the grade (A+, A, B, C, D) based on the final numeric score.
  String getGrade(double score);

  /// Returns the color associated with a grade.
  Color getColor(double score);

  /// Returns a human-readable message for the given score.
  String getMessage(double score);

  /// Returns actionable tips for the given score.
  List<String> getTips(double score);

  /// Main entry point: takes raw sensor data and returns a full score result.
  WaterScoreResult calculate(SensorData data, double aiMultiplier, {FarmProfile? farmProfile});
}