import 'package:flutter/material.dart';

/// 逐天剂量设置页面
class DailyDoseScreen extends StatefulWidget {
  /// 初始剂量列表（如果有）
  final List<String> initialDosages;
  /// 总天数
  final int daysCount;
  /// 默认剂量
  final String defaultDosage;

  const DailyDoseScreen({
    super.key,
    this.initialDosages = const [],
    required this.daysCount,
    this.defaultDosage = '1片',
  });

  @override
  State<DailyDoseScreen> createState() => _DailyDoseScreenState();
}

class _DailyDoseScreenState extends State<DailyDoseScreen> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(widget.daysCount, (index) {
      final text = widget.initialDosages.length > index
          ? widget.initialDosages[index]
          : widget.defaultDosage;
      return TextEditingController(text: text);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 获取所有剂量
  List<String> get dosages {
    return _controllers.map((c) => c.text).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日剂量设置'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(dosages);
            },
            child: const Text('完成'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.daysCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: _controllers[index],
              decoration: InputDecoration(
                labelText: '第${index + 1}天',
                hintText: '如：2片、1粒',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.medication),
              ),
            ),
          );
        },
      ),
    );
  }
}
