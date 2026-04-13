import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/training_lock_provider.dart';

/// 训练锁定设置页面
/// 家长可设置训练防中断功能
class TrainingLockScreen extends StatefulWidget {
  const TrainingLockScreen({super.key});

  @override
  State<TrainingLockScreen> createState() => _TrainingLockScreenState();
}

class _TrainingLockScreenState extends State<TrainingLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainingLockProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('训练锁定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Consumer<TrainingLockProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 说明卡片
              _buildInfoCard(),
              const SizedBox(height: 24),

              // 锁定开关
              _buildLockToggle(provider),
              const SizedBox(height: 24),

              // 锁定时长设置
              if (provider.lockEnabled) ...[
                _buildDurationSection(provider),
                const SizedBox(height: 24),
                _buildDurationOptions(provider),
              ],

              const SizedBox(height: 24),

              // 注意事项
              _buildNotes(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90D9), Color(0xFF6C63FF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_clock, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '训练防中断',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  '开启后训练过程中无法退出，帮助孩子专注训练',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockToggle(TrainingLockProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: provider.lockEnabled ? const Color(0xFF4A90D9).withOpacity(0.15) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              provider.lockEnabled ? Icons.lock : Icons.lock_open,
              color: provider.lockEnabled ? const Color(0xFF4A90D9) : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('开启训练锁定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  provider.lockEnabled ? '训练期间无法退出应用' : '关闭后可随时退出训练',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch(
            value: provider.lockEnabled,
            onChanged: (value) => provider.setLockEnabled(value),
            activeColor: const Color(0xFF4A90D9),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection(TrainingLockProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('锁定时长', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(
          '设置本次训练的锁定时长，超时后自动解除锁定',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDurationOptions(TrainingLockProvider provider) {
    final options = [
      {'value': 15, 'label': '15分钟', 'icon': Icons.timer},
      {'value': 30, 'label': '30分钟', 'icon': Icons.timer},
      {'value': 45, 'label': '45分钟', 'icon': Icons.timer},
      {'value': 60, 'label': '1小时', 'icon': Icons.access_time},
      {'value': 90, 'label': '1.5小时', 'icon': Icons.access_time},
      {'value': 120, 'label': '2小时', 'icon': Icons.access_time},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: options.map((opt) {
          final isSelected = provider.lockDuration == opt['value'];
          return InkWell(
            onTap: () => provider.setLockDuration(opt['value'] as int),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4A90D9).withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    color: isSelected ? const Color(0xFF4A90D9) : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color(0xFF4A90D9) : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Color(0xFF4A90D9), size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                '注意事项',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNoteItem('1. 训练锁定仅在训练进行中生效'),
          _buildNoteItem('2. 应用退到后台会自动暂停训练'),
          _buildNoteItem('3. 超时后锁定自动解除'),
          _buildNoteItem('4. 紧急情况下可强制退出应用'),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.amber.shade900, height: 1.4),
      ),
    );
  }
}
