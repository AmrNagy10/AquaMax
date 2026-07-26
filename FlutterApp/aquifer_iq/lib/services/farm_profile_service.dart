import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm_profile.dart';

/// بيدير بيانات المحصول والتربة الخاصة بوضع Agricultural، بنفس باترن
/// [ModeService]: يحمّل من shared_preferences، وأي تغيير بيتحفظ فورًا.
class FarmProfileService extends ChangeNotifier {
  static const String _key = 'farm_profile';

  FarmProfile? _profile;

  FarmProfileService() {
    _loadProfile();
  }

  /// null لو المستخدم لسه معملش setup أو عمل Skip قبل ما نسجل default.
  FarmProfile? get profile => _profile;

  /// بتستخدم في الـ dashboard/scoring — لو مفيش profile محفوظ بترجع
  /// الافتراضي المحافظ (Other crop / Loamy soil) بدل ما تكسر أي حساب.
  FarmProfile get profileOrDefault => _profile ?? FarmProfile.fallbackDefault;

  /// بتحدد هل نعرض bottom sheet الإعداد أول مرة يتفعّل Agricultural mode.
  bool get hasProfile => _profile != null;

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      try {
        _profile = FarmProfile.fromJson(jsonDecode(saved));
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
  }

  /// بتتنادى من زرار "Skip for now" في الـ setup sheet — بتسجل default
  /// معقول (مش متطرف) عشان الـ sheet متظهرش تاني، لكن تفضل قابلة للتعديل
  /// من الإعدادات في أي وقت.
  Future<void> skipWithDefault() => setProfile(FarmProfile.fallbackDefault);

  Future<void> clearProfile() async {
    _profile = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}