import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide ProxyProvider;
import '../models/proxy_server.dart';
import '../providers/proxy_provider.dart';
import '../widgets/connect_button.dart';
import '../widgets/server_selector.dart';
import '../widgets/speed_monitor.dart';
import 'about_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final Map<String, int> _delays = {};
  final Set<String> _testing = {};

  PowerState _powerOf(ProxyProvider p) {
    if (p.isConnecting || p.isDisconnecting) return PowerState.connecting;
    if (p.isConnected) return PowerState.connected;
    return PowerState.idle;
  }

  bool _testingAll = false;

  Future<void> _testOne(ProxyProvider p, ProxyServer s) async {
    if (_testing.contains(s.link) || p.busy) {
      if (p.busy && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('内核忙碌中，请稍候…')),
        );
      }
      return;
    }
    setState(() => _testing.add(s.link));
    final d = await p.testDelay(s);
    if (!mounted) return;
    setState(() {
      _testing.remove(s.link);
      _delays[s.link] = d; // -1 超时 / -2 忙
    });
  }

  Future<void> _testAll(ProxyProvider p) async {
    if (_testingAll) return;
    setState(() => _testingAll = true);
    // 串行测速：每次测速都会起/杀一个临时 Xray 进程，并发会互相冲突
    for (final s in p.servers) {
      if (!mounted) break;
      await _testOne(p, s);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (mounted) setState(() => _testingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHome(),
        const AboutScreen(),
      ],
    );
  }

  Widget _buildHome() {
    final proxy = context.watch<ProxyProvider>();

    // 错误提示：在帧结束后弹出，避免 build 期间修改状态
    final err = proxy.errorMessage;
    if (err.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        if (mounted) context.read<ProxyProvider>().clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proxy App'),
        actions: [
          IconButton(
            tooltip: '测速全部节点（长按单个节点可单独测速）',
            onPressed: () => _testAll(proxy),
            icon: Icon(_testingAll ? Icons.hourglass_top : Icons.speed),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: '关于'),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              // 当前节点
              _CurrentNode(
                server: proxy.selectedServer,
                statusText: proxy.statusText,
                connected: proxy.isConnected,
              ),
              const SizedBox(height: 10),
              // 速度面板：仅连接后显示，带高度过渡动画
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: proxy.isConnected || proxy.isConnecting
                    ? SpeedMonitor(
                        downloadSpeed: proxy.downloadSpeed,
                        uploadSpeed: proxy.uploadSpeed,
                        downloadTraffic: proxy.downloadTraffic,
                        uploadTraffic: proxy.uploadTraffic,
                        durationSeconds: proxy.durationSeconds,
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 4),
              // 动画按钮
              Expanded(
                child: Center(
                  child: ConnectButton(
                    state: _powerOf(proxy),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      proxy.toggle();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // 节点列表（可下滑）
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.30,
                child: ServerSelector(
                  servers: proxy.servers,
                  selectedServer: proxy.selectedServer,
                  delays: _delays,
                  testing: _testing,
                  onServerSelected: (s) {
                    HapticFeedback.lightImpact();
                    // 仅切换节点。原先"选中即自动测速"会临时起/杀
                    // Xray 进程，与随后的连接动作抢资源，导致按钮
                    // 看起来"点了没反应"。测速改为手动触发。
                    proxy.selectServer(s);
                  },
                  onServerLongPress: (s) {
                    HapticFeedback.mediumImpact();
                    _testOne(proxy, s);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶部：当前节点 + 状态胶囊
class _CurrentNode extends StatelessWidget {
  final ProxyServer? server;
  final String statusText;
  final bool connected;

  const _CurrentNode({
    required this.server,
    required this.statusText,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = connected
        ? const Color(0xFF43A047)
        : (statusText == '连接中' || statusText == '断开中'
            ? const Color(0xFFFFA726)
            : scheme.onSurfaceVariant);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: connected ? 8 : 0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server?.name ?? '未选择节点',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  server == null
                      ? '请在下方选择节点'
                      : '${server!.address}:${server!.port}',
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withValues(alpha: 0.14),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}