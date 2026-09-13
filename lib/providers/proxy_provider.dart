import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_vless/flutter_vless.dart';
import '../models/proxy_server.dart';
import '../utils/logger.dart';

/// 代理状态管理：基于 flutter_vless（内嵌 Xray 内核）实现真实 VPN 连接
class ProxyProvider extends ChangeNotifier {
  ProxyProvider() {
    _loadBuiltInServers();
    _init();
  }

  // ── 测速地址 ────────────────────────────────────────────────────────────
  // 插件的 getServerDelay 只要求"能拿到 HTTP 响应"，不校验状态码。
  // 默认值 google.com 在大陆不可达，会直接返回 -1（表现为"全部超时"），
  // 因此这里换成国内稳定可达的地址，并逐个降级尝试。
  static const List<String> _delayUrls = [
    'https://www.baidu.com',
    'https://www.qq.com',
    'https://www.taobao.com',
    'https://generate_204.com/',
    'https://www.google.com/generate_204',
  ];

  final List<ProxyServer> _servers = [];
  ProxyServer? _selectedServer;

  VlessStatus _status = VlessStatus();
  String _errorMessage = '';
  bool _initialized = false;
  bool _initializing = false;
  String? _coreVersion;

  /// 会话已由本端发起（用于内核未推送状态事件时的兜底显示）
  bool _sessionRequested = false;

  /// 互斥：测速会临时起/杀一个 Xray 进程，必须与连接、与彼此串行
  bool _busy = false;

  /// 连接超时兜底：内核起不来时不让 UI 永远卡在"连接中"
  Timer? _connectTimer;
  static const Duration _connectTimeout = Duration(seconds: 20);

  late final FlutterVless _vless = FlutterVless(
    onStatusChanged: (status) {
      _status = status;
      if (status.connectionState == VlessConnectionState.connected) {
        // 内核确认可用：结束乐观"连接中"，撤销超时兜底
        _sessionRequested = false;
        _connectTimer?.cancel();
        _connectTimer = null;
      }
      // 注意：不在 disconnected 分支清 _sessionRequested，
      // 因为内核冷启动过程中也会推 disconnected，清掉会让按钮
      // 在权限弹窗/启动期间退回"未连接"，表现为"点了没反应"。
      notifyListeners();
    },
  );

  // ── 对外只读状态 ────────────────────────────────────────────────────────
  List<ProxyServer> get servers => List.unmodifiable(_servers);
  ProxyServer? get selectedServer => _selectedServer;
  String get errorMessage => _errorMessage;
  String? get coreVersion => _coreVersion;
  bool get busy => _busy;

  VlessConnectionState get _kernelState => _status.connectionState;

  /// 已连接：只信内核上报的状态，避免乐观误判成绿色
  bool get isConnected => _kernelState == VlessConnectionState.connected;

  /// 连接中：本端已发起且内核尚未确认 connected
  /// （权限弹窗、内核冷启动期间内核仍是 disconnected，
  ///  没有这个标记就会表现为「点了没反应」）
  bool get isConnecting => _sessionRequested && !isConnected;

  bool get isDisconnecting => _kernelState == VlessConnectionState.disconnecting;

  bool get isActive => isConnected || isConnecting || isDisconnecting;

  String get statusText {
    if (isConnected) return '已连接';
    if (isDisconnecting) return '断开中';
    if (isConnecting) return '连接中';
    return '未连接';
  }

  double get downloadSpeed => _status.downloadSpeed.toDouble();
  double get uploadSpeed => _status.uploadSpeed.toDouble();
  int? get downloadTraffic => _status.download;
  int? get uploadTraffic => _status.upload;
  int? get durationSeconds => _status.duration;

