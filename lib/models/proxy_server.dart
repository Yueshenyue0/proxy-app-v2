/// 代理节点数据模型
/// 支持从 hysteria2:// 与 vless:// 分享链接解析
class ProxyServer {
  /// 节点显示名称（链接 # 后面的片段）
  final String name;

  /// 服务器地址
  final String address;

  /// 端口
  final int port;

  /// 协议标识：'hysteria2' / 'vless'
  final String protocol;

  /// 密码 / UUID
  final String secret;

  /// 原始分享链接
  final String link;

  /// 额外参数（sni、pinSHA256、type、host、path 等）
  final Map<String, String> params;

  const ProxyServer({
    required this.name,
    required this.address,
    required this.port,
    required this.protocol,
    this.secret = '',
    this.link = '',
    this.params = const {},
  });

  /// 协议展示名
  String get protocolDisplay {
    switch (protocol) {
      case 'hysteria2':
        return 'Hysteria2';
      case 'vless':
        return 'VLESS';
      default:
        return protocol.toUpperCase();
    }
  }

  /// 解析 hysteria2://<密码>@<host>:<port>/?<参数>#<名称>
  factory ProxyServer.fromHysteria2Link(String link) {
    final uri = Uri.parse(link);
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'hysteria2' && scheme != 'hy2') {
      throw FormatException('不是有效的 Hysteria2 链接: $link');
    }

    final host = uri.host;
    if (host.isEmpty) {
      throw FormatException('Hysteria2 链接缺少服务器地址');
    }

    final port = uri.hasPort ? uri.port : 443;

    // userinfo 中可能带百分号编码的密码
    final secret = Uri.decodeComponent(uri.userInfo.split('@').last);

    // 参数：query 部分
    final params = <String, String>{};
    uri.queryParameters.forEach((k, v) => params[k] = v);

    // 名称：fragment
    final name = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '$host:$port';

    return ProxyServer(
      name: name,
      address: host,
      port: port,
      protocol: 'hysteria2',
      secret: secret,
      link: link,
      params: params,
    );
  }

  /// 解析 vless://<uuid>@<host>:<port>?<参数>#<名称>
  factory ProxyServer.fromVlessLink(String link) {
    final uri = Uri.parse(link);
    if (uri.scheme.toLowerCase() != 'vless') {
      throw FormatException('不是有效的 VLESS 链接: $link');
    }

    final host = uri.host;
    if (host.isEmpty) {
      throw FormatException('VLESS 链接缺少服务器地址');
    }

    final port = uri.hasPort ? uri.port : 443;

    // userinfo 是 UUID（可能含百分号编码）
    final uuid = uri.userInfo.isNotEmpty
        ? Uri.decodeComponent(uri.userInfo.split('@').first)
        : '';

    final params = <String, String>{};
    uri.queryParameters.forEach((k, v) => params[k] = v);

    final name = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '$host:$port';

    return ProxyServer(
      name: name,
      address: host,
      port: port,
      protocol: 'vless',
      secret: uuid,
      link: link,
      params: params,
    );
  }

  /// 通用入口：自动按前缀识别协议
  factory ProxyServer.fromLink(String link) {
    final trimmed = link.trim();
    if (trimmed.startsWith('hysteria2://') || trimmed.startsWith('hy2://')) {
      return ProxyServer.fromHysteria2Link(trimmed);
    }
    if (trimmed.startsWith('vless://')) {
      return ProxyServer.fromVlessLink(trimmed);
    }
    throw FormatException('不支持的链接协议: $trimmed');
  }

  @override
  String toString() => '$protocolDisplay $name ($address:$port)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProxyServer &&
        other.protocol == protocol &&
        other.address == address &&
        other.port == port &&
        other.name == name;
  }

  @override
  int get hashCode =>
      Object.hash(protocol, address, port, name);
}