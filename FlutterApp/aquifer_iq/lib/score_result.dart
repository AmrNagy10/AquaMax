import 'package:flutter/material.dart';

class WaterScoreResult {
  final double numericScore; // 0 - 100
  final String grade;        // A+, A, B, C, D
  final Color statusColor;
  final String message;      // Brief summary message
  final List<String> tips;   // Immediate actionable tips

  WaterScoreResult({
    required this.numericScore,
    required this.grade,
    required this.statusColor,
    required this.message,
    required this.tips,
  });
}
