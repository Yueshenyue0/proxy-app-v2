import 'package:flutter/material.dart';

class SpeedMonitor extends StatelessWidget {
  final double downloadSpeed;
  final double uploadSpeed;

  const SpeedMonitor({
    super.key,
    required this.downloadSpeed,
    required this.uploadSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSpeedItem(
            icon: Icons.arrow_downward,
            label: '下载',
            speed: downloadSpeed,
            color: Colors.green,
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          _buildSpeedItem(
            icon: Icons.arrow_upward,
            label: '上传',
            speed: uploadSpeed,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedItem({
    required IconData icon,
    required String label,
    required double speed,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatSpeed(speed),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatSpeed(double speed) {
    if (speed < 1024) {
      return '${speed.toStringAsFixed(1)} B/s';
    } else if (speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    } else if (speed < 1024 * 1024 * 1024) {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else {
      return '${(speed / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
    }
  }
}