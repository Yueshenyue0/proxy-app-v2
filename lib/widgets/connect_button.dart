import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 连接按钮的三种视觉状态
enum PowerState { idle, connecting, connected }

/// 带流畅动画的圆形电源按钮
/// - idle:        静态蓝色，缓慢呼吸光晕
/// - connecting:  旋转进度环 + 橙色呼吸
/// - connected:   红色 + 双层扩散波纹
class ConnectButton extends StatefulWidget {
  final PowerState state;
  final VoidCallback onPressed;

  const ConnectButton({
    super.key,
    required this.state,
    required this.onPressed,
  });

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with TickerProviderStateMixin {
  /// 常驻呼吸动画
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  /// 连接中旋转动画
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// 按下缩放
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
    lowerBound: 0.9,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant ConnectButton old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _syncSpin();
  }

  void _syncSpin() {
    if (widget.state == PowerState.connecting) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      if (_spin.isAnimating) _spin.stop();
      _spin.value = 0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _breath.dispose();
    _spin.dispose();
    _press.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.state) {
      case PowerState.idle:
        return const Color(0xFF3D7BFF);
      case PowerState.connecting:
        return const Color(0xFFFFA726);
      case PowerState.connected:
        return const Color(0xFFEF5350);
    }
  }

  IconData get _icon {
    switch (widget.state) {
      case PowerState.idle:
        return Icons.power_settings_new;
      case PowerState.connecting:
        return Icons.more_horiz;
      case PowerState.connected:
        return Icons.link;
    }
  }

  String get _label {
    switch (widget.state) {
      case PowerState.idle:
        return '点击连接';
      case PowerState.connecting:
        return '正在连接';
      case PowerState.connected:
        return '已连接';
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 168.0;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _press]),
        builder: (context, child) {
          final breath = _breath.value; // 0..1
          final scale = _press.value;

          return SizedBox(
            width: size + 72,
            height: size + 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 外层光晕
                Transform.scale(
                  scale: 1.0 + breath * 0.10,
                  child: Container(
                    width: size + 56,
                    height: size + 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _color.withValues(alpha: 0.20 + breath * 0.14),
                          _color.withValues(alpha: 0.0),
                        ],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // 已连接：扩散波纹
                if (widget.state == PowerState.connected)
                  ...List.generate(2, (i) {
                    final t = (_breath.value + i * 0.5) % 1.0;
                    return Container(
                      width: size + 20 + t * 60,
                      height: size + 20 + t * 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color.withValues(alpha: (1 - t) * 0.35),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                // 主体
                Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ],
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              colors: [
                Color.lerp(_color, Colors.white, 0.28)!,
                _color,
                Color.lerp(_color, Colors.black, 0.22)!,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 内圈高光
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              // 连接中：旋转进度环
              if (widget.state == PowerState.connecting)
                Positioned(
                  top: 6,
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) => CustomPaint(
                      painter: _ArcPainter(
                        progress: _spin.value,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icon, size: 46, color: Colors.white),
                  const SizedBox(height: 6),
                  Text(
                    _label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 绘制一段旋转的圆弧（连接中指示器）
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final start = progress * 2 * math.pi;
    canvas.drawArc(rect, start, math.pi * 0.7, false, paint);
    canvas.drawArc(
      rect,
      start + math.pi,
      math.pi * 0.35,
      false,
      paint..color = color.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress || old.color != color;
}