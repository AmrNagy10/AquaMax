import 'package:flutter/material.dart';
import '../models/score_result.dart';
import 'ble_service.dart';

class ScoringEngine {
  // New Weights: TDS(40%), Purity(30%), pH(20%), Temp(10%)
  static const double tdsWeight = 0.40;
  static const double purityWeight = 0.30;
  static const double phWeight = 0.20;
  static const double tempWeight = 0.10;

  static WaterScoreResult calculateScore(SensorData data, {double aiMultiplier = 1.0}) {
    if (data.tds == 0 && data.purity == 0 && data.temperature == 0 && data.ph == 0) {
      return WaterScoreResult(
        numericScore: 0,
        grade: "--",
        statusColor: Colors.grey,
        message: "Waiting for Data...",
        tips: ["Connect device or start simulation"],
      );
    }

    // 1. TDS Score (Ideal < 150)
    double tdsScore = (data.tds <= 150) ? 100 : (100 - ((data.tds - 150) / (1200 - 150) * 100)).clamp(0.0, 100.0);

    // 2. Purity Score (0-100)
    double purityScore = data.purity.clamp(0.0, 100.0);

    // 3. pH Score (Ideal 6.5 - 8.5)
    double phScore = 0;
    if (data.ph >= 6.5 && data.ph <= 8.5) {
      phScore = 100;
    } else if (data.ph < 4.0 || data.ph > 11.0) {
      phScore = 0;
    } else {
      if (data.ph < 6.5) {
        phScore = ((data.ph - 4.0) / (6.5 - 4.0)) * 100;
      } else {
        phScore = (1 - (data.ph - 8.5) / (11.0 - 8.5)) * 100;
      }
    }

    // 4. Temp Score (Ideal 10-25)
    double tempScore = (data.temperature >= 10 && data.temperature <= 25) ? 100 :
    (data.temperature < 0 || data.temperature > 50) ? 0 : 50; // Simplified

    double finalScore = (tdsScore * tdsWeight) +
        (purityScore * purityWeight) +
        (phScore * phWeight) +
        (tempScore * tempWeight);

    finalScore = (finalScore * aiMultiplier).clamp(0.0, 100.0);

    String grade;
    Color color;
    String message;
    List<String> tips = [];

    if (finalScore >= 90) {
      grade = "A+"; color = const Color(0xFF2E7D32); message = "Excellent Quality";
      tips = ["Perfect pH balance", "Safe for all uses"];
    } else if (finalScore >= 75) {
      grade = "A"; color = const Color(0xFF639922); message = "Good Quality";
      tips = ["Healthy mineral levels", "Safe for drinking"];
    } else if (finalScore >= 60) {
      grade = "B"; color = const Color(0xFFEF9F27); message = "Acceptable Quality";
      tips = ["Slightly off balance", "Boil if drinking"];
    } else if (finalScore >= 40) {
      grade = "C"; color = const Color(0xFFD85A30); message = "Poor Quality";
      tips = ["Acidic/Alkaline issues", "Unsafe for drinking"];
    } else {
      grade = "D"; color = const Color(0xFFE24B4A); message = "Hazardous";
      tips = ["Chemical imbalance", "Harmful to plants/humans"];
    }

    return WaterScoreResult(
      numericScore: finalScore,
      grade: grade,
      statusColor: color,
      message: message,
      tips: tips,
    );
  }

  // pH Color Helper
  static Color getPhColor(double ph) {
    if (ph < 4.0) return Colors.red;
    if (ph < 6.5) return Colors.orange;
    if (ph <= 8.5) return Colors.green;
    if (ph <= 10.0) return Colors.blue;
    return Colors.purple;
  }

  static Color getTdsColor(double tds) {
    if (tds <= 300) return const Color(0xFF2ECC71);   // ممتاز
    if (tds <= 600) return const Color(0xFF27AE60);   // جيد
    if (tds <= 900) return const Color(0xFFF39C12);   // مرتفع - تحذير
    return const Color(0xFFE74C3C);                   // مرتفع جدًا - خطر
  }

  // 🟢 لون النقاء: كلما قلت النسبة كلما زاد الخطر (عكس TDS)
  static Color getPurityColor(double purity) {
    if (purity >= 90) return const Color(0xFF2ECC71);  // ممتاز
    if (purity >= 70) return const Color(0xFF27AE60);  // جيد
    if (purity >= 50) return const Color(0xFFF39C12);  // منخفض - تحذير
    return const Color(0xFFE74C3C);                    // منخفض جدًا - خطر
  }

  // 🌡️ لون الحرارة: له مدى طبيعي، والخطر يظهر في الاتجاهين (ارتفاع أو انخفاض)
  static Color getTemperatureColor(double temp) {
    if (temp >= 15 && temp <= 25) return const Color(0xFF3498DB);        // طبيعي
    if ((temp >= 10 && temp < 15) || (temp > 25 && temp <= 30)) {
      return const Color(0xFFF39C12);                                    // تحذير (منخفض أو مرتفع نسبيًا)
    }
    return const Color(0xFFE74C3C);                                      // خطر (منخفض جدًا أو مرتفع جدًا)
  }

}
