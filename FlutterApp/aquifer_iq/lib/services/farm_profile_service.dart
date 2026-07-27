import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm_profile.dart';

/// بيدير بيانات المحصول والتربة الخاصة بوضع Agricultural، بنفس باترن
/// [ModeService]: يحمّل من shared_preferences، وأي تغيير بيتحفظ فورًا.
class FarmProfileService extends ChangeNotifier {
  static const String _key = 'farm_profile';
  static const String _skipKey = 'farm_profile_skipped';

  FarmProfile? _profile;
  bool _wasSkipped = false;

  FarmProfileService() {
    _loadProfile();
  }

  /// null لو المستخدم لسه معملش setup أو عمل Skip قبل ما نسجل default.
  FarmProfile? get profile => _profile;

  /// بتستخدم في الـ dashboard/scoring — لو مفيش profile محفوظ بترجع
  /// الافتراضي المحافظ (Other crop / Loamy soil) بدل ما تكسر أي حساب.
  FarmProfile get profileOrDefault => _profile ?? FarmProfile.fallbackDefault;

  /// بتحدد هل نعرض bottom sheet الإعداد.
  /// لو المستخدم عمل Skip أو مفيش profile محفوظ، بنعتبر إنه محتاج يرى الـ sheet تاني.
  bool get hasProfile => _profile != null && !_wasSkipped;

  /// هل الـ profile عمره أكتر من 30 يوم؟
  bool get isProfileStale => _profile?.isProfileStale ?? false;

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      try {
        _profile = FarmProfile.fromJson(jsonDecode(saved));
        // لو الـ profile هو الـ default ومستخدم عمل skip قبل كده،
        /// بنعتبره "مش عنده profile حقيقي" عشان نوريه الـ sheet تاني.
        final isDefault = _profile!.cropType == CropType.other && _profile!.soilType == SoilType.loamy;
        if (isDefault && prefs.getBool(_skipKey) == true) {
          _wasSkipped = true;
          _profile = null;
        }
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading farm profile: $e");
      }
    }
  }

  Future<void> setProfile(FarmProfile profile) async {
    _profile = profile;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
    // بنشيل skip flag لو المستخدم حدد profile حقيقي
    await prefs.remove(_skipKey);
    _wasSkipped = false;
  }

  /// بتتنادى من زرار "Skip for now" في الـ setup sheet — بنحفظ flag إن
  /// المستخدم عمل skip عشان الـ sheet ترجع تظهر لو عايز يعدل profile.
  Future<void> skipWithDefault() async {
    _wasSkipped = true;
    _profile = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipKey, true);
    await prefs.remove(_key);
  }

  Future<void> clearProfile() async {
    _profile = null;
    _wasSkipped = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_skipKey);
  }
}
