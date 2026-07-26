import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/reports_service.dart';
import '../services/mode_service.dart';
import '../models/app_mode.dart';
import '../screens/report_detail_screen.dart';
import '../screens/compare_reports_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;

  void _onLongPress(int index) {
    if (_isSelectionMode && _selectedIndices.contains(index)) {
      // لو كان محدد وضغط تاني عليه — ألغي التحديد
      setState(() {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _isSelectionMode = false;
        }
      });
      return;
    }

    // لو لسه ما وصلناش 2 — نضيفه
    if (_selectedIndices.length < 2) {
      setState(() {
        _isSelectionMode = true;
        _selectedIndices.add(index);
      });
    }
  }

  void _onTap(int index, WaterAnalysisReport report) {
    if (_isSelectionMode) {
      // لو في selection mode — نحدد بدل ما نفتحه
      _onLongPress(index);
      return;
    }
    // عادي — نفتح التفاصيل
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsService = context.watch<ReportsService>();
    final history = reportsService.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: _isSelectionMode
            ? Text("Select 2 to Compare (${_selectedIndices.length}/2)",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor))
            : const Text("Scan History Log", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        leading: _isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _isSelectionMode = false;
            _selectedIndices.clear();
          }),
        )
            : null,
        actions: _isSelectionMode && _selectedIndices.length == 2
            ? [
          TextButton.icon(
            onPressed: () {
              final indices = _selectedIndices.toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompareReportsScreen(
                    report1: history[indices[0]],
                    report2: history[indices[1]],
                  ),
                ),
              ).then((_) => setState(() {
                _isSelectionMode = false;
                _selectedIndices.clear();
              }));
            },
            icon: const Icon(Icons.compare_arrows, size: 20),
            label: const Text("Compare"),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF185FA5)),
          ),
        ]
            : null,
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Last 7 Days"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF185FA5)),
                      foregroundColor: const Color(0xFF185FA5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Consumer<ModeService>(
                      builder: (context, modeService, child) => Text(
                        modeService.currentMode == AppMode.agricultural ? "Crop Type" : "Filter",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selection hint
          if (_isSelectionMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF185FA5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF185FA5).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: const Color(0xFF185FA5), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedIndices.length == 2
                          ? "Tap Compare to see the results"
                          : "Tap another report to compare",
                      style: TextStyle(fontSize: 13, color: const Color(0xFF185FA5), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          if (_isSelectionMode) const SizedBox(height: 8),

          // History List
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text("No history logs yet"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final report = history[index];
                final isSelected = _selectedIndices.contains(index);
                return GestureDetector(
                  onLongPress: () => _onLongPress(index),
                  onTap: () => _onTap(index, report),
                  child: _buildCard(context, report, index, isSelected, isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      WaterAnalysisReport report,
      int index,
      bool isSelected,
      bool isDark,
      ) {
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[600]!;

    Color scoreColor = const Color(0xFF639922);
    if (report.score < 40) scoreColor = const Color(0xFFE24B4A);
    else if (report.score < 75) scoreColor = const Color(0xFFEF9F27);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF185FA5), width: 2.5)
              : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF185FA5).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Selection indicator
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF185FA5) : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF185FA5) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            Expanded(
              child: _isSelectionMode
                  ? _buildSelectionCard(report, textColor, subtitleColor, scoreColor)
                  : _buildSlidableCard(report, index, textColor, subtitleColor, scoreColor, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Card عادي (بدون selection) — فيه Slidable
  Widget _buildSlidableCard(
      WaterAnalysisReport report,
      int index,
      Color textColor,
      Color subtitleColor,
      Color scoreColor,
      bool isDark,
      ) {
    return Slidable(
      key: ValueKey(report.date),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              context.read<ReportsService>().deleteReport(index);
            },
            backgroundColor: const Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          SlidableAction(
            onPressed: (context) {
              // TODO: Implement PDF Export
            },
            backgroundColor: const Color(0xFF21B7CA),
            foregroundColor: Colors.white,
            icon: Icons.picture_as_pdf,
            label: 'PDF',
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(report: report),
              ),
            );
          },
          onLongPress: () => _onLongPress(
            context.read<ReportsService>().history.indexOf(report),
          ),
          splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
          highlightColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(report.date),
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                ),
                Text(
                  DateFormat('hh:mm a').format(report.date),
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      report.score.toStringAsFixed(0),
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<ModeService>(
                      builder: (context, modeService, child) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            modeService.currentMode == AppMode.agricultural
                                ? "Irrigation Data"
                                : "General Water",
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
                          ),
                          Text(
                            modeService.currentMode == AppMode.agricultural
                                ? "Field Log"
                                : "Analysis Log",
                            style: TextStyle(fontSize: 12, color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card في الـ selection mode
  Widget _buildSelectionCard(
      WaterAnalysisReport report,
      Color textColor,
      Color subtitleColor,
      Color scoreColor,
      ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMM dd, yyyy').format(report.date),
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
          ),
          Text(
            DateFormat('hh:mm a').format(report.date),
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
        ],
      ),
      trailing: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scoreColor.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: scoreColor, width: 2),
        ),
        child: Center(
          child: Text(
            report.score.toStringAsFixed(0),
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
