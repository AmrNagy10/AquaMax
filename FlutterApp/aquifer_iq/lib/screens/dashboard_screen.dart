import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../services/ble_service.dart';
import '../services/ai_service.dart';
import '../services/reports_service.dart';
import '../widgets/gauge_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  int _currentIndex = 0;

  // ─── Compensated TDS ──────────────────────────────────────────────────────
  double _compensatedTds(double rawTds, double temp) {
    return rawTds / (1 + 0.02 * (temp - 25));
  }

  // ─── Quality Grade ────────────────────────────────────────────────────────
  String _getQualityScore(SensorData data) {
    final double cTds = _compensatedTds(data.tds, data.temperature);
    final double pur  = data.purity;
    final double temp = data.temperature;

    final bool tempIdeal      = temp >= 10 && temp <= 25;
    final bool tempAcceptable = temp >= 5  && temp <= 35;
    final bool tempMarginal   = temp >= 1  && temp <= 45;

    if (cTds <= 150  && pur >= 95 && tempIdeal)      return "A+";
    if (cTds <= 300  && pur >= 90 && tempAcceptable) return "A";
    if (cTds <= 600  && pur >= 75 && tempAcceptable) return "B";
    if (cTds <= 1000 && pur >= 50 && tempMarginal)   return "C";
    return "D";
  }

  double _getScoreValue(String score) {
    switch (score) {
      case "A+": return 100;
      case "A":  return 80;
      case "B":  return 60;
      case "C":  return 35;
      case "D":  return 15;
      default:   return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // نظام الألوان المحسّن
  //
  // TDS:         teal → amber → coral → red   (أقل = أفضل)
  // Purity:      red  → amber → teal → green  (أكثر = أفضل)
  // Temperature: blue للنطاق المثالي — يعبر بصرياً عن طبيعة المياه الباردة
  //              ينتقل لـ amber عند الحرارة و red عند الخطر
  // Grade:       نفس سلم Purity (D أحمر → A+ أخضر)
  // ─────────────────────────────────────────────────────────────────────────

  // TDS: أقل = أنظف → teal ممتاز، amber مقبول، red خطر
  Color _getTdsColor(double rawTds, double temp) {
    final double cTds = _compensatedTds(rawTds, temp);
    if (cTds <= 150)  return const Color(0xFF1D9E75); // teal غامق — ممتاز
    if (cTds <= 300)  return const Color(0xFF5DCAA5); // teal فاتح — جيد
    if (cTds <= 600)  return const Color(0xFFEF9F27); // amber — مقبول
    if (cTds <= 1000) return const Color(0xFFD85A30); // coral — تحذير
    return const Color(0xFFE24B4A);                   // red — خطر
  }

  // Purity: أكثر = أفضل → سلم معكوس (red عند 0، green عند 100)
  Color _getPurityColor(double value) {
    if (value >= 95) return const Color(0xFF3B6D11); // أخضر غامق — ممتاز
    if (value >= 75) return const Color(0xFF639922); // أخضر — جيد
    if (value >= 60) return const Color(0xFFEF9F27); // amber — مقبول
    if (value >= 40) return const Color(0xFFD85A30); // coral — تحذير
    return const Color(0xFFE24B4A);                  // red — خطر
  }

  // Temperature: أزرق للنطاق المثالي (يعبر عن برودة المياه النظيفة)
  // ينتقل لـ amber عند الدفء ثم red عند الخطر — من الطرفين
  Color _getTempColor(double value) {
    if (value >= 10 && value <= 20) return const Color(0xFF378ADD); // أزرق — مثالي للشرب
    if (value >= 5  && value <= 30) return const Color(0xFF185FA5); // أزرق غامق — مقبول
    if (value >= 1  && value <= 40) return const Color(0xFFEF9F27); // amber — تحذير
    if (value >= 0  && value <= 50) return const Color(0xFFD85A30); // coral — خطر
    return const Color(0xFFE24B4A);                                  // red — حرج
  }

  // Grade: A+ أخضر غامق ← D أحمر
  Color _getScoreColor(String score) {
    switch (score) {
      case "A+": return const Color(0xFF2E7D32); // أخضر غامق
      case "A":  return const Color(0xFF639922); // أخضر
      case "B":  return const Color(0xFFEF9F27); // amber
      case "C":  return const Color(0xFFD85A30); // coral
      case "D":  return const Color(0xFFE24B4A); // red
      default:   return Colors.grey;
    }
  }

  // ─── AI Analysis ──────────────────────────────────────────────────────────
  Future<void> _runVisualAnalysis(SensorData data) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() => _isAnalyzing = true);

      final result = await _aiService.analyzeWaterImage(
        imageFile: File(image.path),
        tds: data.tds,
        purity: data.purity,
        temperature: data.temperature,
      );

      if (!mounted) return;

      context.read<ReportsService>().addReport(WaterAnalysisReport(
        date: DateTime.now(),
        tds: data.tds,
        purity: data.purity,
        temperature: data.temperature,
        imageFile: File(image.path),
        aiResult: result,
      ));

      setState(() => _currentIndex = 1);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء التحليل: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble  = context.watch<BleService>();
    final data = ble.sensorData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F7F6),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: const Color(0xFF185FA5),
          unselectedItemColor: Colors.grey[600],
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Reports"),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded),  label: "Settings"),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardBody(data, ble, isDark),
          const ReportsScreen(),
          const SettingsScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboardBody(SensorData data, BleService ble, bool isDark) {
    final cardColor     = isDark ? const Color(0xFF161B22) : Colors.white;
    // ✅ إصلاح dark mode: textColor و subtitleColor متكيفين صح
    final textColor     = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;

    final String score      = _getQualityScore(data);
    final Color  scoreColor = _getScoreColor(score);
    final double scoreValue = _getScoreValue(score);

    // ✅ bgColor للـ gauge cards متكيف مع dark mode
    final Color gaugeBg      = isDark ? const Color(0xFF161B22) : Colors.white;
    final Color tempGaugeBg  = isDark ? const Color(0xFF161B22) : const Color(0xFFE8F4FD); // أزرق فاتح جداً في light
    final Color gradeGaugeBg = isDark ? const Color(0xFF161B22) : const Color(0xFFF0FAF4); // أخضر فاتح جداً في light

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: Color(0xFF185FA5), shape: BoxShape.circle),
                      child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text("AquaMax", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textColor)), // ✅ تم التعديل هنا
                  ]),
                  GestureDetector(
                    onTap: ble.isConnected ? ble.disconnect : ble.startScan,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ble.isConnected ? const Color(0xFFC0DD97) : Colors.grey.withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ble.isConnected ? const Color(0xFF639922)
                                : ble.isScanning ? Colors.orange
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ble.isConnected ? "Connected" : ble.isScanning ? "Scanning..." : "Connect",
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            // ✅ إصلاح: subtitleColor بدل hardcoded grey[700]
                            color: ble.isConnected ? const Color(0xFF3B6D11) : subtitleColor,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            Text("REAL-TIME ANALYSIS", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text("System Health", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 20),

            // ── Gauges Grid ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
              children: [

                // TDS — teal ممتاز، amber مقبول، red خطر
                GaugeWidget(
                  title: "TDS Level",
                  value: data.tds,
                  maxValue: 1200,
                  displayText: data.tds.toStringAsFixed(0),
                  unit: "PPM",
                  activeColor: _getTdsColor(data.tds, data.temperature),
                  bgColor: gaugeBg,
                ),

                // Purity — أحمر عند 0، أخضر عند 100
                GaugeWidget(
                  title: "Water Purity",
                  value: data.purity,
                  maxValue: 100,
                  displayText: data.purity.toStringAsFixed(0),
                  unit: "%",
                  activeColor: _getPurityColor(data.purity),
                  bgColor: gaugeBg,
                ),

                // Temperature — أزرق للنطاق المثالي
                GaugeWidget(
                  title: "Temperature",
                  value: data.temperature,
                  maxValue: 50,
                  displayText: data.temperature.toStringAsFixed(1),
                  unit: "°C",
                  activeColor: _getTempColor(data.temperature),
                  bgColor: tempGaugeBg,
                ),

                // Quality Grade — A+ أخضر، D أحمر
                GaugeWidget(
                  title: "Quality Score",
                  value: scoreValue,
                  maxValue: 100,
                  displayText: score,
                  unit: "GRADE",
                  activeColor: scoreColor,
                  bgColor: gradeGaugeBg,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── AI Card ──
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE6F1FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, size: 14, color: Color(0xFF185FA5)),
                    SizedBox(width: 6),
                    Text("AI INTELLIGENCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF185FA5), letterSpacing: 0.5)),
                  ]),
                ),
                const SizedBox(height: 12),
                Text("Deep Visual Analysis", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 8),
                Text(
                  "Detect micro-particles and sediment not visible to the naked eye with your camera.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.5),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : () => _runVisualAnalysis(data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF185FA5).withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isAnalyzing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt_outlined, size: 20),
                    label: Text(
                      _isAnalyzing ? "Analyzing Request..." : "Visual Water Analysis",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}