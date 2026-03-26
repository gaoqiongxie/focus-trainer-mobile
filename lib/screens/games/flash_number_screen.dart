import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/reward_provider.dart';

/// 数字闪现训练
/// 快速显示数字/符号，训练瞬间记忆和视觉捕捉能力
/// 难度: 初级(3位数,2秒) / 中级(4位数,1.5秒) / 高级(5位数,1秒)
class FlashNumberScreen extends StatefulWidget {
  final int level; // 1=初级, 2=中级, 3=高级

  const FlashNumberScreen({
    super.key,
    required this.level,
  });

  @override
  State<FlashNumberScreen> createState() => _FlashNumberScreenState();
}

class _FlashNumberScreenState extends State<FlashNumberScreen
    with TickerProviderStateMixin {
  // 游戏阶段: ready -> memorize -> input -> result
  String _phase = 'ready'; // ready / memorize / input / result

  // 难度配置
  static const Map<int, int> _digitCounts = {1: 3, 2: 4, 3: 5};
  static const Map<int, int> _displayMs = {1: 2000, 2: 1500, 3: 1000};
  static const Map<int, int> _roundCounts = {1: 5, 2: 7, 3: 10};
  static const Map<int, String> _levelNames = {1: '初级 3位数', 2: '中级 4位数', 3: '高级 5位数'};

  late int _digitCount;
  late int _displayMs;
  late int _totalRounds;
  late int _currentRound;
  late String _currentNumber;
  late List<String> _userInput;
  String _inputText = '';
  int _correctCount = 0;
  int _totalScore = 0;
  List<Map<String, dynamic>> _roundResults = [];

  // 计时
  Stopwatch _totalStopwatch = Stopwatch();

  // 后端训练记录
  Map<String, dynamic>? _trainingRecord;

  // 动画
  late AnimationController _flashAnimController;
  late Animation<double> _flashScaleAnimation;
  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnimation;

  @override
  void initState() {
    super.initState();
    _digitCount = _digitCounts[widget.level] ?? 3;
    _displayMs = _displayMs[widget.level] ?? 2000;
    _totalRounds = _roundCounts[widget.level] ?? 5;
    _currentRound = 0;

    _flashAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashScaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _flashAnimController, curve: Curves.elasticOut),
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
    _flashAnimController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  String _generateNumber() {
    final rng = Random();
    String num = '';
    // 确保首位不是0
    num += (rng.nextInt(9) + 1).toString();
    for (int i = 1; i < _digitCount; i++) {
      num += rng.nextInt(10).toString();
    }
    return num;
  }

  Future<void> _startGame() async {
    final provider = context.read<TrainingProvider>();
    final record = await provider.startTraining(2, widget.level + 10, 300);

    setState(() {
      _trainingRecord = record;
      _currentRound = 0;
      _correctCount = 0;
      _totalScore = 0;
      _roundResults = [];
      _totalStopwatch.reset();
      _totalStopwatch.start();
    });

    _nextRound();
  }

  void _nextRound() {
    if (_currentRound >= _totalRounds) {
      _finishGame();
      return;
    }

    setState(() {
      _currentRound++;
      _currentNumber = _generateNumber();
      _userInput = [];
      _inputText = '';
      _phase = 'memorize';
    });

    _flashAnimController.forward(from: 0);

    // 闪现指定时间后切换到输入阶段
    Timer(Duration(milliseconds: _displayMs), () {
      if (!mounted) return;
      setState(() {
        _phase = 'input';
      });
    });
  }

  void _onNumberPressed(String digit) {
    if (_phase != 'input') return;
    if (_userInput.length >= _digitCount) return;

    setState(() {
      _userInput.add(digit);
      _inputText = _userInput.join();
    });

    // 输入完所有位数后自动提交
    if (_userInput.length == _digitCount) {
      _submitAnswer();
    }
  }

  void _onDelete() {
    if (_userInput.isEmpty) return;
    setState(() {
      _userInput.removeLast();
      _inputText = _userInput.join();
    });
  }

  void _submitAnswer() {
    final userAnswer = _userInput.join();
    final isCorrect = userAnswer == _currentNumber;
    final roundScore = isCorrect ? 10 : 0;

    setState(() {
      if (isCorrect) {
        _correctCount++;
        _totalScore += roundScore;
      }
      _roundResults.add({
        'round': _currentRound,
        'number': _currentNumber,
        'answer': userAnswer,
        'correct': isCorrect,
      });
    });

    // 延迟展示结果后进入下一轮
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _nextRound();
    });
  }

  void _finishGame() {
    _totalStopwatch.stop();
    final totalMs = _totalStopwatch.elapsedMilliseconds;
    final actualDuration = (totalMs / 1000).round();
    final accuracy = (_correctCount / _totalRounds * 100).round();

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
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('数字闪现', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF8C42),
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
                color: const Color(0xFFFF8C42).withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.flash_on, size: 48, color: Color(0xFFFF8C42)),
            ),
            const SizedBox(height: 24),
            const Text('数字闪现', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
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
                  _buildRuleItem('1️⃣', '屏幕快速闪现一串数字'),
                  _buildRuleItem('2️⃣', '记住数字后在键盘上输入'),
                  _buildRuleItem('3️⃣', '共 $_totalRounds 轮，答对越多越好'),
                  _buildRuleItem('🎯', '闪现时间仅 ${_displayMs ~/ 1000} 秒，集中注意力！'),
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
                  backgroundColor: const Color(0xFFFF8C42),
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
    return Column(
      children: [
        // 状态栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('第 $_currentRound / $_totalRounds 轮', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFFF8C42), size: 20),
                  const SizedBox(width: 4),
                  Text('正确 $_correctCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: _currentRound / _totalRounds,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
          minHeight: 4,
        ),
        const Spacer(),
        // 核心区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _phase == 'memorize' ? _buildMemorizePhase() : _buildInputPhase(),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildMemorizePhase() {
    // 当前轮次正确/错误反馈
    String? lastFeedback;
    Color feedbackColor = Colors.transparent;
    if (_roundResults.isNotEmpty) {
      final last = _roundResults.last;
      if (last['round'] == _currentRound - 1) {
        lastFeedback = last['correct'] ? '✅ 正确！' : '❌ 是 ${last['number']}';
        feedbackColor = last['correct'] ? const Color(0xFF50C878) : Colors.red;
      }
    }

    return Column(
      children: [
        if (lastFeedback != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: feedbackColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(lastFeedback, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: feedbackColor)),
          ),
          const SizedBox(height: 24),
        ],
        const Text('👀 记住这个数字！', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        // 数字闪现区域
        ScaleTransition(
          scale: _flashScaleAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C42),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C42).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              _currentNumber,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 16,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputPhase() {
    // 显示上一轮的结果反馈
    String? lastFeedback;
    Color feedbackColor = Colors.transparent;
    if (_roundResults.isNotEmpty) {
      final last = _roundResults.last;
      if (last['round'] == _currentRound - 1) {
        lastFeedback = last['correct'] ? '✅ 上轮正确！' : '❌ 上轮是 ${last['number']}';
        feedbackColor = last['correct'] ? const Color(0xFF50C878) : Colors.red;
      }
    }

    return Column(
      children: [
        if (lastFeedback != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: feedbackColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(lastFeedback, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: feedbackColor)),
          ),
          const SizedBox(height: 16),
        ],
        const Text('✏️ 输入你记住的数字', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        // 输入显示区域
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Text(
            _inputText.isEmpty ? '?' : _inputText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _inputText.isEmpty ? Colors.grey.shade300 : const Color(0xFF333333),
              letterSpacing: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_userInput.length} / $_digitCount',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
        const Spacer(),
        // 数字键盘
        _buildKeypad(),
      ],
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 0; col < 3; col++) _buildKeyButton(row, col),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(int row, int col) {
    String label;
    VoidCallback? onPressed;

    if (row < 3) {
      final num = row * 3 + col + 1;
      label = '$num';
      onPressed = () => _onNumberPressed('$num');
    } else if (col == 0) {
      label = '';
      onPressed = null;
    } else if (col == 1) {
      label = '0';
      onPressed = () => _onNumberPressed('0');
    } else {
      label = '⌫';
      onPressed = _onDelete;
    }

    if (label.isEmpty) {
      return const SizedBox(width: 72, height: 56);
    }

    return SizedBox(
      width: 72,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: label == '⌫' ? Colors.red.shade50 : const Color(0xFFF0F4FF),
          foregroundColor: label == '⌫' ? Colors.red : const Color(0xFF333333),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label, style: TextStyle(fontSize: label == '⌫' ? 22 : 24, fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// ===== 结果界面 =====
  Widget _buildResultScreen() {
    final accuracy = (_correctCount / _totalRounds * 100).round();
    final timeSeconds = (_totalStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

    int starRating = 1;
    if (accuracy >= 90) {
      starRating = 3;
    } else if (accuracy >= 60) {
      starRating = 2;
    }
    final stars = '⭐' * starRating + '☆' * (3 - starRating);

    return SingleChildScrollView(
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
                  const Text('🎉 训练完成！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildResultRow('⏱️ 总用时', '${timeSeconds}秒'),
                  _buildResultRow('📊 正确', '$_correctCount / $_totalRounds 轮'),
                  _buildResultRow('🎯 正确率', '$accuracy%'),
                  _buildResultRow('🏆 得分', '$_totalScore 分'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      starRating == 3 ? '🌟 记忆力超群！' : (starRating == 2 ? '👍 表现不错！' : '💪 多练习会更好！'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFF8C42)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 每轮详情
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
                  const Text('📋 每轮详情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._roundResults.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text('第${r['round']}轮 ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        Text(r['correct'] ? '✅ ' : '❌ ',
                            style: TextStyle(fontSize: 13, color: r['correct'] ? const Color(0xFF50C878) : Colors.red)),
                        Expanded(
                          child: Text(
                            r['correct']
                                ? '${r['number']}'
                                : '正确: ${r['number']} 你的: ${r['answer']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: r['correct'] ? Colors.black87 : Colors.red,
                              decoration: r['correct'] ? null : TextDecoration.lineThrough,
                              decorationColor: Colors.grey,
                            ),
                          ),
                        ),
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
                      side: const BorderSide(color: Color(0xFFFF8C42)),
                    ),
                    child: const Text('返回', style: TextStyle(fontSize: 16, color: Color(0xFFFF8C42))),
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
                      backgroundColor: const Color(0xFFFF8C42),
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
