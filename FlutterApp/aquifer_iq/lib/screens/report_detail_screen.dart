import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/reports_service.dart';
import '../services/Scoring_Engine.dart';

class ReportDetailScreen extends StatelessWidget {
  final WaterAnalysisReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Analysis Details"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM dd, yyyy').format(report.date),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      DateFormat('hh:mm:ss a').format(report.date),
                      style: TextStyle(color: subtitleColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF185FA5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Score: ${report.score.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Image Preview (if exists)
            if (report.imageFile.existsSync())
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: FileImage(report.imageFile),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 25),

            // Sensors Data Card
            Text("SENSOR READINGS", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildDataRow("TDS Level", "${report.tds.toStringAsFixed(0)} PPM", Icons.opacity, Colors.cyan),
                  const Divider(),
                  _buildDataRow("pH Level", report.ph.toStringAsFixed(1), Icons.science, ScoringEngine.getPhColor(report.ph)),
                  const Divider(),
                  _buildDataRow("Purity", "${report.purity.toStringAsFixed(0)}%", Icons.clean_hands, Colors.green),
                  const Divider(),
                  _buildDataRow("Temperature", "${report.temperature.toStringAsFixed(1)}°C", Icons.thermostat, Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // AI Analysis
            Text("AI ANALYSIS & RECOMMENDATION", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF185FA5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF185FA5).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF185FA5), size: 20),
                      const SizedBox(width: 10),
                      Text("Expert Insights", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.aiResult.summary,
                        style: TextStyle(color: textColor, height: 1.6),
                      ),
                      const SizedBox(height: 12), // مسافة فصل أرتب من \n
                      Text(
                        report.aiResult.recommendation,
                        style: TextStyle(color: textColor, height: 1.6),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
