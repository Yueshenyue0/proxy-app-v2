import 'package:flutter/foundation.dart';
import 'package:flutter_vless/flutter_vless.dart';
import '../models/proxy_server.dart';
import '../utils/logger.dart';

/// 代理状态管理：基于 flutter_vless（Xray 内核）实现真实 VPN 连接
class ProxyProvider extends ChangeNotifier {
  final List<ProxyServer> _servers = [];
  ProxyServer? _selectedServer;
  VlessStatus _status = VlessStatus();
  String _errorMessage = '';
  bool _initialized = false;
  String? _coreVersion;

  late final FlutterVless _vless = FlutterVless(
    onStatusChanged: (status) {
      _status = status;
      notifyListeners();
    },
  );

  List<ProxyServer> get servers => List.unmodifiable(_servers);
  ProxyServer? get selectedServer => _selectedServer;
  VlessStatus get status => _status;
  String get errorMessage => _errorMessage;
  String? get coreVersion => _coreVersion;

  bool get isConnected =>
      _status.connectionState == VlessConnectionState.connected;
  bool get isConnecting =>
      _status.connectionState == VlessConnectionState.connecting;
  bool get isDisconnecting =>
      _status.connectionState == VlessConnectionState.disconnecting;
  bool get isActive => isConnected || isConnecting || isDisconnecting;

  /// 当前状态中文文案
  String get statusText {
    if (isConnecting) return '连接中';
    if (isDisconnecting) return '断开中';
    if (isConnected) return '已连接';
    return '未连接';
  }

  double get downloadSpeed => _toD(_status.downloadSpeed);
  double get uploadSpeed => _toD(_status.uploadSpeed);
  int? get downloadTraffic => _toI(_status.download);
  int? get uploadTraffic => _toI(_status.upload);
  int? get durationSeconds => _toI(_status.duration);

  static double _toD(dynamic v) {
    if (v is num) return v.toDouble();
    return 0.0;
  }

  static int? _toI(dynamic v) => v is num ? v.toInt() : null;

  ProxyProvider() {
    _loadBuiltInServers();
    _init();
  }

  Future<void> _init() async {
    try {
      await _vless.initializeVless(
        notificationIconResourceType: 'mipmap',
        notificationIconResourceName: 'ic_launcher',
        providerBundleIdentifier: 'com.eri.proxyAppTunnel',
        groupIdentifier: 'group.com.eri.proxyapp',
      );
      _initialized = true;
      try {
        _coreVersion = await _vless.getCoreVersion();
      } catch (_) {}
      notifyListeners();
    } catch (e) {
      Logger.error('内核初始化失败: $e');
    }
  }

