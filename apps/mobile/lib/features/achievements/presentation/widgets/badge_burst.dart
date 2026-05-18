import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

/// How much visual weight the burst should carry.
///
/// - [soft]: a gentle sparkle ring around the badge — used for onboarding
///   unlocks. ~10 amber particles, short lifespan, no gravity.
/// - [confetti]: a heavier rotating-square burst with gravity — reserved
///   for prestige unlocks and level-ups.
enum BurstIntensity { soft, confetti }

/// One-shot particle burst painted behind [child]. Plays once on first
/// build; if you want to replay, give the widget a new [Key].
///
/// Designed to be theme-aware via [AppColors] — particles use `ac.amber`
/// and `cs.onSurface` so the effect blends into both light and dark themes
/// without separate tuning.
class BadgeBurst extends StatefulWidget {
  const BadgeBurst({
    super.key,
    required this.intensity,
    required this.child,
  });

  final BurstIntensity intensity;
  final Widget child;

  @override
  State<BadgeBurst> createState() => _BadgeBurstState();
}

class _BadgeBurstState extends State<BadgeBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Particle> _particles;

  bool get _shouldLoop => widget.intensity == BurstIntensity.confetti;

  @override
  void initState() {
    super.initState();
    final isConfetti = widget.intensity == BurstIntensity.confetti;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isConfetti ? 1200 : 650),
    );
    _particles = _seedParticles(widget.intensity);
    if (_shouldLoop) {
      // Reseed particles on each cycle so consecutive bursts don't look
      // identical, then drive a continuous shower while the modal is open.
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _particles = _seedParticles(widget.intensity));
          _controller.forward(from: 0);
        }
      });
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final accent = Theme.of(context).colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return CustomPaint(
          painter: _BurstPainter(
            particles: _particles,
            t: _controller.value,
            intensity: widget.intensity,
            primary: ac.amber,
            accent: accent,
          ),
          child: child,
        );
      },
    );
  }
}

/// Stateless precomputed description of a single particle. The painter
/// derives current position / opacity from [t].
class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationVelocity,
    required this.useAccent,
    required this.shape,
  });

  /// Initial radial direction in radians (0 = right, π/2 = down).
  final double angle;

  /// Initial speed in pixels per unit of animation time.
  final double speed;

  /// Particle render size in pixels (diameter for dot, side length for square).
  final double size;
  final double rotation;
  final double rotationVelocity;
  final bool useAccent;
  final _ParticleShape shape;
}

enum _ParticleShape { dot, square }

List<_Particle> _seedParticles(BurstIntensity intensity) {
  final rng = math.Random();
  if (intensity == BurstIntensity.soft) {
    return List.generate(10, (i) {
      final spread = (i / 10) * math.pi * 2;
      // Slight angular jitter so the ring doesn't look mechanical.
      return _Particle(
        angle: spread + (rng.nextDouble() - 0.5) * 0.4,
        speed: 50 + rng.nextDouble() * 20,
        size: 3 + rng.nextDouble() * 1.5,
        rotation: 0,
        rotationVelocity: 0,
        useAccent: false,
        shape: _ParticleShape.dot,
      );
    });
  }
  // Confetti: 36 particles in the upper hemisphere with downward gravity
  // applied by the painter. Half use the accent color for two-tone effect.
  return List.generate(36, (i) {
    return _Particle(
      angle: -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi,
      speed: 90 + rng.nextDouble() * 70,
      size: 4 + rng.nextDouble() * 4,
      rotation: rng.nextDouble() * math.pi * 2,
      rotationVelocity: (rng.nextDouble() - 0.5) * 6,
      useAccent: rng.nextBool(),
      shape: _ParticleShape.square,
    );
  });
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.particles,
    required this.t,
    required this.intensity,
    required this.primary,
    required this.accent,
  });

  final List<_Particle> particles;
  final double t;
  final BurstIntensity intensity;
  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final centre = Offset(size.width / 2, size.height / 2);
    final isConfetti = intensity == BurstIntensity.confetti;
    // Ease-out for the position, ease-in for the fade so particles
    // travel quickly then linger briefly before disappearing.
    final positionT = 1 - math.pow(1 - t, 2.0);
    final opacity = 1 - math.pow(t, 2.2).toDouble();

    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * positionT;
      double dy = math.sin(p.angle) * p.speed * positionT;
      if (isConfetti) {
        // Gravity term — pulls particles down over time.
        dy += 0.5 * 220 * t * t;
      }
      final pos = centre + Offset(dx, dy);
      final color = (p.useAccent ? accent : primary).withValues(
        alpha: opacity.clamp(0.0, 1.0),
      );

      final paint = Paint()..color = color;
      switch (p.shape) {
        case _ParticleShape.dot:
          canvas.drawCircle(pos, p.size / 2, paint);
          break;
        case _ParticleShape.square:
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(p.rotation + p.rotationVelocity * t);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size,
            ),
            paint,
          );
          canvas.restore();
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.t != t || old.primary != primary || old.accent != accent;
}
