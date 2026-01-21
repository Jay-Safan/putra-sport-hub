import 'dart:math';
import 'package:flutter/material.dart';

/// Confetti celebration overlay for booking success
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool isPlaying;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.isPlaying = false,
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with TickerProviderStateMixin {
  late List<ConfettiParticle> _particles;
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    setState(() {
      _particles = List.generate(80, (index) => _createParticle(index));
    });
    _controller.forward(from: 0);
  }

  ConfettiParticle _createParticle(int index) {
    final colors = [
      const Color(0xFF2E8B57), // Green
      const Color(0xFFB22222), // Red
      const Color(0xFFFFD700), // Gold
      const Color(0xFF3498DB), // Blue
      const Color(0xFFE67E22), // Orange
      const Color(0xFF9B59B6), // Purple
    ];

    return ConfettiParticle(
      x: _random.nextDouble(),
      y: -0.1 - _random.nextDouble() * 0.3,
      color: colors[_random.nextInt(colors.length)],
      size: 8 + _random.nextDouble() * 8,
      speed: 0.3 + _random.nextDouble() * 0.5,
      rotation: _random.nextDouble() * 360,
      rotationSpeed: -180 + _random.nextDouble() * 360,
      wobble: _random.nextDouble() * 2 * pi,
      wobbleSpeed: 2 + _random.nextDouble() * 4,
      shape: ConfettiShape.values[_random.nextInt(ConfettiShape.values.length)],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isPlaying)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
      ],
    );
  }
}

enum ConfettiShape { rectangle, circle, triangle }

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double speed;
  final double rotation;
  final double rotationSpeed;
  final double wobble;
  final double wobbleSpeed;
  final ConfettiShape shape;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.wobble,
    required this.wobbleSpeed,
    required this.shape,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final currentY = particle.y + particle.speed * progress * 1.5;
      final wobbleOffset = sin(particle.wobble + progress * particle.wobbleSpeed * pi) * 0.05;
      final currentX = particle.x + wobbleOffset;
      final currentRotation = particle.rotation + particle.rotationSpeed * progress;

      if (currentY > 1.2) continue; // Off screen

      final dx = currentX * size.width;
      final dy = currentY * size.height;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(currentRotation * pi / 180);

      switch (particle.shape) {
        case ConfettiShape.rectangle:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            paint,
          );
          break;
        case ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case ConfettiShape.triangle:
          final path = Path();
          path.moveTo(0, -particle.size / 2);
          path.lineTo(particle.size / 2, particle.size / 2);
          path.lineTo(-particle.size / 2, particle.size / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Simple confetti trigger widget
class ConfettiController extends ChangeNotifier {
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void play() {
    _isPlaying = true;
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    notifyListeners();
  }
}

