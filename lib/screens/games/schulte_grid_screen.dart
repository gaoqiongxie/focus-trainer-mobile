import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/reward_provider.dart';

/// 舒尔特方格训练
/// 经典注意力训练：在方格中按数字顺序依次点击
/// 难度: 3x3(9格) / 4x4(16格) / 5x5(25格)
class SchulteGridScreen extends StatefulWidget {
  final int level; // 1=3x3, 2=4x4, 3=5x5

  const SchulteGridScreen({
    super.key,
    required this.level,
  });

  @override
  State<SchulteGridScreen> createState() => _SchulteGridScreenState();
}

class _SchulteGridScreenState extends State<SchulteGridScreen
    with TickerProviderStateMixin {
  // 游戏状态
  bool _isReady = true;
  bool _isPlaying = false;
  bool _isCompleted = false;
  int _nextNumber = 1;
  int _gridSize = 3;
  late List<int> _numbers;
  List<int> _tappedNumbers = [];
  Stopwatch _stopwatch = Stopwatch();
  Timer? _displayTimer;
  String _elapsedTime = '00:00.0';

  // 错误反馈
  int _errorCount = 0;
  int _correctCount = 0;

  // 动画
  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnimation;
  String? _lastTappedFeedback; // 'correct' / 'wrong'
  int? _lastTappedIndex;

  // 后端训练记录
  Map<String, dynamic>? _trainingRecord;

  // 配置映射
  static const Map<int, int> _levelToSize = {1: 3, 2: 4, 3: 5};
  static const Map<int, String> _levelNames = {1: '初级 3×3', 2: '中级 4×4', 3: '高级 5×5'};

  @override
  void initState() {
    super.initState();
    _gridSize = _levelToSize[widget.level] ?? 3;
    _initGrid();

    _resultAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.elasticOut),
    );
  }

  void _initGrid() {
    final total = _gridSize * _gridSize;
    _numbers = List.generate(total, (i) => i + 1);
    // Fisher-Yates 洗牌
    final rng = Random();
    for (int i = _numbers.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = _numbers[i];
      _numbers[i] = _numbers[j];
      _numbers[j] = temp;
    }
    _tappedNumbers = [];
    _nextNumber = 1;
    _errorCount = 0;
    _correctCount = 0;
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _resultAnimController.dispose();
    super.dispose();
  }

  void _startGame() async {
    // 调用后端开始训练
    final provider = context.read<TrainingProvider>();
    final record = await provider.startTraining(2, widget.level, 300);

    setState(() {
      _isReady = false;
      _isPlaying = true;
      _trainingRecord = record;
    });

    _stopwatch.reset();
    _stopwatch.start();

    _displayTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      final ms = _stopwatch.elapsedMilliseconds;
      final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
      final seconds = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
      final tenths = ((ms % 1000) ~/ 100).toString();
      setState(() {
        _elapsedTime = '$minutes:$seconds.$tenths';
      });
    });
  }

  void _onCellTapped(int index) {
    if (!_isPlaying) return;

    final tappedNumber = _numbers[index];

    if (tappedNumber == _nextNumber) {
      // 正确
      setState(() {
        _tappedNumbers.add(tappedNumber);
        _correctCount++;
        _lastTappedIndex = index;
        _lastTappedFeedback = 'correct';
      });

      if (_nextNumber == _gridSize * _gridSize) {
        // 全部完成
        _completeGame();
      } else {
        _nextNumber++;
      }

      // 300ms后清除反馈高亮
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _lastTappedIndex = null;
            _lastTappedFeedback = null;
          });
        }
      });
    } else {
      // 错误 - 闪烁反馈
      setState(() {
        _errorCount++;
        _lastTappedIndex = index;
        _lastTappedFeedback = 'wrong';
      });

      // 震动反馈（如果支持）
      // HapticFeedback.heavyImpact();

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _lastTappedIndex = null;
            _lastTappedFeedback = null;
          });
        }
      });
    }
  }

  void _completeGame() {
    _stopwatch.stop();
    _displayTimer?.cancel();

    final totalMs = _stopwatch.elapsedMilliseconds;
    final total = _gridSize * _gridSize;
    final accuracy = (_correctCount / total * 100).round();
    final score = (total * 10 * accuracy / 100).round();
    final actualDuration = (totalMs / 1000).round();

    // 计算星级评价
    int starRating = 1;
    // 参考时间标准（秒）：3x3<15s, 4x4<40s, 5x5<75s
    final standardTimes = {3: 15, 4: 40, 5: 75};
    final timeSeconds = totalMs / 1000;
    final standard = standardTimes[_gridSize] ?? 60;
    if (timeSeconds < standard * 0.7 && _errorCount == 0) {
      starRating = 3;
    } else if (timeSeconds < standard && _errorCount <= 2) {
      starRating = 2;
    }

    // 上报训练结果给后端
    if (_trainingRecord != null) {
      context.read<TrainingProvider>().completeTraining(
        _trainingRecord!['recordId'],
        actualDuration,
        0, // 中断次数为0
        accuracy.toDouble(),
        score,
      );
      context.read<RewardProvider>().loadStarCount();
    }

    setState(() {
      _isPlaying = false;
      _isCompleted = true;
    });
    if (mounted) {
      _resultAnimController.forward();
    }
  }

  void _restartGame() {
    _resultAnimController.reset();
    _initGrid();
    _elapsedTime = '00:00.0';
    setState(() {
      _isCompleted = false;
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return _buildResultScreen();
    if (_isPlaying) return _buildGameScreen();
    return _buildReadyScreen();
  }

  /// ===== 准备界面 =====
  Widget _buildReadyScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('舒尔特方格', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF50C878),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF50C878).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.grid_on, size: 48, color: Color(0xFF50C878)),
              ),
              const SizedBox(height: 24),
              const Text(
                '舒尔特方格',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '难度: ${_levelNames[widget.level] ?? ""}',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              // 玩法说明
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎮 玩法说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildRuleItem('1️⃣', '按 1→2→3... 的顺序依次点击数字'),
                    _buildRuleItem('2️⃣', '点错会记录错误次数，但不扣分'),
                    _buildRuleItem('3️⃣', '用时越短、错误越少，评价越高'),
                    _buildRuleItem('🎯', '目标: 全部正确点击，追求最快速度'),
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
                    backgroundColor: const Color(0xFF50C878),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: const Text('开始挑战', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5))),
        ],
      ),
    );
  }

  /// ===== 游戏界面 =====
  Widget _buildGameScreen() {
    final total = _gridSize * _gridSize;

    return WillPopScope(
      onWillPop: () async {
        // 关闭时中断训练记录
        _stopwatch.stop();
        _displayTimer?.cancel();
        if (_trainingRecord != null) {
          context.read<TrainingProvider>().interruptTraining(
            _trainingRecord!['recordId'],
          );
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        appBar: AppBar(
          title: const Text('舒尔特方格', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF50C878),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _stopwatch.stop();
                _displayTimer?.cancel();
                if (_trainingRecord != null) {
                  context.read<TrainingProvider>().interruptTraining(
                    _trainingRecord!['recordId'],
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      body: Column(
        children: [
          // 状态栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _elapsedTime,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text('用时', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '第 $_nextNumber / $total 个',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text('进度', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _errorCount == 0 ? '✅ 完美' : '❌ $_errorCount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _errorCount == 0 ? const Color(0xFF50C878) : Colors.red,
                      ),
                    ),
                    Text('错误', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          // 进度条
          LinearProgressIndicator(
            value: _correctCount / total,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF50C878)),
            minHeight: 4,
          ),
          const SizedBox(height: 16),
          // 提示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '👆 请找到并点击数字 $_nextNumber',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          // 方格区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AspectRatio(
              aspectRatio: 1,
              child: _buildGrid(),
            ),
          ),
          const Spacer(),
        ],
      ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridSize,
        crossAxisSpacing: _gridSize <= 3 ? 10 : 6,
        mainAxisSpacing: _gridSize <= 3 ? 10 : 6,
      ),
      itemCount: _gridSize * _gridSize,
      itemBuilder: (context, index) {
        final number = _numbers[index];
        final isTapped = _tappedNumbers.contains(number);
        final isCurrentTarget = number == _nextNumber && !isTapped;
        final isTappedNow = index == _lastTappedIndex;
        final feedback = _lastTappedFeedback;

        Color bgColor = Colors.white;
        Color textColor = const Color(0xFF333333);
        double scale = 1.0;

        if (isTapped) {
          bgColor = const Color(0xFF50C878);
          textColor = Colors.white;
        }

        if (isTappedNow && feedback == 'correct') {
          bgColor = const Color(0xFF50C878);
          textColor = Colors.white;
          scale = 0.9;
        } else if (isTappedNow && feedback == 'wrong') {
          bgColor = Colors.red.shade100;
          textColor = Colors.red;
          scale = 1.05;
        }

        final fontSize = _gridSize <= 3 ? 28.0 : (_gridSize <= 4 ? 22.0 : 18.0);

        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          child: GestureDetector(
            onTap: () => _onCellTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(_gridSize <= 3 ? 16 : 10),
                border: isCurrentTarget
                    ? Border.all(color: const Color(0xFF50C878), width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isTapped ? 0.0 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                child: Text(
                  isTapped ? '✓' : '$number',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ===== 结果界面 =====
  Widget _buildResultScreen() {
    final totalMs = _stopwatch.elapsedMilliseconds;
    final timeSeconds = (totalMs / 1000).toStringAsFixed(1);
    final total = _gridSize * _gridSize;
    final accuracy = _correctCount == total ? 100 : ((_correctCount / total * 100).round());
    final score = (total * 10 * accuracy / 100).round();

    // 星级
    int starRating = 1;
    final standardTimes = {3: 15, 4: 40, 5: 75};
    final ts = totalMs / 1000;
    final std = standardTimes[_gridSize] ?? 60;
    if (ts < std * 0.7 && _errorCount == 0) {
      starRating = 3;
    } else if (ts < std && _errorCount <= 2) {
      starRating = 2;
    }

    final stars = '⭐' * starRating + '☆' * (3 - starRating);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('训练完成', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF50C878),
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
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 星级
                      Text(stars, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 16),
                      const Text(
                        '🎉 挑战完成！',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      // 成绩卡片
                      _buildResultRow('⏱️ 用时', '${timeSeconds}秒'),
                      _buildResultRow('✅ 正确', '$_correctCount / $total'),
                      _buildResultRow('❌ 错误', '$_errorCount 次'),
                      _buildResultRow('🎯 正确率', '$accuracy%'),
                      _buildResultRow('🏆 得分', '$score 分'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF50C878).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          starRating == 3 ? '🌟 太厉害了！' : (starRating == 2 ? '👍 很棒！继续加油！' : '💪 再接再厉！'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF50C878),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          side: const BorderSide(color: Color(0xFF50C878)),
                        ),
                        child: const Text('返回', style: TextStyle(fontSize: 16, color: Color(0xFF50C878))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF50C878),
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
