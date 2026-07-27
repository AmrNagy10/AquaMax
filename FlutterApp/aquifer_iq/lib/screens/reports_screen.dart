import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reports_service.dart';
import '../services/mode_service.dart';
import '../models/app_mode.dart';
import '../models/farm_profile.dart';
import '../services/farm_profile_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedIndex = 0;

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? "PM" : "AM";
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final reportsService = context.watch<ReportsService>();
    final history = reportsService.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMode = context.watch<ModeService>().currentMode;
    final cardColor     = isDark ? const Color(0xFF161B22) : Colors.white;
    final bgColor       = isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F7F6);
    // ✅ إصلاح dark mode: textColor و subtitleColor متكيفين
    final textColor     = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[700]!;

    final isAgricultural = currentMode == AppMode.agricultural;
    final appBarTitle = isAgricultural ? "Irrigation Reports" : "Water Reports & AI";
    final emptyTitle = isAgricultural ? "No irrigation reports yet" : "No reports yet";
    final emptySubtitle = isAgricultural ? "Start an Irrigation Scan in the Dashboard." : "Start a Visual Analysis in the Dashboard.";
    final trendsTitle = isAgricultural ? "Irrigation Trends" : "History Trends";
    final trendsCountLabel = isAgricultural ? "Analyses" : "Reports";

    if (history.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(appBarTitle, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        ),
        body: _buildEmptyState(subtitleColor, emptyTitle, emptySubtitle),
      );
    }

    final safeIndex = _selectedIndex >= history.length ? 0 : _selectedIndex;
    final selectedReport = history[safeIndex];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(appBarTitle, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedReportCard(
              selectedReport, safeIndex == 0, isDark, cardColor, textColor, subtitleColor, isAgricultural, history,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(trendsTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                Text("${history.length} $trendsCountLabel", style: TextStyle(fontSize: 14, color: Colors.blue[800], fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text("Tap on any bar to view its full report", style: TextStyle(fontSize: 12, color: subtitleColor)),
            const SizedBox(height: 20),
            _buildInteractiveBarChart(history, safeIndex),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ✅ إصلاح جوهري: بنمرر isDark عشان نحل مشكلة النصوص الغامقة في dark mode
  Widget _buildFormattedAiDetails(List<String> detailPoints, bool isDark) {
    // ✅ textColor متكيف مع dark/light بدل hardcoded Colors.black87
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final configs = [
      _PointConfig(icon: Icons.visibility_outlined,       color: const Color(0xFF185FA5)),
      _PointConfig(icon: Icons.water_drop_outlined,        color: const Color(0xFF185FA5)),
      _PointConfig(icon: Icons.analytics_outlined,         color: const Color(0xFF185FA5)),
      _PointConfig(icon: Icons.health_and_safety_outlined, color: const Color(0xFF639922)),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(detailPoints.length, (i) {
          final config = i < configs.length
              ? configs[i]
              : _PointConfig(icon: Icons.info_outline, color: const Color(0xFF185FA5));
          final text = detailPoints[i];

          final isWarning = i == 3 && (
              text.contains('غير آمن') ||
                  text.contains('ملوث') ||
                  text.contains('لا يُنصح') ||
                  text.contains('خطر')
          );

          final iconColor = isWarning ? Colors.redAccent : config.color;
          final iconData  = isWarning ? Icons.warning_amber_rounded : config.icon;

          // ✅ iconBg متكيف مع dark mode بدل .withOpacity(0.1) اللي بيطلع شفاف جداً
          final iconBg = isDark
              ? iconColor.withOpacity(0.2)
              : iconColor.withOpacity(0.1);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, left: 12),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(iconData, size: 18, color: iconColor),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      // ✅ الإصلاح الأساسي — كان hardcoded Colors.black87
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAgricultureAdvice(double rawTds, double temp, bool isSafeForDrinking, bool isDark) {
    double realTds = rawTds / (1 + 0.02 * (temp - 25));
    String advice;
    String plants;
    IconData agIcon = Icons.eco_outlined;
    Color agColor = const Color(0xFF639922);

    if (realTds <= 500) {
      advice = "مياه ممتازة للري (لا توجد قيود)";
      plants = "الفراولة، الفاصوليا، الجزر، البصل، والتفاح.";
    } else if (realTds <= 1000) {
      advice = "مياه جيدة للري (قيود خفيفة)";
      plants = "الطماطم، الخس، الذرة، الخيار، والبطيخ.";
      agColor = const Color(0xFF3B6D11);
    } else if (realTds <= 2000) {
      advice = "مياه مقبولة للري (تحتاج إدارة جيدة)";
      plants = "القمح، الشعير، الزيتون، النخيل، والقطن.";
      agColor = Colors.orange[800]!;
      agIcon = Icons.local_florist_outlined;
    } else {
      advice = "مياه عالية الملوحة (غير صالحة للزراعة العادية)";
      plants = "بعض أنواع النخيل ونباتات الزينة الملحية فقط.";
      agColor = Colors.redAccent;
      agIcon = Icons.warning_amber_rounded;
    }

    // ✅ إصلاح dark mode: النصوص داخل بكسة الزراعة كانت hardcoded
    final bodyTextColor = isDark ? Colors.white70 : Colors.black87;
    final subTextColor  = isDark ? Colors.white54 : Colors.grey[800]!;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: agColor.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: agColor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(agIcon, color: agColor, size: 22),
          const SizedBox(width: 8),
          Text(
            isSafeForDrinking ? "إمكانية الاستخدام الزراعي" : "أفضل استغلال بديل (الري)",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: agColor),
          ),
        ]),
        const SizedBox(height: 10),
        Text(advice, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: bodyTextColor)),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            "🌱 النباتات المناسبة: $plants",
            style: TextStyle(fontSize: 13, height: 1.5, color: subTextColor, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _buildSelectedReportCard(
      WaterAnalysisReport report, bool isLatest, bool isDark,
      Color cardColor, Color textColor, Color subtitleColor,
      bool isAgricultural, List<WaterAnalysisReport> history,

      ) {
    final aiResult = report.aiResult;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: aiResult.isSafe ? const Color(0xFFC0DD97) : Colors.orange.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    aiResult.isSafe
                        ? Icons.check_circle
                        : Icons.warning_rounded,
                    color: aiResult.isSafe
                        ? const Color(0xFF639922)
                        : Colors.orange[800],
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isLatest
                          ? (isAgricultural
                          ? "Latest Irrigation Analysis"
                          : "Latest Analysis")
                          : "Historical Record",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(report.date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey[800],
                ),
              ),
            ),
          ],
        ),

        const Divider(height: 30),

        // ✅ بنمرر isDark هنا
        _buildFormattedAiDetails(aiResult.detailPoints, isDark),

        // ── توصية AI ──
        if (aiResult.recommendation.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: aiResult.isSafe
                  ? const Color(0xFF639922).withOpacity(0.08)
                  : Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                "💡 ${aiResult.recommendation}",
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, height: 1.5,
                  color: aiResult.isSafe ? const Color(0xFF3B6D11) : Colors.orange[800],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(isAgricultural ? "Salinity" : "TDS",    "${report.tds.toStringAsFixed(0)} PPM", subtitleColor),
              _buildMiniStat(isAgricultural ? "Moisture" : "Purity", "${report.purity.toStringAsFixed(0)}%", subtitleColor),
              _buildMiniStat("Temp",   "${report.temperature.toStringAsFixed(1)}°C", subtitleColor),
            ],
          ),
        ),

        // ✅ Agriculture advice only shown in Agricultural mode
        if (isAgricultural) ...[
          _buildAgricultureAdvice(report.tds, report.temperature, aiResult.isSafe, isDark),
          // Historical Salt Trend Indicator
          _buildSaltTrendIndicator(report.tds, history, isDark),
          // Leaching Recommendation
          _buildLeachingCard(report.tds, report.purity, isDark),
        ],
      ]),
    );
  }

  Widget _buildMiniStat(String label, String value, Color subtitleColor) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 11, color: subtitleColor, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF185FA5))),
    ]);
  }

  // ─── Historical Salt Trend Indicator ───
  Widget _buildSaltTrendIndicator(double currentTds, List<WaterAnalysisReport> history, bool isDark) {
    final farmProfile = context.watch<FarmProfileService>().profileOrDefault;
    final recentTds = history
        .where((r) => r.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .map((r) => r.tds)
        .toList();

    if (recentTds.isEmpty || recentTds.last != currentTds) {
      recentTds.add(currentTds);
    }

    recentTds.add(currentTds);
    final trend = farmProfile.calculateSaltTrend(recentTds);

    if (recentTds.length < 3) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF64B5F6).withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF64B5F6).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: const Color(0xFF64B5F6), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Not enough data for salt trend — Keep scanning to build history',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: trend.color.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: trend.color.withOpacity(0.3)),
      ),
      child: Row(
          children: [
          Icon(trend.icon, color: trend.color, size: 22),
      const SizedBox(width: 10),
      Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
            '7-Day Salt Trend',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            trend.label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: trend.color),
          ),
          const SizedBox(height: 3),
          Text(
              'Avg: ${(recentTds.reduce((a, b) => a + b) / recentTds.length).toStringAsFixed(0)} PPM | Current: ${currentTds.toStringAsFixed(0)} PPM',
      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
    ),
    ],
    ),
    ),
    ],
    ),
    );
  }

  // ─── Leaching Recommendation Card ───
  Widget _buildLeachingCard(double tds, double soilMoisture, bool isDark) {
    final farmProfile = context.watch<FarmProfileService>().profileOrDefault;
    final leaching = farmProfile.getLeachingRecommendation(tds, soilMoisture: soilMoisture);

    if (!leaching.needsLeaching) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF639922).withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF639922).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF639922), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                leaching.message,
                style: TextStyle(fontSize: 12, color: const Color(0xFF639922), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: leaching.color.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: leaching.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, color: leaching.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  leaching.message,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: leaching.color),
                ),
              ),
            ],
          ),
          if (leaching.specificAdvice != null) ...[
            const SizedBox(height: 8),
            Text(
              leaching.specificAdvice!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractiveBarChart(List<WaterAnalysisReport> history, int selectedIndex) {
    return SizedBox(
      height: 130,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(history.length, (i) {
            int actualIndex = history.length - 1 - i;
            final report = history[actualIndex];
            final isSelected = actualIndex == selectedIndex;
            double heightValue = (report.purity / 100.0) * 100;

            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = actualIndex),
              child: Container(
                width: 22,
                height: heightValue.clamp(10.0, 100.0) + (isSelected ? 10.0 : 0.0),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF185FA5)
                      : const Color(0xFF185FA5).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF185FA5).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color subtitleColor, String title, String subtitle) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.analytics_outlined, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 16, color: subtitleColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      ]),
    );
  }
}

class _PointConfig {
  final IconData icon;
  final Color color;
  const _PointConfig({required this.icon, required this.color});
}