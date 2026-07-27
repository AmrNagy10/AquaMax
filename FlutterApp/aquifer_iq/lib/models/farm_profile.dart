import 'package:flutter/material.dart';

/// تصنيف تحمّل المحصول للملوحة، مبني على تصنيف FAO / Maas-Hoffman التقريبي.
/// ملحوظة مهمة: القيم دي تقريبية لأغراض الـ prototype، ومحتاجة تتراجع مع
/// خبير ري/تربة قبل أي استخدام إنتاجي فعلي لاتخاذ قرارات حقيقية.
enum SalinityTolerance { sensitive, moderatelySensitive, moderatelyTolerant, tolerant }

enum CropType {
  tomato,
  potato,
  corn,
  rice,
  wheat,
  cotton,
  barley,
  datePalm,
  olive,
  citrus,
  strawberry,
  other,
}

extension CropTypeX on CropType {
  String get label {
    switch (this) {
      case CropType.tomato: return 'Tomato';
      case CropType.potato: return 'Potato';
      case CropType.corn: return 'Corn';
      case CropType.rice: return 'Rice';
      case CropType.wheat: return 'Wheat';
      case CropType.cotton: return 'Cotton';
      case CropType.barley: return 'Barley';
      case CropType.datePalm: return 'Date palm';
      case CropType.olive: return 'Olive';
      case CropType.citrus: return 'Citrus';
      case CropType.strawberry: return 'Strawberry';
      case CropType.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case CropType.tomato: return Icons.local_florist_rounded;
      case CropType.potato: return Icons.grass_rounded;
      case CropType.corn: return Icons.agriculture_rounded;
      case CropType.rice: return Icons.grain_rounded;
      case CropType.wheat: return Icons.grain_rounded;
      case CropType.cotton: return Icons.cloud_rounded;
      case CropType.barley: return Icons.grain_rounded;
      case CropType.datePalm: return Icons.park_rounded;
      case CropType.olive: return Icons.eco_rounded;
      case CropType.citrus: return Icons.circle_rounded;
      case CropType.strawberry: return Icons.favorite_rounded;
      case CropType.other: return Icons.more_horiz_rounded;
    }
  }

  SalinityTolerance get tolerance => CropSalinityData.tolerance[this]!;
}

enum SoilType { sandy, loamy, clay }

extension SoilTypeX on SoilType {
  String get label {
    switch (this) {
      case SoilType.sandy: return 'Sandy';
      case SoilType.loamy: return 'Loamy';
      case SoilType.clay: return 'Clay';
    }
  }

  /// وصف بسيط بيساعد مزارع مش عارف المصطلح التقني يتعرف على أرضه.
  String get description {
    switch (this) {
      case SoilType.sandy: return 'Water drains fast, doesn\'t hold shape';
      case SoilType.loamy: return 'Dark, crumbly, holds shape loosely';
      case SoilType.clay: return 'Holds water, cracks when dry';
    }
  }

  IconData get icon {
    switch (this) {
      case SoilType.sandy: return Icons.beach_access_rounded;
      case SoilType.loamy: return Icons.grain_rounded;
      case SoilType.clay: return Icons.crop_square_rounded;
    }
  }

  /// معامل امتصاص الملح — تربة رملية بتصرّف أسرع، طينية بتحتفظ أكتر.
  double get saltRetentionFactor {
    switch (this) {
      case SoilType.sandy: return 0.6;   // بتنزل الملح بسهولة
      case SoilType.loamy: return 0.8;   // متوسطة
      case SoilType.clay:  return 1.0;   // بتحتفظ بالملح
    }
  }

  /// نسبة الـ moisture اللي تحتها التربة بتزيد الـ salt stress بسبب قلة الـ leaching.
  double get moistureThresholdForLeaching {
    switch (this) {
      case SoilType.sandy: return 0.35;  // رملية بتحتاج moisture أقل عشان الـ drainage كويس
      case SoilType.loamy: return 0.45;
      case SoilType.clay:  return 0.55;  // طينية محتاجة moisture أعلى عشان salt يتحرك
    }
  }
}

