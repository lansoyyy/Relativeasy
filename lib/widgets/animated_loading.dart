import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/colors.dart';
import 'text_widget.dart';

class AnimatedLoading extends StatefulWidget {
  final String message;
  final Color? color;

  const AnimatedLoading({
    super.key,
    this.message = 'Loading...',
    this.color,
  });

  @override
  State<AnimatedLoading> createState() => _AnimatedLoadingState();
}

class _AnimatedLoadingState extends State<AnimatedLoading>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color effectiveColor = widget.color ?? accent;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          effectiveColor,
                          effectiveColor.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: textOnAccent,
                      size: 30,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextWidget(
            text: widget.message,
            fontSize: 16,
            color: textSecondary,
          ),
        ],
      ),
    );
  }
}

class PhysicsParticleAnimation extends StatefulWidget {
  final Widget child;

  const PhysicsParticleAnimation({
    super.key,
    required this.child,
  });

  @override
  State<PhysicsParticleAnimation> createState() =>
      _PhysicsParticleAnimationState();
}

class _PhysicsParticleAnimationState extends State<PhysicsParticleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _particles = List.generate(20, (index) => Particle());
    _controller.repeat();
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
        // Background particles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(_particles, _controller.value),
              size: Size.infinite,
            );
          },
        ),
        // Main content
        widget.child,
      ],
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;

  Particle()
      : x = 0,
        y = 0,
        vx = (0.5 - (DateTime.now().millisecond % 100) / 100) * 2,
        vy = (0.5 - (DateTime.now().microsecond % 100) / 100) * 2,
        size = 1 + (DateTime.now().millisecond % 3),
        color =
            [accent, secondary, lightSpeedGold][DateTime.now().millisecond % 3];
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;

  ParticlePainter(this.particles, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];

      // Update position
      particle.x += particle.vx;
      particle.y += particle.vy;

      // Wrap around screen
      if (particle.x < 0) particle.x = size.width;
      if (particle.x > size.width) particle.x = 0;
      if (particle.y < 0) particle.y = size.height;
      if (particle.y > size.height) particle.y = 0;

      // Draw particle
      paint.color = particle.color.withOpacity(0.3);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ScaleUpAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const ScaleUpAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<ScaleUpAnimation> createState() => _ScaleUpAnimationState();
}

class _ScaleUpAnimationState extends State<ScaleUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final Offset begin;
  final Duration delay;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.begin = const Offset(0, 1),
    this.delay = Duration.zero,
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: widget.child,
    );
  }
}
