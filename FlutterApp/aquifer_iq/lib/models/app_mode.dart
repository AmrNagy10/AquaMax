/// يحدد الوضع التشغيلي للتطبيق
/// كل mode له weights مختلفة في الـ scoring, prompts مختلفة في الـ AI,
/// وواجهة مختلفة في الـ UI
enum AppMode {
  /// وضع منزلي: التركيز على صلاحية الشرب والاستخدام المنزلي
  home,

  /// وضع زراعي: التركيز على صلاحية الري وتأثير الملوحة على التربة
  agricultural,
}

extension AppModeExtension on AppMode {
  /// الاسم المعروض في الـ UI
  String get label {
    switch (this) {
      case AppMode.home:
        return 'Home';
      case AppMode.agricultural:
        return 'Agricultural';
    }
  }

  /// الأيقونة المرتبطة بكل mode
  String get icon {
    switch (this) {
      case AppMode.home:
        return 'home';
      case AppMode.agricultural:
        return 'agriculture';
    }
  }

  /// وصف مختصر للـ mode
  String get description {
    switch (this) {
      case AppMode.home:
        return 'Water quality for drinking & household use';
      case AppMode.agricultural:
        return 'Water quality for irrigation & crop health';
    }
  }
}
