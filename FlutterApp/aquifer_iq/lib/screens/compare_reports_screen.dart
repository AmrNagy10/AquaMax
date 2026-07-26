import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:provider/provider.dart';
import '../services/reports_service.dart';
import '../services/mode_service.dart';
import '../services/Scoring_Engine.dart';
import '../models/app_mode.dart';
=======
=======
import 'package:provider/provider.dart';
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
import '../services/reports_service.dart';
import '../services/mode_service.dart';
import '../services/Scoring_Engine.dart';
<<<<<<< HEAD
>>>>>>> 5df08f9 (Redesigning and add new Featrues for SensorX)
=======
import '../models/app_mode.dart';
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)

class CompareReportsScreen extends StatefulWidget {
  final WaterAnalysisReport report1;
  final WaterAnalysisReport report2;

  const CompareReportsScreen({
    super.key,
    required this.report1,
    required this.report2,
  });

  @override
  State<CompareReportsScreen> createState() => _CompareReportsScreenState();
}

class _CompareReportsScreenState extends State<CompareReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final report1 = widget.report1;
    final report2 = widget.report2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;

    final score1 = report1.score;
    final score2 = report2.score;
    final diff = score2 - score1;
    final isImprovement = diff >= 0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F7F6),
      appBar: AppBar(
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
        title: Consumer<ModeService>(
          builder: (context, modeService, child) => Text(
            modeService.currentMode == AppMode.agricultural ? "Irrigation Comparison" : "Comparison Results",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
<<<<<<< HEAD
=======
        title: const Text("Comparison Results", style: TextStyle(fontWeight: FontWeight.bold)),
>>>>>>> 5df08f9 (Redesigning and add new Featrues for SensorX)
=======
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score Cards ──
            Row(
              children: [
                Expanded(
                  child: _buildScoreCard("Report 1", report1, isDark, textColor, cardColor, subtitleColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildScoreCard("Report 2", report2, isDark, textColor, cardColor, subtitleColor),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Score Graph ──
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
            Consumer<ModeService>(
              builder: (context, modeService, child) {
                final isAg = modeService.currentMode == AppMode.agricultural;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAg ? "SCORE COMPARISON" : "SCORE COMPARISON", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildScoreGraph(score1, score2, isDark, cardColor, textColor, subtitleColor),
                    const SizedBox(height: 24),
<<<<<<< HEAD

                    // ── Detailed Comparison ──
                    Text(isAg ? "FIELD METRICS" : "DETAILED METRICS", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildMetricComparison(isAg ? "Salinity" : "TDS", "${report1.tds.toStringAsFixed(0)} PPM", "${report2.tds.toStringAsFixed(0)} PPM", Icons.opacity, Colors.cyan, isDark, textColor, cardColor),
                    _buildMetricComparison("pH", report1.ph.toStringAsFixed(1), report2.ph.toStringAsFixed(1), Icons.science, ScoringEngine.getPhColor(report1.ph), isDark, textColor, cardColor),
                    _buildMetricComparison(isAg ? "Moisture" : "Purity", "${report1.purity.toStringAsFixed(0)}%", "${report2.purity.toStringAsFixed(0)}%", isAg ? Icons.grass : Icons.clean_hands, isAg ? const Color(0xFF639922) : Colors.green, isDark, textColor, cardColor),
                    _buildMetricComparison("Temperature", "${report1.temperature.toStringAsFixed(1)}°C", "${report2.temperature.toStringAsFixed(1)}°C", Icons.thermostat, Colors.blue, isDark, textColor, cardColor),
                  ],
                );
              },
            ),
=======
            Text("SCORE COMPARISON", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildScoreGraph(score1, score2, isDark, cardColor, textColor, subtitleColor),
            const SizedBox(height: 24),

            // ── Detailed Comparison ──
            Text("DETAILED METRICS", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMetricComparison("TDS", "${report1.tds.toStringAsFixed(0)} PPM", "${report2.tds.toStringAsFixed(0)} PPM", Icons.opacity, Colors.cyan, isDark, textColor, cardColor),
            _buildMetricComparison("pH", report1.ph.toStringAsFixed(1), report2.ph.toStringAsFixed(1), Icons.science, ScoringEngine.getPhColor(report1.ph), isDark, textColor, cardColor),
            _buildMetricComparison("Purity", "${report1.purity.toStringAsFixed(0)}%", "${report2.purity.toStringAsFixed(0)}%", Icons.clean_hands, Colors.green, isDark, textColor, cardColor),
            _buildMetricComparison("Temperature", "${report1.temperature.toStringAsFixed(1)}°C", "${report2.temperature.toStringAsFixed(1)}°C", Icons.thermostat, Colors.blue, isDark, textColor, cardColor),
>>>>>>> 5df08f9 (Redesigning and add new Featrues for SensorX)
=======

                    // ── Detailed Comparison ──
                    Text(isAg ? "FIELD METRICS" : "DETAILED METRICS", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildMetricComparison(isAg ? "Salinity" : "TDS", "${report1.tds.toStringAsFixed(0)} PPM", "${report2.tds.toStringAsFixed(0)} PPM", Icons.opacity, Colors.cyan, isDark, textColor, cardColor),
                    _buildMetricComparison("pH", report1.ph.toStringAsFixed(1), report2.ph.toStringAsFixed(1), Icons.science, ScoringEngine.getPhColor(report1.ph), isDark, textColor, cardColor),
                    _buildMetricComparison(isAg ? "Moisture" : "Purity", "${report1.purity.toStringAsFixed(0)}%", "${report2.purity.toStringAsFixed(0)}%", isAg ? Icons.grass : Icons.clean_hands, isAg ? const Color(0xFF639922) : Colors.green, isDark, textColor, cardColor),
                    _buildMetricComparison("Temperature", "${report1.temperature.toStringAsFixed(1)}°C", "${report2.temperature.toStringAsFixed(1)}°C", Icons.thermostat, Colors.blue, isDark, textColor, cardColor),
                  ],
                );
              },
            ),
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
            const SizedBox(height: 24),

            // ── Change Summary ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isImprovement
                    ? const Color(0xFF639922).withOpacity(0.1)
                    : const Color(0xFFE24B4A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isImprovement
                      ? const Color(0xFF639922).withOpacity(0.3)
                      : const Color(0xFFE24B4A).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isImprovement ? Icons.trending_up : Icons.trending_down,
                    color: isImprovement ? const Color(0xFF639922) : const Color(0xFFE24B4A),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
                  Consumer<ModeService>(
                    builder: (context, modeService, child) => Text(
                      isImprovement
                          ? (modeService.currentMode == AppMode.agricultural ? "Irrigation Quality Improved" : "Quality Improved")
                          : (modeService.currentMode == AppMode.agricultural ? "Irrigation Quality Declined" : "Quality Declined"),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isImprovement ? const Color(0xFF639922) : const Color(0xFFE24B4A),
                      ),
<<<<<<< HEAD
=======
                  Text(
                    isImprovement ? "Quality Improved" : "Quality Declined",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isImprovement ? const Color(0xFF639922) : const Color(0xFFE24B4A),
>>>>>>> 5df08f9 (Redesigning and add new Featrues for SensorX)
=======
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Score changed by ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} points",
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
                  const SizedBox(height: 4),
                  Consumer<ModeService>(
                    builder: (context, modeService, child) => Text(
                      modeService.currentMode == AppMode.agricultural
                          ? "Field conditions ${isImprovement ? 'improved' : 'worsened'}"
                          : "Water conditions ${isImprovement ? 'improved' : 'worsened'}",
                      style: TextStyle(fontSize: 13, color: subtitleColor),
                    ),
                  ),
<<<<<<< HEAD
=======
>>>>>>> 5df08f9 (Redesigning and add new Featrues for SensorX)
=======
>>>>>>> cabb3a2 (Add Hame&agricultural modes with some changes at ui)
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, WaterAnalysisReport report, bool isDark, Color textColor, Color cardColor, Color subtitleColor) {
    Color scoreColor = const Color(0xFF639922);
    if (report.score < 40) scoreColor = const Color(0xFFE24B4A);
    else if (report.score < 75) scoreColor = const Color(0xFFEF9F27);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(DateFormat('MMM dd').format(report.date), style: TextStyle(fontSize: 14, color: textColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    report.score.toStringAsFixed(0),
                    style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TDS: ${report.tds.toStringAsFixed(0)}", style: TextStyle(fontSize: 11, color: subtitleColor)),
                  Text("pH: ${report.ph.toStringAsFixed(1)}", style: TextStyle(fontSize: 11, color: subtitleColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGraph(double score1, double score2, bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    final maxScore = 100.0;
    final barHeight = 140.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bar 1
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score1.toStringAsFixed(1),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: score1 / maxScore),
                    builder: (context, value, child) {
                      final color = score1 >= 75 ? const Color(0xFF639922) :
                      score1 >= 40 ? const Color(0xFFEF9F27) :
                      const Color(0xFFE24B4A);
                      return Container(
                        width: 60,
                        height: value * barHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text("Report 1", style: TextStyle(fontSize: 12, color: subtitleColor)),
                ],
              ),
              // Bar 2
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score2.toStringAsFixed(1),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: score2 / maxScore),
                    builder: (context, value, child) {
                      final color = score2 >= 75 ? const Color(0xFF639922) :
                      score2 >= 40 ? const Color(0xFFEF9F27) :
                      const Color(0xFFE24B4A);
                      return Container(
                        width: 60,
                        height: value * barHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text("Report 2", style: TextStyle(fontSize: 12, color: subtitleColor)),
                ],
              ),
            ],
          ),
          const Divider(height: 30),
          // Mini legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(const Color(0xFF639922)),
              const SizedBox(width: 4),
              Text("Good (75+)", style: TextStyle(fontSize: 11, color: subtitleColor)),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFFEF9F27)),
              const SizedBox(width: 4),
              Text("Average (40-75)", style: TextStyle(fontSize: 11, color: subtitleColor)),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFFE24B4A)),
              const SizedBox(width: 4),
              Text("Poor (<40)", style: TextStyle(fontSize: 11, color: subtitleColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildMetricComparison(
      String label,
      String value1,
      String value2,
      IconData icon,
      Color color,
      bool isDark,
      Color textColor,
      Color cardColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
            ),
            Text(value1, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.compare_arrows, size: 16, color: Color(0xFF185FA5)),
            ),
            Text(value2, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
