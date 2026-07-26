import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';
import '../services/ai_service.dart';
import '../services/Scoring_Engine.dart';
import '../services/ble_service.dart';

class WaterAnalysisReport {
  final DateTime date;
  final double tds;
  final double purity;
  final double temperature;
  final double ph;
  final double score;
  final File imageFile;
  final AiAnalysisResult aiResult;

  WaterAnalysisReport({
    required this.date,
    required this.tds,
    required this.purity,
    required this.temperature,
    required this.ph,
    required this.score,
    required this.imageFile,
    required this.aiResult,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'tds': tds,
    'purity': purity,
    'temperature': temperature,
    'ph': ph,
    'score': score,
    'imagePath': imageFile.path,
    'aiResult': aiResult.toJson(),
  };

  factory WaterAnalysisReport.fromJson(Map<String, dynamic> json) => WaterAnalysisReport(
    date: DateTime.parse(json['date']),
    tds: (json['tds'] as num).toDouble(),
    purity: (json['purity'] as num).toDouble(),
    temperature: (json['temperature'] as num).toDouble(),
    ph: (json['ph'] as num?)?.toDouble() ?? 7.0,
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
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

  // chartData بيرجع دايماً بيانات فعلية من التاريخ
  List<double> get chartData {
    if (_history.isEmpty) return [];
    return _history.take(10).map((r) => r.score > 0 ? r.score : r.purity).toList().reversed.toList();
  }

  // دالة حذف كل التقارير
  Future<void> clearAll() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reports_history');
    notifyListeners();
  }

  // دالة حذف تقرير محدد
  Future<void> deleteReport(int index) async {
    if (index < 0 || index >= _history.length) return;
    _history.removeAt(index);
    _saveToDisk();
    notifyListeners();
  }

  // دالة إعادة حساب Score لتقرير قديم
  double recalculateScore(WaterAnalysisReport report) {
    final sensorData = SensorData(
      tds: report.tds,
      purity: report.purity,
      temperature: report.temperature,
      ph: report.ph,
    );
    return ScoringEngine.calculateScore(sensorData).numericScore;
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

        // إصلاح: لو أي تقرير الـ score بتاعه = 0، نعيد حسابه
        bool needsResave = false;
        for (int i = 0; i < _history.length; i++) {
          if (_history[i].score == 0 && _history[i].tds > 0) {
            final newScore = recalculateScore(_history[i]);
            _history[i] = WaterAnalysisReport(
              date: _history[i].date,
              tds: _history[i].tds,
              purity: _history[i].purity,
              temperature: _history[i].temperature,
              ph: _history[i].ph,
              score: newScore,
              imageFile: _history[i].imageFile,
              aiResult: _history[i].aiResult,
            );
            needsResave = true;
          }
        }
        if (needsResave) {
          await _saveToDisk();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading reports: $e");
      _history = [];
    }
  }
}
