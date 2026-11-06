import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Boîte à outils d'animations réutilisables pour Educoach.
///
/// Toutes les micro-animations de l'app proviennent d'ici afin de garder
/// une cohérence de rythme (durées, courbes) et de coût cognitif.

// ---------------------------------------------------------------------------
// Constantes de timing
// ---------------------------------------------------------------------------
class Motion {
  const Motion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration entrance = Duration(milliseconds: 460);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve springy = Curves.easeOutBack;
  static const Duration stagger = Duration(milliseconds: 60);
}

// ---------------------------------------------------------------------------
// FadeSlideIn – apparition combinée opacité + translation
// ---------------------------------------------------------------------------
/// Fait apparaître [child] avec un léger glissement vertical et un fondu.
///
/// Utilise [delay] pour créer des effets de cascade (listes, grilles).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.entrance,
    this.offset = const Offset(0, 0.12),
    this.curve = Motion.emphasized,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: widget.curve,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: widget.curve));
  late final Animation<double> _scale = Tween<double>(
    begin: 0.98,
    end: 1,
  ).animate(CurvedAnimation(parent: _c, curve: widget.curve));

  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _startTimer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// Enveloppe une liste d'enfants avec des délais progressifs.
class Stagger extends StatelessWidget {
  const Stagger({
    super.key,
    required this.children,
    this.step = Motion.stagger,
    this.initialDelay = Duration.zero,
  });

  final List<Widget> children;
  final Duration step;
  final Duration initialDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == children.length - 1 ? 0 : 10),
            child: FadeSlideIn(
              delay: initialDelay + step * i,
              child: children[i],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AnimatedCounter – compteur animé
// ---------------------------------------------------------------------------
/// Affiche une valeur numérique animée de 0 à [value] (ou [from]).
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.from = 0,
    this.duration = Motion.slow,
    this.delay = Duration.zero,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.curve = Motion.emphasized,
  });

  final double value;
  final double from;
  final Duration duration;
  final Duration delay;
  final int decimals;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Curve curve;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late Animation<double> _anim = Tween<double>(
    begin: widget.from,
    end: widget.value,
  ).animate(CurvedAnimation(parent: _c, curve: widget.curve));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(
        begin: _anim.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _c, curve: widget.curve));
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _anim.value;
        final digits = v.abs() >= 100 ? 0 : widget.decimals;
        return Text(
          '${widget.prefix}${v.toStringAsFixed(digits)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AnimatedBar – croissance verticale animée (histogramme)
// ---------------------------------------------------------------------------
/// Barre verticale dont la hauteur s'anime de 0 à [ratio] (0..1).
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.ratio,
    required this.color,
    this.maxHeight = 100,
    this.width = 24,
    this.delay = Duration.zero,
    this.borderRadius = 8,
  });

  final double ratio;
  final Color color;
  final double maxHeight;
  final double width;
  final Duration delay;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
      duration: Motion.slow,
      curve: Curves.easeOutQuart,
      builder: (context, v, _) {
        return Container(
          width: width,
          height: maxHeight * v,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.35),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(borderRadius),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PressableScale – retour visuel au tap
// ---------------------------------------------------------------------------
/// Enveloppe un enfant et le rétracte légèrement lorsqu'il est pressé.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Motion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerBox – placeholder animé
// ---------------------------------------------------------------------------
/// Rectangle avec brillance animée, pour les états de chargement.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.height = 12,
    this.width = double.infinity,
    this.borderRadius = 10,
    this.base,
  });

  final double height;
  final double width;
  final double borderRadius;
  final Color? base;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.base ?? scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.6),
      base,
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _c.value * 3, -0.3),
              end: Alignment(1 + _c.value * 3, 0.3),
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AnimatedGradientCard – carte avec halo animé en dégradé
// ---------------------------------------------------------------------------
/// Carte héro avec un gradient animé "vivant" (déplacement de lumière).
class AnimatedGradientCard extends StatefulWidget {
  const AnimatedGradientCard({
    super.key,
    required this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
  });

  final List<Color> colors;
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  State<AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 2 * math.pi;
        final shift = math.sin(t) * 0.25;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + shift, -1),
              end: Alignment(1 + shift, 1),
              colors: widget.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: widget.padding,
          child: child,
        );
      },
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HeroCourse – tag hero cohérent pour les tuiles de cours
// ---------------------------------------------------------------------------
class HeroCourse {
  const HeroCourse._();
  static String icon(String code) => 'course-icon-$code';
  static String title(String code) => 'course-title-$code';
}

