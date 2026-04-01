import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _linesCtrl;
  late AnimationController _lineDrawCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _glowPulseCtrl;
  late AnimationController _exitCtrl;

  // ── Animations ───────────────────────────────────────────────────────────
  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _linesAnim;
  late Animation<double> _lineDrawAnim;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _bracketAnim;
  late Animation<double> _glowPulse;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
    _runSequence();
  }

  void _initControllers() {
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _linesCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _lineDrawCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _glowPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  void _initAnimations() {
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn));

    _linesAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _linesCtrl, curve: Curves.easeOutCubic));

    _bracketAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _linesCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack)));

    _logoScale = Tween<double>(begin: 0.25, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    _lineDrawAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _lineDrawCtrl, curve: Curves.easeInOut));

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)));

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)));

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic)));

    _glowPulse = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _glowPulseCtrl, curve: Curves.easeInOut));

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
  }

  Future<void> _runSequence() async {
    // 1. Fondo
    await _bgCtrl.forward();
    // 2. Líneas y brackets
    _linesCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    // 3. Logo
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 380));
    // 4. Línea horizontal + texto
    _lineDrawCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    _textCtrl.forward();
    // 5. Esperar y salir
    await Future.delayed(const Duration(milliseconds: 1600));
    await _exitCtrl.forward();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _linesCtrl.dispose();
    _logoCtrl.dispose();
    _lineDrawCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    _glowPulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<LocaleProvider>().strings;
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF040512),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF040512),
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _bgCtrl, _linesCtrl, _logoCtrl, _lineDrawCtrl,
            _textCtrl, _particleCtrl, _glowPulseCtrl, _exitCtrl,
          ]),
          builder: (context, _) {
            return Opacity(
              opacity: _exitFade.value,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── 1. Fondo degradado radial ─────────────────────────
                  Opacity(
                    opacity: _bgFade.value,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.15),
                          radius: 1.3,
                          colors: [
                            Color(0xFF0F1030),
                            Color(0xFF080920),
                            Color(0xFF040512),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ── 2. Líneas diagonales estilo pista de atletismo ────
                  CustomPaint(
                    painter: _TrackLinesPainter(_linesAnim.value),
                    size: size,
                  ),

                  // ── 3. Partículas flotantes ───────────────────────────
                  CustomPaint(
                    painter: _ParticlePainter(
                      _particleCtrl.value,
                      _bgFade.value,
                    ),
                    size: size,
                  ),

                  // ── 4. Brackets de esquinas ───────────────────────────
                  CustomPaint(
                    painter: _BracketsPainter(_bracketAnim.value),
                    size: size,
                  ),

                  // ── 5. Contenido central ──────────────────────────────
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo con glow animado
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: Container(
                            width: 120,
                            height: 148,
                            decoration: BoxDecoration(
                              boxShadow: [
                                // Glow rojo exterior pulsante
                                BoxShadow(
                                  color: const Color(0xFFE74C3C)
                                      .withOpacity(0.45 * _glowPulse.value),
                                  blurRadius: 70 * _glowPulse.value,
                                  spreadRadius: 8 * _glowPulse.value,
                                ),
                                // Glow blanco interior suave
                                BoxShadow(
                                  color: Colors.white
                                      .withOpacity(0.10 * _glowPulse.value),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/fdpa_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Línea roja que se extiende desde el centro
                      _buildAnimatedDivider(size),

                      const SizedBox(height: 22),

                      // "FDPA" título grande
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFE8E8FF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'FDPA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 12,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // "FEDERACIÓN PERUANA" subtítulo
                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _subtitleFade,
                          child: Text(
                            s.splashLine1,
                            style: const TextStyle(
                              color: Color(0xFFE74C3C),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _subtitleFade,
                          child: Text(
                            s.splashLine2,
                            style: const TextStyle(
                              color: Color(0xFFE74C3C),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── 6. Dots pulsantes abajo ───────────────────────────
                  Positioned(
                    bottom: 52,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _subtitleFade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final phase = i * (pi * 2 / 3);
                          final pulse = (sin(_particleCtrl.value * pi * 2 + phase) * 0.5 + 0.5);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: 5 + 2 * pulse,
                            height: 5 + 2 * pulse,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE74C3C)
                                  .withOpacity(0.35 + 0.65 * pulse),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE74C3C)
                                      .withOpacity(0.4 * pulse),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // ── 7. Arco superior ─────────────────────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CustomPaint(
                      painter: _ArcPainter(_linesAnim.value),
                      size: Size(size.width, 120),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedDivider(Size size) {
    final halfWidth = 130.0 * _lineDrawAnim.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Línea izquierda
        Container(
          width: halfWidth,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFFE74C3C).withOpacity(0.9),
              ],
            ),
          ),
        ),
        // Punto central
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C)
                .withOpacity(0.3 + 0.7 * _lineDrawAnim.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE74C3C)
                    .withOpacity(0.5 * _lineDrawAnim.value),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Línea derecha
        Container(
          width: halfWidth,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE74C3C).withOpacity(0.9),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── CustomPainter: líneas diagonales estilo pista de atletismo ─────────────
class _TrackLinesPainter extends CustomPainter {
  final double progress;
  _TrackLinesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final lanes = [
      {'shift': 0.0, 'opacity': 0.10},
      {'shift': 55.0, 'opacity': 0.07},
      {'shift': 110.0, 'opacity': 0.05},
      {'shift': 165.0, 'opacity': 0.03},
      {'shift': -55.0, 'opacity': 0.07},
      {'shift': -110.0, 'opacity': 0.05},
      {'shift': -165.0, 'opacity': 0.03},
    ];

    for (final lane in lanes) {
      final shift = lane['shift']! as double;
      final op = (lane['opacity']! as double) * progress;
      final paint = Paint()
        ..color = const Color(0xFFE74C3C).withOpacity(op)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final startX = -size.width * 0.3 + shift;
      final path = Path()
        ..moveTo(startX, size.height)
        ..lineTo(startX + size.width * 1.6, 0);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TrackLinesPainter old) => old.progress != progress;
}

// ── CustomPainter: brackets de esquina ─────────────────────────────────────
class _BracketsPainter extends CustomPainter {
  final double progress;
  _BracketsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = const Color(0xFFE74C3C).withOpacity(0.55 * progress)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arm = 32.0 * progress;
    const margin = 22.0;

    // Top-left
    _drawBracket(canvas, paint, margin, margin, arm, 1, 1);
    // Top-right
    _drawBracket(canvas, paint, size.width - margin, margin, arm, -1, 1);
    // Bottom-left
    _drawBracket(canvas, paint, margin, size.height - margin, arm, 1, -1);
    // Bottom-right
    _drawBracket(canvas, paint, size.width - margin, size.height - margin, arm, -1, -1);
  }

  void _drawBracket(Canvas canvas, Paint paint,
      double x, double y, double arm, double dx, double dy) {
    final path = Path()
      ..moveTo(x + arm * dx, y)
      ..lineTo(x, y)
      ..lineTo(x, y + arm * dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketsPainter old) => old.progress != progress;
}

// ── CustomPainter: partículas flotantes ────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  final double opacity;
  _ParticlePainter(this.t, this.opacity);

  static final _rng = Random(7);
  static final _particles = List.generate(
    30,
    (_) => _SplashParticle(_rng),
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final pt = (t + p.offset) % 1.0;
      final x = p.x * size.width;
      final rawY = p.y * size.height - pt * p.drift * size.height;
      final y = rawY % size.height;
      final alpha = (sin(pt * pi * 2 + p.phase) * 0.5 + 0.5) * 0.30 * opacity;

      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        Paint()
          ..color = (p.isRed
                  ? const Color(0xFFE74C3C)
                  : Colors.white)
              .withOpacity(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

class _SplashParticle {
  final double x, y, radius, offset, drift, phase;
  final bool isRed;

  _SplashParticle(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        radius = r.nextDouble() * 2.2 + 0.4,
        offset = r.nextDouble(),
        drift = r.nextDouble() * 0.25 + 0.08,
        phase = r.nextDouble() * pi * 2,
        isRed = r.nextDouble() < 0.35;
}

// ── CustomPainter: arco superior ───────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  _ArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, -size.height * 0.6);
    final radius = size.height * 1.15;

    final gradient = RadialGradient(
      center: Alignment.topCenter,
      radius: 1.0,
      colors: [
        const Color(0xFFE74C3C).withOpacity(0.18 * progress),
        Colors.transparent,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final arcPaint = Paint()
      ..color = const Color(0xFFE74C3C).withOpacity(0.18 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final sweepAngle = pi * 0.5 * progress;
    final startAngle = pi / 2 + (pi * 0.25 * (1 - progress));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
