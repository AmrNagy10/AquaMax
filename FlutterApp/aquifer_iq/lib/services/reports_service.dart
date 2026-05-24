import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class WaterAnalysisReport {
  final DateTime date;
  final double tds;
  final double purity;
  final double temperature;
  final File imageFile;
  final AiAnalysisResult aiResult;

  WaterAnalysisReport({
    required this.date,
    required this.tds,
    required this.purity,
    required this.temperature,
    required this.imageFile,
    required this.aiResult,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'tds': tds,
    'purity': purity,
    'temperature': temperature,
    'imagePath': imageFile.path,
    'aiResult': aiResult.toJson(),
  };

  factory WaterAnalysisReport.fromJson(Map<String, dynamic> json) => WaterAnalysisReport(
    date: DateTime.parse(json['date']),
    tds: (json['tds'] as num).toDouble(),
    purity: (json['purity'] as num).toDouble(),
    temperature: (json['temperature'] as num).toDouble(),
    imageFile: File(json['imagePath']),
    aiResult: AiAnalysisResult.fromJson(json['aiResult']),
  );
}

class ReportsService extends ChangeNotifier {
  List<WaterAnalysisReport> _history = [];

  List<WaterAnalysisReport> get history => List.unmodifiable(_history);

  ReportsService() {
    loadReports();
  }

  void addReport(WaterAnalysisReport report) {
    _history.insert(0, report);
    _saveToDisk();
    notifyListeners();
  }

  WaterAnalysisReport? get lastReport => _history.isEmpty ? null : _history.first;

  // ✅ إصلاح: chartData بيرجع دايماً بيانات فعلية من التاريخ
  List<double> get chartData {
    if (_history.isEmpty) return [];
    return _history.take(10).map((r) => r.purity).toList().reversed.toList();
  }

  // ✅ جديد: دالة حذف كل التقارير مطلوبة من صفحة الـ Settings
  Future<void> clearAll() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reports_history');
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(_history.map((item) => item.toJson()).toList());
      await prefs.setString('reports_history', encodedData);
    } catch (e) {
      debugPrint("Error saving reports: $e");
    }
  }

  Future<void> loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encodedData = prefs.getString('reports_history');
      if (encodedData != null) {
        final List<dynamic> decodedData = jsonDecode(encodedData);
        _history = decodedData
            .map((item) => WaterAnalysisReport.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading reports: $e");
      // ✅ إصلاح: لو في خطأ في التحميل، نمسح البيانات الفاسدة بدل ما التطبيق يعطل
      _history = [];
    }
  }
}