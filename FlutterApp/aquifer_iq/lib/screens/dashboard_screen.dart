import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../screens/history_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../services/ble_service.dart';
import '../services/ai_service.dart';
import '../services/mode_service.dart';
import '../services/reports_service.dart';
import '../services/Scoring_Engine.dart';
import '../models/app_mode.dart';
import '../models/score_result.dart';
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

  Future<void> _runVisualAnalysis(SensorData data) async {
    final ble = context.read<BleService>();
    try {
      // 1) تجميد القراءات قبل فتح الكاميرا
      ble.startCapture();

      // 2) فتح الكاميرا والتقاط الصورة
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      // 3) إرجاع تحديث القراءات فوراً (سواء التقط صورة أو لا)
      ble.endCapture();

      if (image == null) return;

      // 4) استخدام الـ snapshot اللي اتجمد قبل الكاميرا
      final snapshot = ble.sensorData;
      setState(() => _isAnalyzing = true);

      final result = await _aiService.analyzeWaterImage(
        imageFile: File(image.path),
        tds: snapshot.tds,
        purity: snapshot.purity,
        temperature: snapshot.temperature,
        ph: snapshot.ph,
        mode: context.read<ModeService>().currentMode,
      );
      if (!mounted) return;

      final scoreRes = ScoringEngine.calculateScore(snapshot);

      context.read<ReportsService>().addReport(WaterAnalysisReport(
        date: DateTime.now(),
        tds: snapshot.tds,
        purity: snapshot.purity,
        temperature: snapshot.temperature,
        ph: snapshot.ph,
        score: scoreRes.numericScore,
        imageFile: File(image.path),
        aiResult: result,
      ));
      setState(() => _currentIndex = 2);
    } catch (e) {
      // حتى في حالة الخطأ نرجع تحديث القراءات
      ble.endCapture();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء التحليل: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      ble.endCapture(); // ضمان إن القراءات ترجع تتحدث في كل الحالات
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble  = context.watch<BleService>();
    final data = ble.sensorData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final modeService = context.watch<ModeService>();

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
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.speed_rounded), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "History"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Reports"),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded),  label: "Settings"),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardBody(data, ble, isDark),
          const HistoryScreen(),
          const ReportsScreen(),
          const SettingsScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboardBody(SensorData data, BleService ble, bool isDark) {
    final modeService = context.watch<ModeService>();
    final currentMode = modeService.currentMode;
    final labels = ScoringEngine.getLabels(currentMode);
    final bool connected = ble.isConnected;

    final cardColor     = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor     = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;

    final WaterScoreResult scoreResult = ScoringEngine.calculateScore(data, mode: currentMode);
    final Color gaugeBg = isDark ? const Color(0xFF161B22) : Colors.white;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: Color(0xFF185FA5), shape: BoxShape.circle),
                      child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text("AquaMax", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textColor)),
                  ]),
                  Row(children: [
                    // Mode toggle button
                    GestureDetector(
                      onTap: modeService.toggleMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: currentMode == AppMode.agricultural
                              ? const Color(0xFF639922)
                              : const Color(0xFF185FA5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentMode == AppMode.agricultural
                                  ? Icons.eco_rounded
                                  : Icons.home_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              currentMode.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(ble.isSimulationMode ? Icons.bug_report : Icons.bug_report_outlined, color: ble.isSimulationMode ? Colors.orange : subtitleColor),
                      onPressed: ble.toggleSimulationMode,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: ble.isConnected ? ble.disconnect : ble.startScan,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ble.isConnected ? const Color(0xFFC0DD97) : Colors.grey.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ble.isConnected ? const Color(0xFF639922) : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            ble.isConnected ? (ble.isSimulationMode ? "Sim" : "Connected") : "Connect",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ble.isConnected ? const Color(0xFF3B6D11) : subtitleColor),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            Row(
              children: [
                Text(currentMode == AppMode.agricultural ? "FIELD MONITORING" : "REAL-TIME ANALYSIS", style: TextStyle(fontSize: 12, color: subtitleColor, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentMode == AppMode.agricultural
                        ? const Color(0xFF639922).withOpacity(0.15)
                        : const Color(0xFF185FA5).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: currentMode == AppMode.agricultural
                          ? const Color(0xFF639922)
                          : const Color(0xFF185FA5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentMode == AppMode.agricultural
                            ? Icons.eco_rounded
                            : Icons.home_rounded,
                        size: 14,
                        color: currentMode == AppMode.agricultural
                            ? const Color(0xFF639922)
                            : const Color(0xFF185FA5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentMode.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: currentMode == AppMode.agricultural
                              ? const Color(0xFF639922)
                              : const Color(0xFF185FA5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(labels['dashboardTitle']!, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scoreResult.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scoreResult.statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(labels['scoreLabel']! + " Score", style: TextStyle(color: subtitleColor, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(scoreResult.message, style: TextStyle(color: scoreResult.statusColor, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: scoreResult.statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          scoreResult.grade,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: scoreResult.numericScore / 100),
                    builder: (context, value, child) {
                      return Column(
                        children: [
                          LinearProgressIndicator(
                            value: value,
                            backgroundColor: scoreResult.statusColor.withOpacity(0.2),
                            color: scoreResult.statusColor,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("0", style: TextStyle(color: subtitleColor)),
                              Text("${(value * 100).toStringAsFixed(1)}%", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                              Text("100", style: TextStyle(color: subtitleColor)),
                            ],
                          )
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
              children: [
                GaugeWidget(
                  title: currentMode == AppMode.agricultural ? "Salinity (TDS)" : "TDS Level",
                  subtitle: !connected
                      ? "--" : currentMode == AppMode.agricultural
                      ? (data.tds <= 300 ? "Excellent" : data.tds <= 600 ? "Good" : data.tds <= 900 ? "Caution" : "Critical")
                      : (data.tds <= 300 ? "Ideal" : data.tds <= 600 ? "Acceptable" : data.tds <= 900 ? "High" : "Unsafe"),
                  value: data.tds,
                  maxValue: 1200,
                  displayText: data.tds.toStringAsFixed(0),
                  unit: labels['tdsUnit']!,
                  activeColor: ScoringEngine.getTdsColor(data.tds),
                  bgColor: gaugeBg,
                ),
                GaugeWidget(
                  title: currentMode == AppMode.agricultural ? "Soil Moisture" : "Water Purity",
                  subtitle: !connected
                      ? "--": currentMode == AppMode.agricultural
                      ? (data.purity >= 90 ? "Optimal" : data.purity >= 70 ? "Adequate" : "Low")
                      : (data.purity >= 90 ? "Crystal Clear" : data.purity >= 70 ? "Acceptable" : "Needs Filter"),
                  value: data.purity,
                  maxValue: 100,
                  displayText: data.purity.toStringAsFixed(0),
                  unit: labels['purityUnit']!,
                  activeColor: ScoringEngine.getPurityColor(data.purity),
                  bgColor: gaugeBg,
                ),
                GaugeWidget(
                  title: "pH Level",
                  subtitle: !connected
                      ? "--": currentMode == AppMode.agricultural
                      ? (data.ph >= 6.0 && data.ph <= 8.5 ? "Ideal for Crops" : "Check Soil Impact")
                      : (data.ph >= 6.5 && data.ph <= 8.5 ? "Safe for Drinking" : "Outside WHO Range"),
                  value: data.ph,
                  maxValue: 14,
                  displayText: data.ph.toStringAsFixed(1),
                  unit: labels['phUnit']!,
                  activeColor: ScoringEngine.getPhColor(data.ph),
                  bgColor: gaugeBg,
                ),
                GaugeWidget(
                  title: "Temperature",

                  subtitle: !connected
                      ? "--": currentMode == AppMode.agricultural
                      ? (data.temperature >= 10 && data.temperature <= 30 ? "Safe for Irrigation" : "Extreme for Crops")
                      : (data.temperature >= 15 && data.temperature <= 25 ? "Ideal Range" : "Check Quality"),
                  value: data.temperature,
                  maxValue: 50,
                  displayText: data.temperature.toStringAsFixed(1),
                  unit: labels['tempUnit']!,
                  activeColor: ScoringEngine.getTemperatureColor(data.temperature),
                  bgColor: gaugeBg,
                ),
              ],
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : () => _runVisualAnalysis(data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF185FA5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: _isAnalyzing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isAnalyzing ? "Analyzing..." : "Run AI ${currentMode == AppMode.agricultural ? 'Irrigation' : 'Visual'} Scan",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
