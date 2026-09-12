import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide ProxyProvider;
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const AboutScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: '关于',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Consumer<ProxyProvider>(
      builder: (context, proxyProvider, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 状态显示
                Text(
                  proxyProvider.connectionStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: proxyProvider.isConnected ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                // 速度显示
                if (proxyProvider.isConnected)
                  SpeedMonitor(
                    downloadSpeed: proxyProvider.downloadSpeed,
                    uploadSpeed: proxyProvider.uploadSpeed,
                  ),
                const Spacer(),
                // 大按钮
                ConnectButton(
                  isConnected: proxyProvider.isConnected,
                  isConnecting: proxyProvider.isConnecting,
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    if (proxyProvider.isConnected) {
                      proxyProvider.disconnect();
                    } else {
                      proxyProvider.connect();
                    }
                  },
                ),
                const Spacer(),
                // 节点选择器（内置节点）
                ServerSelector(
                  servers: proxyProvider.servers,
                  selectedServer: proxyProvider.selectedServer,
                  onServerSelected: (server) {
                    proxyProvider.selectServer(server);
                  },
                  onAddServer: () {
                    // 不需要添加节点功能，使用内置节点
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}