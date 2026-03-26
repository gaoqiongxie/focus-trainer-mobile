import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/training_provider.dart';
import '../providers/reward_provider.dart';
import '../config/app_config.dart';

class TrainingScreen extends StatefulWidget {
  final int trainingType;
  final int level;
  final int duration;

  const TrainingScreen({
    super.key,
    required this.trainingType,
    required this.level,
    required this.duration,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> with TickerProviderStateMixin {
  bool _isTraining = false;
  bool _isCompleted = false;
  int _remainingSeconds = 0;
  int _interruptCount = 0;
  Timer? _timer;
  Map<String, dynamic>? _record;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startTraining() async {
    final provider = context.read<TrainingProvider>();
    final record = await provider.startTraining(widget.trainingType, widget.level, widget.duration);
    
    if (record != null) {
      setState(() {
        _isTraining = true;
        _record = record;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _completeTraining();
        }
      });
    });
  }

  Future<void> _completeTraining() async {
    _timer?.cancel();
    
    final actualDuration = widget.duration - _remainingSeconds;
    // 模拟正确率和分数（实际应由训练逻辑计算）
    final accuracy = 75.0 + (_interruptCount == 0 ? 15.0 : 0.0);
    final score = (accuracy * widget.level).round();

    final provider = context.read<TrainingProvider>();
    final success = await provider.completeTraining(
      _record!['recordId'],
      actualDuration,
      _interruptCount,
      accuracy,
      score,
    );

    if (success) {
      await context.read<RewardProvider>().loadStarCount();
      if (mounted) {
        setState(() => _isCompleted = true);
        _animController.forward();
      }
    }
  }

  void _interruptTraining() {
    _interruptCount++;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('注意保持专注哦！'), duration: Duration(seconds: 2)),
    );
  }

  void _quitTraining() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_remainingSeconds / widget.duration);

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return _buildResultScreen();
    if (_isTraining) return _buildTrainingScreen();
    return _buildReadyScreen();
  }

  /// 准备界面
  Widget _buildReadyScreen() {
    final typeName = AppConfig.trainingTypes[widget.trainingType] ?? '训练';
    final typeColor = AppConfig.trainingColors[widget.trainingType] ?? Colors.blue;

    return Scaffold(
      appBar: AppBar(title: Text(typeName), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(Icons.play_arrow, size: 60, color: typeColor),
              ),
              const SizedBox(height: 24),
              Text(typeName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('难度等级 ${widget.level}', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text('训练时长 ${_formatTime(widget.duration)}', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startTraining,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text('开始训练', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 训练进行中界面
  Widget _buildTrainingScreen() {
    final typeColor = AppConfig.trainingColors[widget.trainingType] ?? Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('训练中...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _quitTraining,
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          _interruptTraining();
          return false;
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 圆形进度
              SizedBox(
                width: 200, height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200, height: 200,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                      ),
                    ),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '保持专注，你做得很棒！',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              // 暂停/中断按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _interruptTraining,
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('暂时离开'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                      backgroundColor: Colors.red.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _completeTraining,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('提前完成'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.green,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 训练完成结果界面
  Widget _buildResultScreen() {
    final rewardProvider = context.read<RewardProvider>();
    final actualDuration = widget.duration - _remainingSeconds;
    final earnedStars = (actualDuration ~/ 60 * 2) + (_interruptCount == 0 ? 5 : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('训练完成'), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Icon(Icons.celebration, size: 80, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 16),
              const Text('太棒了！训练完成！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _buildResultItem('⏱️ 训练时长', _formatTime(actualDuration)),
              _buildResultItem('⚠️ 中断次数', '$_interruptCount 次'),
              _buildResultItem('⭐ 获得星星', '+$earnedStars'),
              _buildResultItem('🔥 总星星数', '${rewardProvider.starCount}'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text('返回首页', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