// ---------------------------------------------------------------------------
// BlurOverlay – voile flou optionnel pour les écrans d'onboarding
// ---------------------------------------------------------------------------
class BlurOverlay extends StatelessWidget {
  const BlurOverlay({super.key, required this.child, this.sigma = 20});
  final Widget child;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// ConfettiBurst – explosion de confettis en overlay, autonome (0 dépendance)
// ---------------------------------------------------------------------------
/// Overlay qui projette une gerbe de confettis depuis le haut-centre, puis
/// les laisse retomber avec gravité et fondu. Se joue une seule fois.
///
/// Poser ce widget dans un [Stack] (il remplit son parent) pour célébrer une
/// réussite : fin de leçon, série battue, devoir corrigé, etc.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.particleCount = 110,
    this.duration = const Duration(milliseconds: 2800),
    this.colors,
    this.originY = 0.34,
  });

  final int particleCount;
  final Duration duration;
  final List<Color>? colors;
  final double originY;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final List<_ConfettiParticle> _particles;

  static const _defaultColors = <Color>[
    Color(0xFFF4511E),
    Color(0xFF7C4DFF),
    Color(0xFF00BCD4),
    Color(0xFFFFC107),
    Color(0xFF43A047),
    Color(0xFFE91E63),
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random(1337);
    final palette = widget.colors ?? _defaultColors;
    _particles = <_ConfettiParticle>[
      for (var i = 0; i < widget.particleCount; i++)
        _ConfettiParticle(
          angle: -math.pi / 2 + (rng.nextDouble() - 0.5) * 2.1,
          speed: 0.28 + rng.nextDouble() * 0.55,
          drift: (rng.nextDouble() - 0.5) * 0.5,
          fall: 0.7 + rng.nextDouble() * 0.9,
          size: 6 + rng.nextDouble() * 8,
          spin: (rng.nextDouble() - 0.5) * 4,
          round: rng.nextBool(),
          color: palette[rng.nextInt(palette.length)],
          delay: rng.nextDouble() * 0.12,
        ),
    ];
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _ConfettiPainter(
              t: _c.value,
              particles: _particles,
              originY: widget.originY,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.drift,
    required this.fall,
    required this.size,
    required this.spin,
    required this.round,
    required this.color,
    required this.delay,
  });
  final double angle;
  final double speed;
  final double drift;
  final double fall;
  final double size;
  final double spin;
  final bool round;
  final Color color;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.t,
    required this.particles,
    required this.originY,
  });
  final double t;
  final List<_ConfettiParticle> particles;
  final double originY;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * originY;
    final paint = Paint();
    for (final p in particles) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = Curves.easeOutCubic.transform(local);
      final gravity = local * local;
      final dx =
          math.cos(p.angle) * p.speed * eased * size.width * 0.55 +
          p.drift * eased * size.width * 0.25;
      final dy =
          math.sin(p.angle) * p.speed * eased * size.height * 0.55 +
          p.fall * gravity * size.height * 0.55;
      final x = cx + dx;
      final y = cy + dy;
      final alpha = (1 - local * local).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local * math.pi);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      } else {
        final r = p.size * 0.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.3),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.t != t || old.originY != originY;
}

// ---------------------------------------------------------------------------
// PopBounce – apparition élastique (scale 0 -> 1 avec petit rebond)
// ---------------------------------------------------------------------------
class PopBounce extends StatefulWidget {
  const PopBounce({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 620),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<PopBounce> createState() => _PopBounceState();
}

class _PopBounceState extends State<PopBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: curved.value.clamp(0.0, 1.3),
        child: Opacity(opacity: _c.value.clamp(0.0, 1.0), child: child),
      ),
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Route personnalisée : fade + slide
// ---------------------------------------------------------------------------
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  FadeSlideRoute({
    required Widget page,
    super.settings,
    bool reverse = false,
    Duration duration = Motion.normal,
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (_, _, _) => page,
         transitionsBuilder: (context, anim, _, child) {
           final curved = CurvedAnimation(
             parent: anim,
             curve: Curves.easeOutCubic,
           );
           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: Offset(0, reverse ? -0.03 : 0.05),
                 end: Offset.zero,
               ).animate(curved),
               child: child,
             ),
           );
         },
       );
}