  // ── 内核初始化 ─────────────────────────────────────────────────────────
  Future<void> _init() async {
    if (_initialized || _initializing) return;
    _initializing = true;
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
        Logger.info('Xray 内核版本: $_coreVersion');
      } catch (_) {}
      notifyListeners();
    } catch (e) {
      Logger.error('内核初始化失败: $e');
    } finally {
      _initializing = false;
    }
  }

  // ── 内置节点 ───────────────────────────────────────────────────────────
  // 注意：Xray 的 Hysteria2 读取的证书固定参数名是 `pcs` /
  // `pinnedPeerCertSha256`，而不是其他客户端常用的 `pinSHA256`。
  // 若沿用 pinSHA256，pin 会被静默丢弃，配合 insecure=false 必然握手失败。
  void _loadBuiltInServers() {
    final builtInLinks = [
      // Hysteria2
      _hy2('132.145.137.155', '13a95d801c2b834991f49ce6c6fe754809f8ca2dbf52a4dbc1aeb6885b46cb27', '美国专线01'),
      _hy2('129.146.124.201', 'd97a9e258f15741cbdbee2ccb4580b20abec969ca70f272f4c1970dfce944ff1', '美国专线02'),
      _hy2('159.13.40.81', '9b92e6da557f1d4cc0c698d135154f07b8ab39f67d5714ce841b21a324a03b33', '澳大利亚专线01'),
      _hy2('192.9.179.140', '8d120b1449b52fe48e98e41c7ee5c0c471574179d5b2e968ba3db5f7575a63a4', '澳大利亚专线02'),
      _hy2('144.24.109.215', '236656426d6094bd5dac2054533d713854d14ce89a41ca0da7e9a6a14d2a7edf', '印度专线01'),
      _hy2('141.148.222.181', '3657f3d6126f53ae984af56c82b7744ca55f31f49dea560996112af192ed1177', '印度专线02'),
      _hy2('168.75.68.172', '615b8e1622a98c5f1da3c923bb64b07bd04749146b33a134125dc1a6920ba04c', '巴西专线01'),
      _hy2('144.22.197.28', '395981c03224ffc29cdda4e168cada627e08bba5af89cc711e6c136580445bf4', '巴西专线02'),
      // VLESS（sni 必须给真实值，空 sni= 会导致 TLS 校验失败）
      _vlessLink('us1s', '美国高速01'),
      _vlessLink('us2s', '美国高速02'),
      _vlessLink('in1s', '印度高速01'),
      _vlessLink('au1s', '澳大利亚高速01'),
      _vlessLink('au2s', '澳大利亚高速02'),
      _vlessLink('fr1s', '法国高速01'),
    ];

    for (final link in builtInLinks) {
      try {
        _servers.add(ProxyServer.fromLink(link));
      } catch (e) {
        Logger.error('内置链接解析失败: $e');
      }
    }

    if (_servers.isNotEmpty) {
      _selectedServer = _servers.first;
    }
    Logger.info('内置节点载入完成: ${_servers.length} 个');
  }

  static const String _hy2Uuid = '0cc79829-08fb-420b-b289-6f2b8aa5f8b8';
  static const String _hy2Sni = 'cn.cremedelamer.com';

  static String _hy2(String ip, String pin, String name) =>
      'hysteria2://$_hy2Uuid@$ip:51000/'
      '?insecure=false&sni=$_hy2Sni&pcs=$pin&mport=51000-53000#$name';

  /// 证书轮换时 pin 会失配，用于失败后的降级重试
  static String _hy2NoVerify(String ip, String name) =>
      'hysteria2://$_hy2Uuid@$ip:51000/'
      '?insecure=true&sni=$_hy2Sni&mport=51000-53000#$name';

  static const String _vlUuid = '0cc79829-08fb-420b-b289-6f2b8aa5f8b8';
  static const String _vlHost = 'xn--mirrors-oj8km52txc7d.com';

  static String _vlessLink(String prefix, String name) =>
      'vless://$_vlUuid@63.141.128.158:443'
      '?type=ws&encryption=none&host=$prefix.$_vlHost'
      '&path=%2Fym%2F$prefix&headerType=none'
      '&security=tls&fp=chrome&sni=$prefix.$_vlHost#$name';

  /// 找到某个 hysteria2 节点对应的"跳过校验"降级链接
  String? _fallbackLinkFor(ProxyServer server) {
    if (server.protocol != 'hysteria2') return null;
    final name = server.name;
    final ip = server.address;
    return _hy2NoVerify(ip, name);
  }

  // ── 选择节点 ───────────────────────────────────────────────────────────
  void selectServer(ProxyServer server) {
    if (_selectedServer == server) return;
    _selectedServer = server;
    _errorMessage = '';
    notifyListeners();
  }

  // ── 连接 ───────────────────────────────────────────────────────────────
  Future<void> connect() async {
    final server = _selectedServer;
    if (server == null) {
      _errorMessage = '请先选择一个节点';
      notifyListeners();
      return;
    }
    if (_busy) {
      _errorMessage = '有操作正在进行，请稍候…';
      notifyListeners();
      return;
    }
    if (isActive) {
      await disconnect();
      return;
    }

    _busy = true;
    _errorMessage = '';
    _sessionRequested = true; // 立即进入"连接中"，避免点了没反馈
    _armConnectTimer();
    notifyListeners();

    try {
      await _init();

      // 1) 先按原始链接（带证书固定）尝试
      var ok = await _tryStart(server.link, server.name);

      // 2) Hysteria2 证书固定失配时，降级为跳过校验再试一次
      if (!ok) {
        final fb = _fallbackLinkFor(server);
        if (fb != null) {
          Logger.info('证书固定校验未通过，使用跳过校验模式重试');
          _stopQuietly();
          await Future.delayed(const Duration(milliseconds: 400));
          ok = await _tryStart(fb, server.name);
          if (ok) {
            _errorMessage = '${server.name} 已连接（证书固定失配，已降级校验）';
          }
        }
      }

      if (!ok) {
        _sessionRequested = false;
        if (_errorMessage.isEmpty) {
          _errorMessage = '${server.name} 连接失败，请尝试其他节点';
        }
      }
    } catch (e) {
      _sessionRequested = false;
      _errorMessage = '连接失败: $e';
      Logger.error('连接失败: $e');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// 启动连接超时兜底：到点仍未 connected 就判失败并收回隧道
  void _armConnectTimer() {
    _connectTimer?.cancel();
    _connectTimer = Timer(_connectTimeout, () {
      if (_kernelState == VlessConnectionState.connected) return;
      Logger.warning('连接超时（${_connectTimeout.inSeconds}s 内内核未就绪）');
      _sessionRequested = false;
      _errorMessage = '连接超时：内核未能在规定时间内建立隧道，'
          '可能是证书固定失配或服务器不可达，请尝试其他节点';
      _stopQuietly();
      notifyListeners();
    });
  }

  /// 返回 true 表示内核已接受该配置
  Future<bool> _tryStart(String link, String remark) async {
    try {
      final parsed = FlutterVless.parse(link);
      final config = parsed.getFullConfiguration();

      final granted = await _vless.requestPermission();
      if (!granted) {
        _errorMessage = '未授予 VPN 权限，无法建立连接';
        return false;
      }

      await _vless.startVless(
        remark: remark,
        config: config,
        notificationDisconnectButtonName: '断开',
      );
      Logger.info('内核已启动: $remark');
      return true;
    } catch (e) {
      Logger.error('startVless 失败: $e');
      _errorMessage = '内核启动失败: $e';
      return false;
    }
  }

  void _stopQuietly() {
    try {
      _vless.stopVless();
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _busy = true;
    _connectTimer?.cancel();
    _connectTimer = null;
    try {
      await _vless.stopVless();
      Logger.info('已断开连接');
    } catch (e) {
      Logger.error('断开失败: $e');
    } finally {
      _sessionRequested = false;
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (isActive) {
      await disconnect();
    } else {
      await connect();
    }
  }

  // ── 延迟测试 ───────────────────────────────────────────────────────────
  /// 返回毫秒；-1 表示不可达
  Future<int> testDelay(ProxyServer server) async {
    if (_busy) return -2; // 忙，稍后再试

    _busy = true;
    notifyListeners();
    try {
      await _init();
      // 已连接且是同一节点：走现有隧道测速
      if (_kernelState == VlessConnectionState.connected &&
          _selectedServer == server) {
        for (final url in _delayUrls) {
          try {
            final d = await _vless
                .getConnectedServerDelay(url: url)
                .timeout(const Duration(seconds: 8));
            if (d >= 0) return d;
          } catch (_) {}
        }
        return -1;
      }

      final links = <String>[server.link];
      final fb = _fallbackLinkFor(server);
      if (fb != null) links.add(fb);

      for (final link in links) {
        String config;
        try {
          config = FlutterVless.parse(link).getFullConfiguration();
        } catch (_) {
          continue;
        }
        for (final url in _delayUrls) {
          try {
            final d = await _vless
                .getServerDelay(config: config, url: url)
                .timeout(const Duration(seconds: 10));
            if (d >= 0) return d;
          } catch (_) {}
        }
      }
      return -1;
    } catch (e) {
      Logger.error('延迟测试失败: $e');
      return -1;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage.isEmpty) return;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _connectTimer?.cancel();
    _stopQuietly();
    super.dispose();
  }
}