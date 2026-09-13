import 'package:flutter/material.dart';

/// 实时速率 / 流量 / 时长面板（数据来自 Xray 内核）
class SpeedMonitor extends StatelessWidget {
  final double downloadSpeed;
  final double uploadSpeed;
  final int? downloadTraffic;
  final int? uploadTraffic;
  final int? durationSeconds;

  const SpeedMonitor({
    super.key,
    required this.downloadSpeed,
    required this.uploadSpeed,
    this.downloadTraffic,
    this.uploadTraffic,
    this.durationSeconds,
  });

  static String formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double b = bytes.toDouble();
    int i = 0;
    while (b >= 1024 && i < units.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(b >= 10 ? 0 : 1)} ${units[i]}';
  }

  static String formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 B/s';
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    double b = bytesPerSec;
    int i = 0;
    while (b >= 1024 && i < units.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(b >= 10 ? 0 : 1)} ${units[i]}';
  }

  static String formatDuration(int? seconds) {
    final s = seconds ?? 0;
    if (s <= 0) return '00:00';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.arrow_downward,
                  label: '下载',
                  value: formatSpeed(downloadSpeed),
                  sub: formatBytes(downloadTraffic),
                  color: const Color(0xFF43A047),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _Metric(
                  icon: Icons.arrow_upward,
                  label: '上传',
                  value: formatSpeed(uploadSpeed),
                  sub: formatBytes(uploadTraffic),
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '已连接 ${formatDuration(durationSeconds)}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}