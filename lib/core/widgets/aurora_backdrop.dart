import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fond animé "aurora" : trois halos radiaux qui dérivent lentement.
///
/// Utilisé par l'onboarding et les écrans d'authentification pour
/// donner une identité forte sans images.
class AuroraBackdrop extends StatefulWidget {
  const AuroraBackdrop({
    super.key,
    this.primary,
    this.accentA,
    this.accentB,
    this.intensity = 1.0,
  });

  final Color? primary;
  final Color? accentA;
  final Color? accentB;
  final double intensity;

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = widget.primary ?? scheme.primary;
    final accentA = widget.accentA ?? const Color(0xFF7C4DFF);
    final accentB = widget.accentB ?? const Color(0xFF00BCD4);
    final k = widget.intensity;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * 2 * math.pi;
            final dx = 0.15 * math.sin(t);
            final dy = 0.15 * math.sin(t + 1.2);
            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.6 + dx, -0.6 + dy),
                      radius: 1.2,
                      colors: <Color>[
                        primary.withValues(alpha: 0.28 * k),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.7 - dx, 0.4 - dy),
                      radius: 1.1,
                      colors: <Color>[
                        accentA.withValues(alpha: 0.24 * k),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.1 + dy, 0.9 + dx),
                      radius: 0.9,
                      colors: <Color>[
                        accentB.withValues(alpha: 0.22 * k),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
