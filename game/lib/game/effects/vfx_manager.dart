import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// VFX Manager for Cafe Match Tycoon (MG-0004)
/// Match3 + Simulation 게임 전용 이펙트 관리자
class VfxManager extends Component with HasGameRef {
  VfxManager();

  final Random _random = Random();

  // ============================================================
  // Match-3 Effects
  // ============================================================

  /// 타일 매치 성공 - 기본 클리어
  void showMatchClear(Vector2 position, Color tileColor, {int matchCount = 3}) {
    final intensity = (matchCount / 3).clamp(1.0, 2.0);

    gameRef.add(
      _createBurstEffect(
        position: position,
        color: tileColor,
        count: (12 * intensity).toInt(),
        speed: 80 * intensity,
        lifespan: 0.5,
      ),
    );
  }

  /// 4매치 특수 효과
  void showMatch4(Vector2 position, Color tileColor) {
    // 라인 이펙트
    gameRef.add(
      _createLineEffect(position: position, color: tileColor, isHorizontal: true),
    );
    gameRef.add(
      _createLineEffect(position: position, color: tileColor, isHorizontal: false),
    );

    // 스파클
    gameRef.add(
      _createSparkleEffect(position: position, color: Colors.white, count: 15),
    );
  }

  /// 5매치 폭발 효과
  void showMatch5(Vector2 position, Color tileColor) {
    // 큰 폭발
    gameRef.add(
      _createExplosionEffect(
        position: position,
        color: tileColor,
        count: 40,
        radius: 80,
      ),
    );

    // 무지개 스파클
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
    for (int i = 0; i < colors.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (!isMounted) return;
        gameRef.add(
          _createSparkleEffect(
            position: position,
            color: colors[i],
            count: 8,
          ),
        );
      });
    }

    _triggerScreenShake(intensity: 5, duration: 0.3);
  }

  /// 콤보 표시
  void showCombo(Vector2 position, int comboCount) {
    gameRef.add(
      _ComboText(position: position, combo: comboCount),
    );

    if (comboCount >= 5) {
      gameRef.add(
        _createSparkleEffect(
          position: position,
          color: Colors.amber,
          count: 10,
        ),
      );
    }
  }

  /// 타일 스왑 힌트
  void showSwapHint(Vector2 from, Vector2 to) {
    gameRef.add(
      _createSwapArrow(from: from, to: to),
    );
  }

  /// 셔플 이펙트
  void showShuffle(Vector2 centerPosition) {
    for (int i = 0; i < 8; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (!isMounted) return;
        final offset = Vector2(
          (_random.nextDouble() - 0.5) * 150,
          (_random.nextDouble() - 0.5) * 150,
        );
        gameRef.add(
          _createSparkleEffect(
            position: centerPosition + offset,
            color: Colors.white,
            count: 5,
          ),
        );
      });
    }
  }

  // ============================================================
  // Cafe/Tycoon Effects
  // ============================================================

  /// 손님 입장
  void showCustomerEnter(Vector2 position) {
    gameRef.add(
      _createSparkleEffect(position: position, color: Colors.lightBlue, count: 8),
    );
  }

  /// 주문 완료
  void showOrderComplete(Vector2 position) {
    gameRef.add(
      _createRisingEffect(
        position: position,
        color: Colors.green,
        count: 10,
        speed: 50,
      ),
    );

    showNumberPopup(position, '✓', color: Colors.green);
  }

  /// 손님 만족
  void showCustomerSatisfied(Vector2 position, {bool isVeryHappy = false}) {
    if (isVeryHappy) {
      // 하트 이펙트
      for (int i = 0; i < 3; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (!isMounted) return;
          gameRef.add(
            _createHeartEffect(
              position: position + Vector2((_random.nextDouble() - 0.5) * 30, -20),
            ),
          );
        });
      }
    } else {
      gameRef.add(
        _createRisingEffect(
          position: position,
          color: Colors.pink.shade200,
          count: 5,
          speed: 40,
        ),
      );
    }
  }

  /// 손님 불만족
  void showCustomerAngry(Vector2 position) {
    gameRef.add(
      _createSmokeEffect(position: position, count: 8, color: Colors.grey.shade600),
    );
  }

  /// 수익 획득
  void showMoneyGain(Vector2 position, int amount) {
    gameRef.add(
      _createCoinEffect(position: position, count: (amount / 50).clamp(3, 12).toInt()),
    );

    showNumberPopup(position, '+\$$amount', color: Colors.amber);
  }

  /// 데코레이션 배치
  void showDecorationPlace(Vector2 position) {
    gameRef.add(
      _createSparkleEffect(position: position, color: Colors.amber, count: 12),
    );

    gameRef.add(
      _createGroundCircle(position: position, color: Colors.amber),
    );
  }

  /// 업그레이드 완료
  void showUpgradeComplete(Vector2 position) {
    // 상승하는 별
    gameRef.add(
      _createRisingEffect(
        position: position,
        color: Colors.amber,
        count: 15,
        speed: 80,
      ),
    );

    // 폭발
    gameRef.add(
      _createExplosionEffect(
        position: position,
        color: Colors.yellow,
        count: 25,
        radius: 60,
      ),
    );

    gameRef.add(
      _UpgradeText(position: position),
    );
  }

  // ============================================================
  // Utility
  // ============================================================

  void showNumberPopup(Vector2 position, String text, {Color color = Colors.white}) {
    gameRef.add(
      _NumberPopup(position: position, text: text, color: color),
    );
  }

  void _triggerScreenShake({double intensity = 5, double duration = 0.3}) {
    if (gameRef.camera.viewfinder.children.isNotEmpty) {
      gameRef.camera.viewfinder.add(
        MoveByEffect(
          Vector2(intensity, 0),
          EffectController(
            duration: duration / 10,
            repeatCount: (duration * 10).toInt(),
            alternate: true,
          ),
        ),
      );
    }
  }

  // ============================================================
  // Private Effect Generators
  // ============================================================

  ParticleSystemComponent _createBurstEffect({
    required Vector2 position,
    required Color color,
    required int count,
    required double speed,
    required double lifespan,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: lifespan,
        generator: (i) {
          final angle = (i / count) * 2 * pi;
          final velocity = Vector2(cos(angle), sin(angle)) *
              (speed * (0.5 + _random.nextDouble() * 0.5));

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 150),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = 4 * (1.0 - progress * 0.5);

                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createExplosionEffect({
    required Vector2 position,
    required Color color,
    required int count,
    required double radius,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.6,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = radius * (0.4 + _random.nextDouble() * 0.6);
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 80),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = 5 * (1.0 - progress * 0.3);

                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createLineEffect({
    required Vector2 position,
    required Color color,
    required bool isHorizontal,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 0.4,
        generator: (i) {
          final spread = (i / 20 - 0.5) * 200;
          final velocity = isHorizontal
              ? Vector2(spread * 3, 0)
              : Vector2(0, spread * 3);

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);

                canvas.drawCircle(
                  Offset.zero,
                  3,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createSparkleEffect({
    required Vector2 position,
    required Color color,
    required int count,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.5,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 40 + _random.nextDouble() * 40;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 50),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
                final size = 3 * (1.0 - particle.progress * 0.5);

                // 별 모양
                final path = Path();
                for (int j = 0; j < 4; j++) {
                  final a = (j * pi / 2) - pi / 4;
                  final x = cos(a) * size;
                  final y = sin(a) * size;
                  if (j == 0) {
                    path.moveTo(x, y);
                  } else {
                    path.lineTo(x, y);
                  }
                }
                path.close();

                canvas.drawPath(
                  path,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createRisingEffect({
    required Vector2 position,
    required Color color,
    required int count,
    required double speed,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.8,
        generator: (i) {
          final spreadX = (_random.nextDouble() - 0.5) * 30;

          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, 0),
            speed: Vector2(0, -speed),
            acceleration: Vector2(0, -20),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);

                canvas.drawCircle(
                  Offset.zero,
                  3,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createHeartEffect({required Vector2 position}) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 1,
        lifespan: 1.0,
        generator: (i) {
          return AcceleratedParticle(
            position: position.clone(),
            speed: Vector2((_random.nextDouble() - 0.5) * 20, -40),
            acceleration: Vector2(0, -20),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = 8 * (1.0 - progress * 0.3);

                // 하트 모양 (간단화)
                final path = Path();
                path.moveTo(0, size * 0.3);
                path.cubicTo(-size, -size * 0.3, -size * 0.5, -size, 0, -size * 0.5);
                path.cubicTo(size * 0.5, -size, size, -size * 0.3, 0, size * 0.3);

                canvas.drawPath(
                  path,
                  Paint()..color = Colors.pink.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createSmokeEffect({
    required Vector2 position,
    required int count,
    Color color = Colors.grey,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.8,
        generator: (i) {
          final spreadX = (_random.nextDouble() - 0.5) * 20;

          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, 0),
            speed: Vector2(
              (_random.nextDouble() - 0.5) * 15,
              -25 - _random.nextDouble() * 15,
            ),
            acceleration: Vector2(0, -5),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (0.5 - progress * 0.5).clamp(0.0, 1.0);
                final size = 5 + progress * 8;

                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createCoinEffect({
    required Vector2 position,
    required int count,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.7,
        generator: (i) {
          final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi / 4;
          final speed = 120 + _random.nextDouble() * 80;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 350),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress * 0.2).clamp(0.0, 1.0);
                final rotation = particle.progress * 3 * pi;

                canvas.save();
                canvas.rotate(rotation);

                canvas.drawOval(
                  const Rect.fromLTWH(-3, -2, 6, 4),
                  Paint()..color = Colors.amber.withOpacity(opacity),
                );

                canvas.restore();
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createGroundCircle({
    required Vector2 position,
    required Color color,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 1,
        lifespan: 0.6,
        generator: (i) {
          return ComputedParticle(
            renderer: (canvas, particle) {
              final progress = particle.progress;
              final opacity = (1.0 - progress).clamp(0.0, 1.0);
              final radius = 15 + progress * 30;

              canvas.drawCircle(
                Offset(position.x, position.y),
                radius,
                Paint()
                  ..color = color.withOpacity(opacity * 0.4)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2,
              );
            },
          );
        },
      ),
    );
  }

  Component _createSwapArrow({
    required Vector2 from,
    required Vector2 to,
  }) {
    return _SwapArrow(from: from, to: to);
  }
}

/// 스왑 화살표 컴포넌트
class _SwapArrow extends PositionComponent {
  final Vector2 from;
  final Vector2 to;

  _SwapArrow({required this.from, required this.to});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(OpacityEffect.fadeOut(
      EffectController(duration: 1.5),
    ));

    add(RemoveEffect(delay: 1.5));
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(from.x, from.y),
      Offset(to.x, to.y),
      paint,
    );

    // 화살촉
    final direction = (to - from).normalized();
    final arrowSize = 8.0;
    final arrowPoint = to - direction * 5;
    final perpendicular = Vector2(-direction.y, direction.x);

    final path = Path();
    path.moveTo(to.x, to.y);
    path.lineTo(
      arrowPoint.x + perpendicular.x * arrowSize,
      arrowPoint.y + perpendicular.y * arrowSize,
    );
    path.lineTo(
      arrowPoint.x - perpendicular.x * arrowSize,
      arrowPoint.y - perpendicular.y * arrowSize,
    );
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.8));
  }
}

/// 콤보 텍스트
class _ComboText extends TextComponent {
  _ComboText({required Vector2 position, required int combo})
      : super(
          text: '$combo COMBO!',
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: 20 + (combo * 0.5).clamp(0, 10),
              fontWeight: FontWeight.bold,
              color: combo >= 10 ? Colors.red : (combo >= 5 ? Colors.orange : Colors.yellow),
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    scale = Vector2.all(0.5);
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.2, curve: Curves.elasticOut),
    ));

    add(MoveByEffect(
      Vector2(0, -30),
      EffectController(duration: 0.8, curve: Curves.easeOut),
    ));

    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.8, startDelay: 0.3),
    ));

    add(RemoveEffect(delay: 1.0));
  }
}

/// 업그레이드 텍스트
class _UpgradeText extends TextComponent {
  _UpgradeText({required Vector2 position})
      : super(
          text: 'UPGRADE!',
          position: position + Vector2(0, -40),
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.orange, blurRadius: 8),
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    scale = Vector2.all(0.5);
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.3, curve: Curves.elasticOut),
    ));

    add(MoveByEffect(
      Vector2(0, -20),
      EffectController(duration: 1.0, curve: Curves.easeOut),
    ));

    add(OpacityEffect.fadeOut(
      EffectController(duration: 1.0, startDelay: 0.5),
    ));

    add(RemoveEffect(delay: 1.5));
  }
}

/// 일반 텍스트 팝업
class _NumberPopup extends TextComponent {
  _NumberPopup({
    required Vector2 position,
    required String text,
    required Color color,
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(MoveByEffect(
      Vector2(0, -25),
      EffectController(duration: 0.6, curve: Curves.easeOut),
    ));

    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.6, startDelay: 0.2),
    ));

    add(RemoveEffect(delay: 0.8));
  }
}
