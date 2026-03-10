import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/template_provider.dart';

/// 模板管理页面
class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  State<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  @override
  void initState() {
    super.initState();
    // 加载模板列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().loadTemplates();
    });
  }

  Future<void> _deleteTemplate(Template template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除模板"${template.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<TemplateProvider>().deleteTemplate(template.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模板管理'),
      ),
      body: Consumer<TemplateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.templates.isEmpty) {
            return const Center(
              child: Text(
                '暂无模板\n创建多天计划时可保存为模板',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.templates.length,
            itemBuilder: (context, index) {
              final template = provider.templates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(template.name),
                  subtitle: Text('${template.daysCount}天 • ${template.dosages.join("、")}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteTemplate(template),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
