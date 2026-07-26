import 'package:flutter/material.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════════════════
// GaugeWidget — StatefulWidget مع Animation سلس للقيم القادمة من BLE
//
// الفكرة:
//   • لما تيجي قيمة جديدة من الـ BLE، الـ arc والنص بيتحركوا بـ animation
//     من القيمة القديمة للجديدة (مش بتقفز فجأة).
//   • النص اللي جوه الدايرة بيتحدث بشكل تدريجي كمان (animated counter).
//   • لون الـ arc بيتغير بـ animation لو اللون اتغير.
// ═══════════════════════════════════════════════════════════════════════════════

class GaugeWidget extends StatefulWidget {
  final String title;
  final double value;
  final double maxValue;
  final String displayText; // النص اللي يتعرض جوه الدايرة (ممكن يكون Grade أو رقم)
  final String unit;
  final Color activeColor;
  final Color bgColor;

  // نص وصفي تحت العنوان (مثل "Ideal", "Caution", "Unsafe") — Optional
  final String? subtitle;

  // مدة الـ animation — قابلة للتخصيص من الخارج لو احتجنا
  final Duration animationDuration;

  const GaugeWidget({
    super.key,
    required this.title,
    required this.value,
    required this.maxValue,
    required this.displayText,
    required this.unit,
    required this.activeColor,
    this.bgColor = Colors.white,
    this.subtitle,
    this.animationDuration = const Duration(milliseconds: 900),
  });

  @override
  State<GaugeWidget> createState() => _GaugeWidgetState();
}

class _GaugeWidgetState extends State<GaugeWidget>
    with SingleTickerProviderStateMixin {
  // ─── Controllers ──────────────────────────────────────────────────────────
  late AnimationController _controller;

  // animation للـ arc (النسبة من 0.0 → 1.0)
  late Animation<double> _arcAnimation;

  // animation للون (من اللون القديم للجديد)
  late Animation<Color?> _colorAnimation;

  // animation للرقم (من القيمة القديمة للجديدة) — بس لو displayText رقم
  late Animation<double> _valueAnimation;

  // آخر قيمة وصلنا عندها عشان نبدأ الـ animation منها
  double _prevPercentage = 0.0;
  double _prevValue      = 0.0;
  Color  _prevColor      = Colors.transparent;

  // هل الـ displayText رقم؟ (لو Grade مثلاً "A+" مش هنحاول نعمله counter)
  bool get _isNumeric => double.tryParse(widget.displayText) != null;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _prevColor = widget.activeColor;

    // أول مرة: نبدأ من 0 ونوصل للقيمة الحالية
    _buildAnimations(
      fromPercentage: 0.0,
      toPercentage:   _currentPercentage,
      fromValue:      0.0,
      toValue:        widget.value,
      fromColor:      widget.activeColor.withOpacity(0.3),
      toColor:        widget.activeColor,
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(GaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final double newPercentage = _currentPercentage;
    final double oldPercentage = (oldWidget.value / oldWidget.maxValue).clamp(0.0, 1.0);

    // لو في تغيير في القيمة أو اللون — نشغّل animation جديدة
    if (newPercentage != oldPercentage ||
        widget.activeColor != oldWidget.activeColor) {

      // نبدأ من المكان اللي وقف عنده الـ animation الحالي
      _prevPercentage = _arcAnimation.value;
      _prevValue      = _valueAnimation.value;
      _prevColor      = _colorAnimation.value ?? oldWidget.activeColor;

      _buildAnimations(
        fromPercentage: _prevPercentage,
        toPercentage:   newPercentage,
        fromValue:      _prevValue,
        toValue:        widget.value,
        fromColor:      _prevColor,
        toColor:        widget.activeColor,
      );

      _controller
        ..reset()
        ..forward();
    }
  }

  // ─── بناء الـ Animations ──────────────────────────────────────────────────
  void _buildAnimations({
    required double fromPercentage,
    required double toPercentage,
    required double fromValue,
    required double toValue,
    required Color  fromColor,
    required Color  toColor,
  }) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _arcAnimation = Tween<double>(
      begin: fromPercentage,
      end:   toPercentage,
    ).animate(curved);

    _colorAnimation = ColorTween(
      begin: fromColor,
      end:   toColor,
    ).animate(curved);

    _valueAnimation = Tween<double>(
      begin: fromValue,
      end:   toValue,
    ).animate(curved);
  }

  double get _currentPercentage =>
      (widget.value / widget.maxValue).clamp(0.0, 1.0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white70        : Colors.grey[800]!;
    final textColor  = isDark ? Colors.white          : Colors.black;
    final unitColor  = isDark ? Colors.white54        : Colors.grey[700]!;
    final borderClr  = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── عنوان المقياس ──────────────────────────────────────────────
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: titleColor,
              letterSpacing: 0.5,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: widget.activeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: widget.activeColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // ── الدايرة + النص الداخلي ─────────────────────────────────────
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // النص المتحرك: لو رقم → نعرض الـ counter، لو grade → ثابت
              final String animatedText = _isNumeric
                  ? _formatAnimatedValue(_valueAnimation.value)
                  : widget.displayText;

              final Color arcColor =
                  _colorAnimation.value ?? widget.activeColor;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // ─ الـ Arc ─────────────────────────────────────────────
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        percentage: _arcAnimation.value,
                        color:      arcColor,
                        isDark:     isDark,
                      ),
                    ),
                  ),

                  // ─ النص جوه الدايرة ───────────────────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // لو الـ Grade (A+, B, …) نعمله fade بدل counter
                      _isNumeric
                          ? Text(
                        animatedText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      )
                          : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Text(
                          animatedText,
                          key: ValueKey(animatedText),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        widget.unit,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: unitColor,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Format ───────────────────────────────────────────────────────────────
  // بنعرض الرقم بنفس صيغة الـ displayText الأصلي:
  //   • لو displayText فيه نقطة عشرية → نعرض نقطة واحدة (مثل Temperature)
  //   • لو مفيش → نعرض integer (مثل TDS و Purity)
  String _formatAnimatedValue(double animValue) {
    if (widget.displayText.contains('.')) {
      return animValue.toStringAsFixed(1);
    }
    return animValue.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _GaugePainter — الرسام الفعلي للـ arc
// ═══════════════════════════════════════════════════════════════════════════════
class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color  color;
  final bool   isDark;

  const _GaugePainter({
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center      = Offset(size.width / 2, size.height / 2);
    final radius      = size.width / 2 - 2; // margin بسيط عشان الـ stroke ما يتقطعش
    const strokeWidth = 9.0;

    // ─ Track خلفي (رمادي) ──────────────────────────────────────────────────
    final trackPaint = Paint()
      ..color       = isDark
          ? Colors.white.withOpacity(0.10)
          : Colors.grey.withOpacity(0.15)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,   // بيبدأ من الساعة 7:30 (أسفل يسار)
      math.pi * 1.5,    // يلف 270 درجة
      false,
      trackPaint,
    );

    // ─ Arc الملون (القيمة الحالية) ─────────────────────────────────────────
    if (percentage > 0.0) {
      final valuePaint = Paint()
        ..color       = color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi * 0.75,
        math.pi * 1.5 * percentage,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.percentage != percentage ||
          old.color      != color      ||
          old.isDark     != isDark;
}