import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';

class ModeService extends ChangeNotifier {
  static const String _key = 'app_mode';

  AppMode _currentMode = AppMode.home;

  ModeService() {
    _loadMode();
  }

  /// الـ mode الحالي — قابل للقراءة من أي مكان في التطبيق
  AppMode get currentMode => _currentMode;

  /// هل الـ mode الحالي هو الوضع المنزلي؟
  bool get isHomeMode => _currentMode == AppMode.home;

  /// هل الـ mode الحالي هو الوضع الزراعي؟
  bool get isAgriculturalMode => _currentMode == AppMode.agricultural;

  /// تحميل الـ mode المحفوظ من SharedPreferences
  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _currentMode = AppMode.values.firstWhere(
            (mode) => mode.name == saved,
        orElse: () => AppMode.home,
      );
      notifyListeners();
    }
  }

  /// تغيير الـ mode وحفظه
  Future<void> setMode(AppMode mode) async {
    _currentMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// toggle بين Home و Agricultural
  Future<void> toggleMode() async {
    await setMode(
      _currentMode == AppMode.home
          ? AppMode.agricultural
          : AppMode.home,
    );
  }
}
