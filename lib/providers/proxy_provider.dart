import 'package:flutter/material.dart';
import '../models/proxy_server.dart';
import '../utils/logger.dart';

class ProxyProvider with ChangeNotifier {
  final List<ProxyServer> _servers = [];
  ProxyServer? _selectedServer;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = '未连接';
  double _downloadSpeed = 0.0;
  double _uploadSpeed = 0.0;
  String _errorMessage = '';

  List<ProxyServer> get servers => _servers;
  ProxyServer? get selectedServer => _selectedServer;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  double get downloadSpeed => _downloadSpeed;
  double get uploadSpeed => _uploadSpeed;
  String get errorMessage => _errorMessage;

  ProxyProvider() {
    _loadBuiltInServers();
  }

  void _loadBuiltInServers() {
    // 内置的代理节点（来自之前的解析结果）
    final builtInLinks = [
      // Hysteria2 节点
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@132.145.137.155:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=13a95d801c2b834991f49ce6c6fe754809f8ca2dbf52a4dbc1aeb6885b46cb27&mport=51000-53000#美国专线01',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@132.145.137.155:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=13a95d801c2b834991f49ce6c6fe754809f8ca2dbf52a4dbc1aeb6885b46cb27&mport=51000-53000#美国专线02',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@129.146.124.201:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=d97a9e258f15741cbdbee2ccb4580b20abec969ca70f272f4c1970dfce944ff1&mport=51000-53000#美国专线02',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@159.13.40.81:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=9b92e6da557f1d4cc0c698d135154f07b8ab39f67d5714ce841b21a324a03b33&mport=51000-53000#澳大利亚专线01',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@192.9.179.140:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=8d120b1449b52fe48e98e41c7ee5c0c471574179d5b2e968ba3db5f7575a63a4&mport=51000-53000#澳大利亚专线02',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@144.24.109.215:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=236656426d6094bd5dac2054533d713854d14ce89a41ca0da7e9a6a14d2a7edf&mport=51000-53000#印度专线01',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@141.148.222.181:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=3657f3d6126f53ae984af56c82b7744ca55f31f49dea560996112af192ed1177&mport=51000-53000#印度专线02',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@168.75.68.172:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=615b8e1622a98c5f1da3c923bb64b07bd04749146b33a134125dc1a6920ba04c&mport=51000-53000#巴西专线01',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@144.22.197.28:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=395981c03224ffc29cdda4e168cada627e08bba5af89cc711e6c136580445bf4&mport=51000-53000#巴西专线02',
      // VLESS 节点
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=us1s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fus1&headerType=none&quicSecurity=none&serviceName=&security=tls&fp=chrome&insecure=0&sni=#美国高速01',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=us2s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fus2&headerType=none&quicSecurity=none&serviceName=&security=tls&fp=chrome&insecure=0&sni=#美国高速02',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=in1s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fin1&headerType=none&quicSecurity=none&serviceName=&security=tls&fp=chrome&insecure=0&sni=#印度高速01',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=au1s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fau1&headerType=none&quicSecurity=none&serviceName=&security=tls&fp=chrome&insecure=0&sni=#澳大利亚高速01',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=au2s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fau2&headerType=none&quicSecurity=none&serviceName=&security=tls&fp=chrome&insecure=0&sni=#澳大利亚高速02',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=fr1s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Ffr1&headerType=none&quicSecurity=none&serviceName=&security=tls&fp=chrome&insecure=0&sni=#法国高速01',
    ];

    for (final link in builtInLinks) {
      try {
        ProxyServer server;
        if (link.startsWith('hysteria2://')) {
          server = ProxyServer.fromHysteria2Link(link);
        } else if (link.startsWith('vless://')) {
          server = ProxyServer.fromVlessLink(link);
        } else {
          continue;
        }
        _servers.add(server);
      } catch (e) {
        Logger.error('Failed to parse built-in link: $e');
      }
    }

    // 默认选择第一个节点
    if (_servers.isNotEmpty) {
      _selectedServer = _servers.first;
    }
  }

  void selectServer(ProxyServer server) {
    _selectedServer = server;
    notifyListeners();
  }

  Future<void> connect() async {
    if (_selectedServer == null) {
      _errorMessage = '请先选择一个节点';
      notifyListeners();
      return;
    }

    _isConnecting = true;
    _connectionStatus = '连接中...';
    _errorMessage = '';
    notifyListeners();

    try {
      // 模拟连接过程
      await Future.delayed(const Duration(seconds: 2));
      
      _isConnected = true;
      _connectionStatus = '已连接';
      _isConnecting = false;
      
      // 模拟速度监控
      _startSpeedMonitoring();
      
      Logger.info('Connected to ${_selectedServer!.name}');
    } catch (e) {
      _isConnecting = false;
      _connectionStatus = '连接失败';
      _errorMessage = '连接失败: $e';
      Logger.error('Connection failed: $e');
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      _isConnected = false;
      _connectionStatus = '未连接';
      _downloadSpeed = 0.0;
      _uploadSpeed = 0.0;
      _errorMessage = '';
      Logger.info('Disconnected');
    } catch (e) {
      Logger.error('Failed to disconnect: $e');
    }
    notifyListeners();
  }

  void _startSpeedMonitoring() {
    // 模拟速度监控
    Future.doWhile(() async {
      if (!_isConnected) return false;
      
      try {
        // 模拟速度数据
        _downloadSpeed = 1024 * 1024 * (1 + DateTime.now().millisecond % 5); // 1-5 MB/s
        _uploadSpeed = 1024 * 512 * (1 + DateTime.now().millisecond % 3); // 0.5-1.5 MB/s
        notifyListeners();
      } catch (e) {
        Logger.error('Failed to get speed: $e');
      }
      
      await Future.delayed(const Duration(seconds: 1));
      return _isConnected;
    });
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}