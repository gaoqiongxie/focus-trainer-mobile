import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/reward_provider.dart';
import '../../utils/audio_service.dart';

/// 听觉专注训练 - 声音序列记忆
/// 听到一组动物叫声序列后，按正确顺序复现
/// 难度: 初级(3个) / 中级(5个) / 高级(7个)
class SoundSequenceScreen extends StatefulWidget {
  final int level; // 1=初级, 2=中级, 3=高级

  const SoundSequenceScreen({
    super.key,
    required this.level,
  });

  @override
  State<SoundSequenceScreen> createState() => _SoundSequenceScreenState();
}

class _SoundSequenceScreenState extends State<SoundSequenceScreen>
    with TickerProviderStateMixin {
  // 难度配置
  static const Map<int, int> _seqLengths = {1: 3, 2: 5, 3: 7};
  static const Map<int, int> _roundCounts = {1: 5, 2: 5, 3: 5};
  static const Map<int, String> _levelNames = {
    1: '初级 3音序',
    2: '中级 5音序',
    3: '高级 7音序'
  };

  // 动物声音配置: emoji + 名称 + 颜色
  static const List<Map<String, dynamic>> _animals = [
    {'emoji': '🐶', 'name': '小狗', 'color': 0xFF8B6914},
    {'emoji': '🐱', 'name': '小猫', 'color': 0xFFFF8C42},
    {'emoji': '🐸', 'name': '青蛙', 'color': 0xFF4CAF50},
    {'emoji': '🐦', 'name': '小鸟', 'color': 0xFF42A5F5},
    {'emoji': '🐔', 'name': '小鸡', 'color': 0xFFFFD54F},
    {'emoji': '🐷', 'name': '小猪', 'color': 0xFFEC407A},
    {'emoji': '🐮', 'name': '奶牛', 'color': 0xFF795548},
    {'emoji': '🐴', 'name': '小马', 'color': 0xFF9E9E9E},
  ];

  // 游戏阶段: ready -> listen -> replay -> result
  String _phase = 'ready';

  late int _seqLength;
  late int _totalRounds;
  late int _currentRound;

  // 当前轮数据
  List<int> _currentSequence = []; // 正确序列(动物索引)
  List<int> _userSequence = []; // 用户输入序列
  int _listenIndex = 0; // 正在播放到第几个
  bool _isListening = false;

  int _correctRounds = 0;
  int _totalScore = 0;
  List<Map<String, dynamic>> _roundResults = [];

  Stopwatch _stopwatch = Stopwatch();
  Map<String, dynamic>? _trainingRecord;

  // 动画
  late AnimationController _pulseAnimController;
  late Animation<double> _pulseAnimation;
  int? _activeAnimalIndex;
  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnimation;

  // 从8个动物中随机选出当前轮使用的动物（至少seqLength个）
  List<int> _currentAnimalPool = [];

  @override
  void initState() {
    super.initState();
    _seqLength = _seqLengths[widget.level] ?? 3;
    _totalRounds = _roundCounts[widget.level] ?? 5;
    _currentRound = 0;

    _pulseAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeOut),
    );

    _resultAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  void _generateSequence() {
    final rng = Random();
    // 随机选取 seqLength + 2 个动物作为候选池
    final pool = List.generate(_animals.length, (i) => i)..shuffle();
    _currentAnimalPool = pool.take(min(_seqLength + 2, _animals.length)).toList();

    _currentSequence = [];
    for (int i = 0; i < _seqLength; i++) {
      _currentSequence.add(_currentAnimalPool[rng.nextInt(_currentAnimalPool.length)]);
    }
  }

  Future<void> _startGame() async {
    final provider = context.read<TrainingProvider>();
    final record = await provider.startTraining(3, widget.level, 300);

    setState(() {
      _trainingRecord = record;
      _currentRound = 0;
      _correctRounds = 0;
      _totalScore = 0;
      _roundResults = [];
      _stopwatch.reset();
      _stopwatch.start();
    });

    _nextRound();
  }

  void _nextRound() {
    if (_currentRound >= _totalRounds) {
      _finishGame();
      return;
    }

    _generateSequence();
    _userSequence = [];
    _listenIndex = 0;
    _isListening = true;

    setState(() {
      _currentRound++;
      _phase = 'listen';
    });

    // 依次播放声音序列
    _playSequence();
  }

  void _playSequence() async {
    final audioService = AudioService.instance;

    for (int i = 0; i < _currentSequence.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;
      final animalIdx = _currentSequence[i];

      // 播放动物声音
      await audioService.playAnimalSound(animalIdx);

      if (!mounted) return;
      setState(() {
        _listenIndex = i;
        _activeAnimalIndex = animalIdx;
      });

      // 脉冲动画
      _pulseAnimController.forward(from: 0);

      // 根据动物声音持续时间等待
      final soundDuration = audioService.getAnimalSoundDuration(animalIdx);
      await Future.delayed(Duration(milliseconds: soundDuration));

      if (!mounted) return;
      setState(() {
        _activeAnimalIndex = null;
      });
    }

    // 播放完毕，进入回放阶段
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _phase = 'replay';
      _isListening = false;
    });
  }

  void _onAnimalPressed(int animalIndex) {
    if (_phase != 'replay') return;

    // 播放动物声音
    AudioService.instance.playAnimalSound(animalIndex);

    setState(() {
      _activeAnimalIndex = animalIndex;
      _userSequence.add(animalIndex);
    });

    _pulseAnimController.forward(from: 0);

    // 检查当前输入是否正确
    final currentInputIndex = _userSequence.length - 1;
    if (_userSequence[currentInputIndex] != _currentSequence[currentInputIndex]) {
      // 输入错误 - 锁定输入，防止延迟期间继续点击
      setState(() {
        _phase = 'submitting';
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _submitRoundResult();
      });
      return;
    }

    // 输入正确
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _activeAnimalIndex = null;
      });

      if (_userSequence.length == _currentSequence.length) {
        // 全部输入完毕
        _submitRoundResult();
      }
    });
  }

  void _submitRoundResult() {
    final isCorrect = _userSequence.length == _currentSequence.length &&
        List.generate(_userSequence.length, (i) => _userSequence[i] == _currentSequence[i]).every((x) => x);

    if (isCorrect) {
      _correctRounds++;
      _totalScore += 10 * _seqLength;
    }

    _roundResults.add({
      'round': _currentRound,
      'correct': isCorrect,
      'sequence': _currentSequence,
      'userAnswer': _userSequence,
    });

    setState(() {
      _activeAnimalIndex = null;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _nextRound();
    });
  }

  void _finishGame() {
    _stopwatch.stop();
    final actualDuration = (_stopwatch.elapsedMilliseconds / 1000).round();
    final accuracy = (_correctRounds / _totalRounds * 100).round();

    if (_trainingRecord != null) {
      context.read<TrainingProvider>().completeTraining(
        _trainingRecord!['recordId'],
        actualDuration,
        0,
        accuracy.toDouble(),
        _totalScore,
      );
      context.read<RewardProvider>().loadStarCount();
    }

    setState(() {
      _phase = 'result';
    });
    _resultAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text('声音序列', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: _phase == 'ready',
      ),
      body: _phase == 'ready'
          ? _buildReadyScreen()
          : _phase == 'result'
              ? _buildResultScreen()
              : _buildGameScreen(),
    );
  }

  /// ===== 准备界面 =====
  Widget _buildReadyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.headphones, size: 48, color: Color(0xFFFF6B6B)),
            ),
            const SizedBox(height: 24),
            const Text('声音序列', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('难度: ${_levelNames[widget.level]}', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎮 玩法说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRuleItem('1️⃣', '仔细听动物叫声的顺序'),
                  _buildRuleItem('2️⃣', '听完后按相同顺序点击动物'),
                  _buildRuleItem('3️⃣', '共 $_totalRounds 轮，答对越多越好'),
                  _buildRuleItem('🎯', '训练你的听觉记忆能力！'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: const Text('开始训练', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5))),
        ],
      ),
    );
  }

  /// ===== 游戏界面 =====
  Widget _buildGameScreen() {
    // 上一轮反馈
    String? lastFeedback;
    Color feedbackColor = Colors.transparent;
    if (_roundResults.isNotEmpty) {
      final last = _roundResults.last;
      if (last['round'] == _currentRound - 1) {
        lastFeedback = last['correct'] ? '✅ 上一轮正确！' : '❌ 上一轮错误';
        feedbackColor = last['correct'] ? const Color(0xFF4CAF50) : Colors.red;
      }
    }

    return Column(
      children: [
        // 状态栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('第 $_currentRound / $_totalRounds 轮', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFFF6B6B), size: 20),
                  const SizedBox(width: 4),
                  Text('正确 $_correctRounds', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (_currentRound - 1) / _totalRounds,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
          minHeight: 4,
        ),
        const Spacer(),

        // 反馈提示
        if (lastFeedback != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: feedbackColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(lastFeedback, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: feedbackColor)),
          ),
          const SizedBox(height: 16),
        ],

        // 阶段提示
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _phase == 'listen'
              ? Column(
                  children: [
                    const Text('👂 仔细听...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('正在播放第 ${_listenIndex + 1} / $_seqLength 个', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  ],
                )
              : Column(
                  children: [
                    const Text('🎵 按顺序点击动物', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('已选 ${_userSequence.length} / $_seqLength', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  ],
                ),
        ),
        const SizedBox(height: 24),

        // 动物按钮网格
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: _currentAnimalPool.map((idx) {
              final animal = _animals[idx];
              final isActive = _activeAnimalIndex == idx;
              final isUserInput = _userSequence.contains(idx);
              final isEnabled = _phase == 'replay';

              return GestureDetector(
                onTap: isEnabled ? () => _onAnimalPressed(idx) : null,
                child: AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Color(animal['color'])
                          : isUserInput
                              ? Color(animal['color']).withOpacity(0.2)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isUserInput
                          ? Border.all(color: Color(animal['color']), width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isActive
                              ? Color(animal['color']).withOpacity(0.4)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: isActive ? 16 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          animal['emoji'],
                          style: TextStyle(fontSize: _phase == 'listen' && isActive ? 40 : 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          animal['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Color(animal['color']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  /// ===== 结果界面 =====
  Widget _buildResultScreen() {
    final accuracy = (_correctRounds / _totalRounds * 100).round();
    final timeSeconds = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

    int starRating = 1;
    if (accuracy >= 80) {
      starRating = 3;
    } else if (accuracy >= 50) {
      starRating = 2;
    }
    final stars = '⭐' * starRating + '☆' * (3 - starRating);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text('训练完成', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ScaleTransition(
                scale: _resultScaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(stars, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 16),
                      const Text('🎉 听力训练完成！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildResultRow('⏱️ 总用时', '${timeSeconds}秒'),
                      _buildResultRow('📊 正确', '$_correctRounds / $_totalRounds 轮'),
                      _buildResultRow('🎯 正确率', '$accuracy%'),
                      _buildResultRow('🏆 得分', '$_totalScore 分'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          starRating == 3 ? '🌟 耳朵真灵！' : (starRating == 2 ? '👍 不错的听力！' : '💪 多加练习！'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFF6B6B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 每轮结果
              if (_roundResults.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📋 每轮结果', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._roundResults.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('第${r['round']}轮 ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            Text(r['correct'] ? '✅ 正确' : '❌ 错误',
                                style: TextStyle(fontSize: 13, color: r['correct'] ? const Color(0xFF4CAF50) : Colors.red)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          side: const BorderSide(color: Color(0xFFFF6B6B)),
                        ),
                        child: const Text('返回', style: TextStyle(fontSize: 16, color: Color(0xFFFF6B6B))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _resultAnimController.reset();
                          _startGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: const Text('再来一次', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
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

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
