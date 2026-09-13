import 'package:flutter/material.dart';
import '../models/proxy_server.dart';

/// 节点列表：可上下滚动，带逐条入场动画与延迟显示
class ServerSelector extends StatelessWidget {
  final List<ProxyServer> servers;
  final ProxyServer? selectedServer;
  final Function(ProxyServer) onServerSelected;
  final Map<String, int> delays;
  final Set<String> testing;
  final void Function(ProxyServer)? onServerLongPress;

  const ServerSelector({
    super.key,
    required this.servers,
    required this.selectedServer,
    required this.onServerSelected,
    this.delays = const {},
    this.testing = const {},
    this.onServerLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (servers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text('暂无节点', style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Text(
                '节点列表',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${servers.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Expanded + ListView => 可自由下滑浏览全部节点
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              physics: const ClampingScrollPhysics(),
              itemCount: servers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final server = servers[index];
                return _NodeTile(
                  index: index,
                  server: server,
                  selected: selectedServer == server,
                  delay: delays[server.link],
                  testing: testing.contains(server.link),
                  onTap: () => onServerSelected(server),
                  onLongPress: onServerLongPress == null
                      ? null
                      : () => onServerLongPress!(server),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NodeTile extends StatelessWidget {
  final int index;
  final ProxyServer server;
  final bool selected;
  final int? delay;
  final bool testing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _NodeTile({
    required this.index,
    required this.server,
    required this.selected,
    required this.onTap,
    this.delay,
    this.testing = false,
    this.onLongPress,
  });

  Color _delayColor(ColorScheme scheme) {
    final d = delay ?? -1;
    if (d == -2) return scheme.onSurfaceVariant;
    if (d < 0) return scheme.error;
    if (d < 120) return const Color(0xFF43A047);
    if (d < 300) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  String _delayText() {
    if (testing) return '测试中';
    final d = delay;
    if (d == null) return '未测';
    if (d == -2) return '忙碌';
    if (d < 0) return '超时';
    return '${d}ms';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(18 * (1 - t), 0),
          child: child,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          color: selected
              ? scheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // 左侧选中指示条
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 3.5,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: selected ? scheme.primary : Colors.transparent,
                ),
              ),
              const SizedBox(width: 10),
              AnimatedScale(
                duration: const Duration(milliseconds: 260),
                scale: selected ? 1.06 : 1.0,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: selected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    server.protocol == 'hysteria2'
                        ? Icons.bolt
                        : Icons.flutter_dash,
                    size: 20,
                    color:
                        selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${server.address}:${server.port}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 协议标签
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color:
                      _protocolColor(server.protocol).withValues(alpha: 0.14),
                ),
                child: Text(
                  server.protocolDisplay,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _protocolColor(server.protocol),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 延迟
              SizedBox(
                width: 52,
                child: Text(
                  _delayText(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _delayColor(scheme),
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle, size: 18, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _protocolColor(String protocol) {
    switch (protocol) {
      case 'hysteria2':
        return const Color(0xFF9C5BFF);
      case 'vless':
        return const Color(0xFF17B8A6);
      default:
        return const Color(0xFF3D7BFF);
    }
  }
}