class CropSalinityData {
  static const Map<CropType, SalinityTolerance> tolerance = {
    CropType.strawberry: SalinityTolerance.sensitive,
    CropType.rice:       SalinityTolerance.sensitive,
    CropType.citrus:     SalinityTolerance.sensitive,
    CropType.tomato:     SalinityTolerance.moderatelySensitive,
    CropType.potato:     SalinityTolerance.moderatelySensitive,
    CropType.corn:       SalinityTolerance.moderatelySensitive,
    CropType.other:      SalinityTolerance.moderatelySensitive, // افتراضي محافظ
    CropType.wheat:      SalinityTolerance.moderatelyTolerant,
    CropType.olive:      SalinityTolerance.tolerant,
    CropType.cotton:     SalinityTolerance.tolerant,
    CropType.barley:     SalinityTolerance.tolerant,
    CropType.datePalm:   SalinityTolerance.tolerant,
  };

  /// عتبات TDS (PPM) لكل فئة تحمّل — بديل عن العتبة الثابتة الواحدة
  /// اللي كانت مستخدمة قبل كده لكل المحاصيل بنفس الطريقة.
  static const Map<SalinityTolerance, ({double excellent, double acceptable, double max})> thresholds = {
    SalinityTolerance.sensitive:           (excellent: 200, acceptable: 500,  max: 900),
    SalinityTolerance.moderatelySensitive: (excellent: 300, acceptable: 700,  max: 1200),
    SalinityTolerance.moderatelyTolerant:  (excellent: 500, acceptable: 1000, max: 1800),
    SalinityTolerance.tolerant:            (excellent: 800, acceptable: 1500, max: 2500),
  };
}

/// مؤشر تراكم الملح في التربة على المدى الطويل — مقصودًا منفصل عن الـ
/// numeric score (اللي بيجاوب "المياه كويسة دلوقتي؟"). المؤشر ده بيجاوب
/// سؤال مختلف تمامًا: "هل ده هيسبب مشكلة تراكمية بعد مواسم؟"
enum SaltAccumulationRisk { low, medium, high }

extension SaltAccumulationRiskX on SaltAccumulationRisk {
  String get label {
    switch (this) {
      case SaltAccumulationRisk.low: return 'Low salt accumulation risk';
      case SaltAccumulationRisk.medium: return 'Medium salt accumulation risk';
      case SaltAccumulationRisk.high: return 'High salt accumulation risk';
    }
  }

  Color get color {
    switch (this) {
      case SaltAccumulationRisk.low: return const Color(0xFF639922);
      case SaltAccumulationRisk.medium: return const Color(0xFFEF9F27);
      case SaltAccumulationRisk.high: return const Color(0xFFE24B4A);
    }
  }

  /// أيقونة معبرة عن مستوى الخطر
  IconData get icon {
    switch (this) {
      case SaltAccumulationRisk.low: return Icons.check_circle_outline_rounded;
      case SaltAccumulationRisk.medium: return Icons.warning_amber_rounded;
      case SaltAccumulationRisk.high: return Icons.dangerous_rounded;
    }
  }
}

/// مؤشر تراكم الملح التاريخي (7 أيام)
enum HistoricalSaltTrend { declining, stable, rising, critical }

extension HistoricalSaltTrendX on HistoricalSaltTrend {
  String get label {
    switch (this) {
      case HistoricalSaltTrend.declining: return 'Salt levels declining';
      case HistoricalSaltTrend.stable: return 'Salt levels stable';
      case HistoricalSaltTrend.rising: return 'Salt levels rising — Monitor closely';
      case HistoricalSaltTrend.critical: return 'Salt levels critical — Immediate action needed';
    }
  }

  Color get color {
    switch (this) {
      case HistoricalSaltTrend.declining: return const Color(0xFF639922);
      case HistoricalSaltTrend.stable: return const Color(0xFF64B5F6);
      case HistoricalSaltTrend.rising: return const Color(0xFFEF9F27);
      case HistoricalSaltTrend.critical: return const Color(0xFFE24B4A);
    }
  }

  IconData get icon {
    switch (this) {
      case HistoricalSaltTrend.declining: return Icons.trending_down_rounded;
      case HistoricalSaltTrend.stable: return Icons.trending_flat_rounded;
      case HistoricalSaltTrend.rising: return Icons.trending_up_rounded;
      case HistoricalSaltTrend.critical: return Icons.crisis_alert_rounded;
    }
  }
}

/// نتيجة فحص الـ TDS ضد عتبة الـ crop الحالي
enum TdsThresholdStatus { excellent, acceptable, warning, critical }

extension TdsThresholdStatusX on TdsThresholdStatus {
  String get label {
    switch (this) {
      case TdsThresholdStatus.excellent: return 'Excellent';
      case TdsThresholdStatus.acceptable: return 'Acceptable';
      case TdsThresholdStatus.warning: return 'Warning: Above acceptable limit';
      case TdsThresholdStatus.critical: return 'Critical: Exceeds maximum safe level';
    }
  }

