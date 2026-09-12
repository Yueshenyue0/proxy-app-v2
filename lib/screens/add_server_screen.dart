import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide ProxyProvider;
import '../providers/proxy_provider.dart';

class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _subscriptionController = TextEditingController();
  bool _isAddingFromLink = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加节点'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tab切换
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAddingFromLink = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isAddingFromLink 
                              ? Theme.of(context).primaryColor 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '从链接添加',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isAddingFromLink ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAddingFromLink = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isAddingFromLink 
                              ? Theme.of(context).primaryColor 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '从订阅添加',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isAddingFromLink ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 内容区域
            Expanded(
              child: _isAddingFromLink 
                  ? _buildLinkTab() 
                  : _buildSubscriptionTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '粘贴代理链接',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '支持 Hysteria2 和 VLESS 协议链接',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TextField(
            controller: _linkController,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: 'hysteria2://...\nvless://...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _addFromLink,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '添加节点',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '订阅链接',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '输入订阅地址，自动导入所有节点',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _subscriptionController,
          decoration: InputDecoration(
            hintText: 'https://example.com/subscription',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _addFromSubscription,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '导入订阅',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _addFromLink() {
    if (_linkController.text.isNotEmpty) {
      final links = _linkController.text.split('\n');
      for (var link in links) {
        link = link.trim();
        if (link.isNotEmpty) {
          context.read<ProxyProvider>().addServerFromLink(link);
        }
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('节点添加成功')),
      );
    }
  }

  void _addFromSubscription() {
    if (_subscriptionController.text.isNotEmpty) {
      context.read<ProxyProvider>().addServersFromSubscription(
        _subscriptionController.text,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('订阅导入成功')),
      );
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _subscriptionController.dispose();
    super.dispose();
  }
}