import 'package:flutter/material.dart';
import '../models/proxy_server.dart';

class ServerSelector extends StatelessWidget {
  final List<ProxyServer> servers;
  final ProxyServer? selectedServer;
  final Function(ProxyServer) onServerSelected;
  final VoidCallback onAddServer;

  const ServerSelector({
    super.key,
    required this.servers,
    this.selectedServer,
    required this.onServerSelected,
    required this.onAddServer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '选择节点',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: onAddServer,
              icon: const Icon(Icons.add),
              label: const Text('添加'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (servers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 10),
                Text(
                  '暂无节点',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '点击上方"添加"按钮添加节点',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: servers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final server = servers[index];
                final isSelected = selectedServer == server;
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.dns,
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    server.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${server.address}:${server.port}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getProtocolColor(server.protocol).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          server.protocolDisplay,
                          style: TextStyle(
                            color: _getProtocolColor(server.protocol),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                  onTap: () => onServerSelected(server),
                );
              },
            ),
          ),
      ],
    );
  }

  Color _getProtocolColor(String protocol) {
    switch (protocol) {
      case 'hysteria2':
        return Colors.purple;
      case 'vless':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }
}