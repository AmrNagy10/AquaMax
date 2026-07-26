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
}

class FarmProfile {
  final CropType cropType;
  final SoilType soilType;

  const FarmProfile({required this.cropType, required this.soilType});

  static const FarmProfile fallbackDefault = FarmProfile(
    cropType: CropType.other,
    soilType: SoilType.loamy,
  );

  Map<String, dynamic> toJson() => {'crop': cropType.name, 'soil': soilType.name};

  factory FarmProfile.fromJson(Map<String, dynamic> json) => FarmProfile(
    cropType: CropType.values.firstWhere(
          (c) => c.name == json['crop'],
      orElse: () => CropType.other,
    ),
    soilType: SoilType.values.firstWhere(
          (s) => s.name == json['soil'],
      orElse: () => SoilType.loamy,
    ),
  );

  /// تربة رملية بتصرّف الملح بسهولة (خطر أقل)، تربة طينية بتحتفظ بيه
  /// (خطر أعلى)، والطميية في النص.
  SaltAccumulationRisk soilRiskFor(double tds) {
    final int base = tds > 1000 ? 2 : (tds > 500 ? 1 : 0);
    final int soilPenalty = switch (soilType) {
      SoilType.clay => 1,
      SoilType.sandy => -1,
      SoilType.loamy => 0,
    };
    final int level = (base + soilPenalty).clamp(0, 2);
    return SaltAccumulationRisk.values[level];
  }
}