  Color get color {
    switch (this) {
      case TdsThresholdStatus.excellent: return const Color(0xFF639922);
      case TdsThresholdStatus.acceptable: return const Color(0xFF64B5F6);
      case TdsThresholdStatus.warning: return const Color(0xFFEF9F27);
      case TdsThresholdStatus.critical: return const Color(0xFFE24B4A);
    }
  }

  IconData get icon {
    switch (this) {
      case TdsThresholdStatus.excellent: return Icons.check_circle_rounded;
      case TdsThresholdStatus.acceptable: return Icons.info_outline_rounded;
      case TdsThresholdStatus.warning: return Icons.warning_amber_rounded;
      case TdsThresholdStatus.critical: return Icons.error_rounded;
    }
  }
}

/// توصيات الـ Leaching
class LeachingRecommendation {
  final bool needsLeaching;
  final String message;
  final String? specificAdvice;
  final Color color;

  const LeachingRecommendation({
    required this.needsLeaching,
    required this.message,
    this.specificAdvice,
    required this.color,
  });
}

class FarmProfile {
  final CropType cropType;
  final SoilType soilType;
  final DateTime lastUpdated;

  FarmProfile({
    required this.cropType,
    required this.soilType,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  static final FarmProfile fallbackDefault = FarmProfile(
    cropType: CropType.other,
    soilType: SoilType.loamy,
  );

  Map<String, dynamic> toJson() => {
    'crop': cropType.name,
    'soil': soilType.name,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory FarmProfile.fromJson(Map<String, dynamic> json) => FarmProfile(
    cropType: CropType.values.firstWhere(
          (c) => c.name == json['crop'],
      orElse: () => CropType.other,
    ),
    soilType: SoilType.values.firstWhere(
          (s) => s.name == json['soil'],
      orElse: () => SoilType.loamy,
    ),
    lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'] as String)
        : DateTime.now(),
  );

  // ─── Profile Age ───

  /// عدد الأيام من آخر تحديث
  int get profileAgeInDays => DateTime.now().difference(lastUpdated).inDays;

  /// هل الـ profile عمره أكتر من 30 يوم؟
  bool get isProfileStale => profileAgeInDays > 30;

  /// رسالة تحذيرية لو الـ profile قديم
  String? get profileAgeWarning {
    if (isProfileStale) {
      return 'Profile was last updated ${profileAgeInDays} days ago. Consider refreshing for accurate readings.';
    }
    return null;
  }

  // ─── TDS Threshold Status ───

  /// فحص الـ TDS الحالي ضد عتبات الـ crop
  TdsThresholdStatus getTdsThresholdStatus(double tds) {
    final threshold = CropSalinityData.thresholds[cropType.tolerance]!;
    if (tds <= threshold.excellent) return TdsThresholdStatus.excellent;
    if (tds <= threshold.acceptable) return TdsThresholdStatus.acceptable;
    if (tds <= threshold.max) return TdsThresholdStatus.warning;
    return TdsThresholdStatus.critical;
  }

  /// عتبة الـ TDS العليا للمحصول الحالي
  double get maxTdsThreshold =>
      CropSalinityData.thresholds[cropType.tolerance]!.max;

  /// عتبة الـ TDS المقبولة للمحصول الحالي
  double get acceptableTdsThreshold =>
      CropSalinityData.thresholds[cropType.tolerance]!.acceptable;

  // ─── Salt Accumulation Risk (مع Soil Moisture integration) ───

  /// تربة رملية بتصرّف الملح بسهولة (خطر أقل)، تربة طينية بتحتفظ بيه
  /// (خطر أعلى)، والطميية في النص. دلوقتي مع Soil Moisture integration.
  SaltAccumulationRisk soilRiskFor(double tds, {double? soilMoisture}) {
    // Base TDS score
    final int base = tds > 1000 ? 2 : (tds > 500 ? 1 : 0);

    // Soil type penalty
    final int soilPenalty = switch (soilType) {
      SoilType.clay => 1,
      SoilType.sandy => -1,
      SoilType.loamy => 0,
    };

    // Soil moisture modifier — لو التربة ناشفة + TDS عالي = خطر أعلى
    int moisturePenalty = 0;
    if (soilMoisture != null) {
      final moistureThreshold = soilType.moistureThresholdForLeaching;
      if (tds > 500 && soilMoisture < moistureThreshold * 100) {
        // تربة ناشفة + TDS عالي = خطر تراكم أعلى
        moisturePenalty = 1;
      } else if (soilMoisture >= moistureThreshold * 100) {
        // تربة رطبة كفاية = الـ leaching طبيعي = خطر أقل
        moisturePenalty = -1;
      }
    }

    final int level = (base + soilPenalty + moisturePenalty).clamp(0, 2);
    return SaltAccumulationRisk.values[level];
  }

  // ─── Historical Salt Index ───

  /// حساب مؤشر التراكم التاريخي من قائمة قراءات TDS
  /// بتقارن المتوسط بآخر قراءة لمعرفة الاتجاه
  HistoricalSaltTrend calculateSaltTrend(List<double> tdsReadings) {
    if (tdsReadings.length < 3) return HistoricalSaltTrend.stable;

    final recentCount = tdsReadings.length ~/ 2;
    final olderCount = tdsReadings.length - recentCount;

    final olderAverage =
        tdsReadings.take(olderCount).reduce((a, b) => a + b) / olderCount;

    final recentAverage =
        tdsReadings.skip(olderCount).reduce((a, b) => a + b) / recentCount;

    final changePercent = olderAverage > 0
        ? ((recentAverage - olderAverage) / olderAverage) * 100
        : 0;

    final maxThreshold = maxTdsThreshold;
    final isNearCritical = recentAverage > maxThreshold * 0.8;

    if (changePercent > 20 || (isNearCritical && changePercent > 5)) {
      return HistoricalSaltTrend.critical;
    } else if (changePercent > 10) {
      return HistoricalSaltTrend.rising;
    } else if (changePercent < -10) {
      return HistoricalSaltTrend.declining;
    }
    return HistoricalSaltTrend.stable;
  }

  // ─── Leaching Recommendation ───

  /// بناءً على الـ risk الحالي + Soil Moisture + TDS، بندي توصية بالـ leaching
  LeachingRecommendation getLeachingRecommendation(
      double tds, {
        double? soilMoisture,
      }) {
    final risk = soilRiskFor(tds, soilMoisture: soilMoisture);
    final thresholdStatus = getTdsThresholdStatus(tds);
    final moistureThreshold = soilType.moistureThresholdForLeaching * 100;

    // تربة طينية محتاجة flushing أكتر عشان الـ drainage بطيء
    final flushingMultiplier = switch (soilType) {
      SoilType.clay => 2.0,    // طينية: تحتاج كميّة مياه أكبر
      SoilType.loamy => 1.5,   // طميية: متوسطة
      SoilType.sandy => 1.0,   // رملية: كفاية كميّة أقل (الـ drainage سريع)
    };

    if (thresholdStatus == TdsThresholdStatus.critical || risk == SaltAccumulationRisk.high) {
      return LeachingRecommendation(
        needsLeaching: true,
        message: 'Immediate leaching required',
        specificAdvice:
        'Flush soil with ${(flushingMultiplier * 1.5).toStringAsFixed(0)}x the normal water volume. '
            'Repeat every 2-3 days until TDS drops below ${acceptableTdsThreshold.toStringAsFixed(0)} PPM.',
        color: const Color(0xFFE24B4A),
      );
    } else if (thresholdStatus == TdsThresholdStatus.warning || risk == SaltAccumulationRisk.medium) {
      final isDry = soilMoisture != null && soilMoisture < moistureThreshold;
      return LeachingRecommendation(
        needsLeaching: true,
        message: isDry
            ? 'Leaching recommended — soil is dry'
            : 'Preventive leaching advised',
        specificAdvice: isDry
            ? 'Increase irrigation by ${(flushingMultiplier).toStringAsFixed(0)}x this week. '
            'Ensure water drains through the root zone.'
            : 'Apply extra ${(flushingMultiplier - 0.5).toStringAsFixed(1)}x water volume this week '
            'to prevent salt buildup.',
        color: const Color(0xFFEF9F27),
      );
    }

    // لو الـ moisture منخفضة بس TDS كويس، تحذير وقائي
    if (soilMoisture != null && soilMoisture < moistureThreshold * 0.7) {
      return LeachingRecommendation(
        needsLeaching: false,
        message: 'Soil moisture is low — ensure adequate irrigation',
        color: const Color(0xFF64B5F6),
      );
    }

    return LeachingRecommendation(
      needsLeaching: false,
      message: 'No leaching needed — current conditions are safe',
      color: const Color(0xFF639922),
    );
  }
}