  void _loadBuiltInServers() {
    final builtInLinks = [
      // Hysteria2 节点
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@132.145.137.155:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=13a95d801c2b834991f49ce6c6fe754809f8ca2dbf52a4dbc1aeb6885b46cb27&mport=51000-53000#美国专线01',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@129.146.124.201:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=d97a9e258f15741cbdbee2ccb4580b20abec969ca70f272f4c1970dfce944ff1&mport=51000-53000#美国专线02',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@159.13.40.81:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=9b92e6da557f1d4cc0c698d135154f07b8ab39f67d5714ce841b21a324a03b33&mport=51000-53000#澳大利亚专线01',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@192.9.179.140:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=8d120b1449b52fe48e98e41c7ee5c0c471574179d5b2e968ba3db5f7575a63a4&mport=51000-53000#澳大利亚专线02',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@144.24.109.215:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=236656426d6094bd5dac2054533d713854d14ce89a41ca0da7e9a6a14d2a7edf&mport=51000-53000#印度专线01',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@141.148.222.181:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=3657f3d6126f53ae984af56c82b7744ca55f31f49dea560996112af192ed1177&mport=51000-53000#印度专线02',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@168.75.68.172:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=615b8e1622a98c5f1da3c923bb64b07bd04749146b33a134125dc1a6920ba04c&mport=51000-53000#巴西专线01',
      'hysteria2://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@144.22.197.28:51000/?insecure=false&sni=cn.cremedelamer.com&pinSHA256=395981c03224ffc29cdda4e168cada627e08bba5af89cc711e6c136580445bf4&mport=51000-53000#巴西专线02',
      // VLESS 节点
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=us1s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fus1&headerType=none&security=tls&fp=chrome&sni=us1s.xn--mirrors-oj8km52txc7d.com#美国高速01',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=us2s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fus2&headerType=none&security=tls&fp=chrome&sni=us2s.xn--mirrors-oj8km52txc7d.com#美国高速02',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=in1s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fin1&headerType=none&security=tls&fp=chrome&sni=in1s.xn--mirrors-oj8km52txc7d.com#印度高速01',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=au1s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fau1&headerType=none&security=tls&fp=chrome&sni=au1s.xn--mirrors-oj8km52txc7d.com#澳大利亚高速01',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=au2s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Fau2&headerType=none&security=tls&fp=chrome&sni=au2s.xn--mirrors-oj8km52txc7d.com#澳大利亚高速02',
      'vless://0cc79829-08fb-420b-b289-6f2b8aa5f8b8@63.141.128.158:443?type=ws&encryption=none&host=fr1s.xn--mirrors-oj8km52txc7d.com&path=%2Fym%2Ffr1&headerType=none&security=tls&fp=chrome&sni=fr1s.xn--mirrors-oj8km52txc7d.com#法国高速01',
    ];

    for (final link in builtInLinks) {
      try {
        ProxyServer server;
        if (link.startsWith('hysteria2://') || link.startsWith('hy2://')) {
          server = ProxyServer.fromHysteria2Link(link);
        } else if (link.startsWith('vless://')) {
          server = ProxyServer.fromVlessLink(link);
        } else {
          continue;
        }
        _servers.add(server);
      } catch (e) {
        Logger.error('内置链接解析失败: $e');
      }
    }

    if (_servers.isNotEmpty) {
      _selectedServer = _servers.first;
    }
  }

  void selectServer(ProxyServer server) {
    if (_selectedServer == server) return;
    _selectedServer = server;
    _errorMessage = '';
    notifyListeners();
  }

  /// 真实连接：解析分享链接 → 申请 VPN 权限 → 启动 Xray 隧道
  Future<void> connect() async {
    final server = _selectedServer;
    if (server == null) {
      _errorMessage = '请先选择一个节点';
      notifyListeners();
      return;
    }

    _errorMessage = '';
    notifyListeners();

    try {
      if (!_initialized) {
        await _init();
      }

      final parsed = FlutterVless.parse(server.link);
      final config = parsed.getFullConfiguration();

      final granted = await _vless.requestPermission();
      if (!granted) {
        _errorMessage = '未授予 VPN 权限，无法建立连接';
        notifyListeners();
        return;
      }

      await _vless.startVless(
        remark: server.name,
        config: config,
        notificationDisconnectButtonName: '断开',
      );
      Logger.info('正在连接: ${server.name}');
    } catch (e) {
      _errorMessage = '连接失败: $e';
      Logger.error('连接失败: $e');
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _vless.stopVless();
      Logger.info('已断开连接');
    } catch (e) {
      _errorMessage = '断开失败: $e';
      Logger.error('断开失败: $e');
      notifyListeners();
    }
  }

  /// 切换连接/断开
  Future<void> toggle() async {
    if (isActive) {
      await disconnect();
    } else {
      await connect();
    }
  }

  /// 测试某个节点延迟（毫秒），-1 表示失败
  Future<int> testDelay(ProxyServer server) async {
    try {
      final parsed = FlutterVless.parse(server.link);
      final config = parsed.getFullConfiguration();
      if (isConnected && _selectedServer == server) {
        return await _vless.getConnectedServerDelay();
      }
      return await _vless.getServerDelay(config: config);
    } catch (e) {
      Logger.error('延迟测试失败: $e');
      return -1;
    }
  }

  void clearError() {
    if (_errorMessage.isEmpty) return;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    try {
      _vless.stopVless();
    } catch (_) {}
    super.dispose();
  }
}