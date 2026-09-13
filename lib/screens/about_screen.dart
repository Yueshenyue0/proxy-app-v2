import 'package:flutter/material.dart';

/// 关于页：仅保留作者信息与赞赏码
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SizedBox(height: 12),
            // 应用标识
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      Color.lerp(scheme.primary, Colors.black, 0.28)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.vpn_lock,
                  size: 46,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Proxy App',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 26),
            // 作者卡片
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '作者',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Eri',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '感谢您的使用',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // 赞赏码卡片（此卡片以下不再放任何内容）
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '赞赏支持',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 赞赏码图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/qr_reward.png',
                      width: 210,
                      height: 210,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 210,
                        height: 210,
                        color: scheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.qr_code_2,
                          size: 90,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '所有费用续费用于服务器',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}