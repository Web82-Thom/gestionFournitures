import 'dart:math';
import 'package:flutter/material.dart';

/// 🍪 Fond animé avec cookies qui bougent librement,
/// rebondissent entre eux et sur les bords de l’écran.
class AnimatedCookieBackgroundMouve extends StatefulWidget {
  final String cookieImage;
  final int count;
  final double size;
  final double speed;
  final double opacity;

  const AnimatedCookieBackgroundMouve({
    super.key,
    required this.cookieImage,
    this.count = 10,
    this.size = 50,
    this.speed = 0.003,
    this.opacity = 0.25,
  });

  @override
  State<AnimatedCookieBackgroundMouve> createState() =>
      _AnimatedCookieBackgroundMouveState();
}

class _AnimatedCookieBackgroundMouveState extends State<AnimatedCookieBackgroundMouve>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_MovingCookie> _cookies;
  final random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..repeat();

    // 🔸 Initialisation aléatoire des cookies
    _cookies = List.generate(widget.count, (_) {
      final vx = (random.nextDouble() * 0.8 + 0.2) * (random.nextBool() ? 1 : -1);
      final vy = (random.nextDouble() * 0.8 + 0.2) * (random.nextBool() ? 1 : -1);
      return _MovingCookie(
        x: random.nextDouble(),
        y: random.nextDouble(),
        vx: vx,
        vy: vy,
        rotation: random.nextDouble() * 2 * pi,
      );
    });

    _controller.addListener(_updateCookies);
  }

  /// 🔁 Met à jour la position et gère les collisions / rebonds
  void _updateCookies() {
    if (!mounted) return;

    setState(() {
      for (final cookie in _cookies) {
        cookie.x += cookie.vx * widget.speed;
        cookie.y += cookie.vy * widget.speed;

        // Rebond sur les bords
        if (cookie.x <= 0 || cookie.x >= 1) {
          cookie.vx = -cookie.vx;
          cookie.x = cookie.x.clamp(0.0, 1.0);
        }
        if (cookie.y <= 0 || cookie.y >= 1) {
          cookie.vy = -cookie.vy;
          cookie.y = cookie.y.clamp(0.0, 1.0);
        }
      }

      // Collisions entre cookies
      for (int i = 0; i < _cookies.length; i++) {
        for (int j = i + 1; j < _cookies.length; j++) {
          final c1 = _cookies[i];
          final c2 = _cookies[j];
          final dx = c1.x - c2.x;
          final dy = c1.y - c2.y;
          final distance = sqrt(dx * dx + dy * dy);
          final minDist =
              widget.size / MediaQuery.of(context).size.width * 1.1;

          if (distance < minDist) {
            // échange des vitesses (rebond simple)
            final tmpVx = c1.vx;
            final tmpVy = c1.vy;
            c1.vx = c2.vx;
            c1.vy = c2.vy;
            c2.vx = tmpVx;
            c2.vy = tmpVy;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCookies);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: _cookies.map((cookie) {
            final dx = cookie.x * (width - size);
            final dy = cookie.y * (height - size);
            cookie.rotation += 0.002; // rotation lente

            return Positioned(
              left: dx,
              top: dy,
              child: Transform.rotate(
                angle: cookie.rotation,
                child: Image.asset(
                  widget.cookieImage,
                  width: size,
                  height: size,
                  opacity: AlwaysStoppedAnimation(widget.opacity),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// 🍪 Représente un cookie mobile avec position, direction et rotation
class _MovingCookie {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;

  _MovingCookie({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
  });
}
