import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/reward_provider.dart';

/// 卡片配对记忆游戏
/// 翻转卡片找到配对，训练工作记忆
/// 难度: 初级(4x3=6对) / 中级(4x4=8对) / 高级(5x4=10对)
class CardMatchScreen extends StatefulWidget {
  final int level; // 1=初级, 2=中级, 3=高级

  const CardMatchScreen({
    super.key,
    required this.level,
  });

  @override
  State<CardMatchScreen> createState() => _CardMatchScreenState();
}

class _CardMatchItem {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  _CardMatchItem({required this.id, required this.emoji, this.isFlipped = false, this.isMatched = false});
}

class _CardMatchScreenState extends State<CardMatchScreen> with TickerProviderStateMixin {
  // 难度配置
  static const Map<int, int> _pairCounts = {1: 6, 2: 8, 3: 10};
  static const Map<int, String> _levelNames = {1: '初级 6对', 2: '中级 8对', 3: '高级 10对'};

  // 可用的emoji集
  static const List<String> _emojiPool = [
    '🐶', '🐱', '🐰', '🦊', '🐼', '🐨', '🦁', '🐯', '🐸', '🐵',
    '🍎', '🍊', '🍋', '🍇', '🍓', '🍑', '🥝', '🍌', '🍉', '🥭',
    '⭐', '🌙', '☀️', '🌈', '❤️', '💎', '🎈', '🎀', '🎨', '🎵',
  ];

  // 游戏状态
  bool _isReady = true;
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _isChecking = false;

  List<_CardMatchItem> _cards = [];
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;

  int _moves = 0;
  int _matchedPairs = 0;
  int _totalPairs = 6;

  Stopwatch _stopwatch = Stopwatch();
  Timer? _displayTimer;
  String _elapsedTime = '00:00';

  Map<String, dynamic>? _trainingRecord;

  // 动画控制器
  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnimation;
  Map<int, AnimationController> _flipControllers = {};

  @override
  void initState() {
    super.initState();
    _totalPairs = _pairCounts[widget.level] ?? 6;

    _resultAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.elasticOut),
    );
  }

  void _initCards() {
    _totalPairs = _pairCounts[widget.level] ?? 6;
    final emojis = List<String>.from(_emojiPool)..shuffle();
    final selectedEmojis = emojis.take(_totalPairs).toList();

    final cardList = <_CardMatchItem>[];
    for (int i = 0; i < selectedEmojis.length; i++) {
      cardList.add(_CardMatchItem(id: i * 2, emoji: selectedEmojis[i]));
      cardList.add(_CardMatchItem(id: i * 2 + 1, emoji: selectedEmojis[i]));
    }
    cardList.shuffle();

    _cards = cardList;
    _firstFlippedIndex = null;
    _secondFlippedIndex = null;
    _moves = 0;
    _matchedPairs = 0;
    _isChecking = false;

    // 初始化翻转动画控制器
    _flipControllers.clear();
    for (int i = 0; i < _cards.length; i++) {
      _flipControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _resultAnimController.dispose();
    for (var c in _flipControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startGame() async {
    final provider = context.read<TrainingProvider>();
    final record = await provider.startTraining(4, widget.level, 300);

    _initCards();

    setState(() {
      _isReady = false;
      _isPlaying = true;
      _trainingRecord = record;
    });

    _stopwatch.reset();
    _stopwatch.start();

    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final s = _stopwatch.elapsedSeconds;
      setState(() {
        _elapsedTime = '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  void _onCardTapped(int index) {
    if (!_isPlaying || _isChecking) return;

    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;

    // 翻转动画
    _flipControllers[index]?.forward();

    setState(() {
      card.isFlipped = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else if (_secondFlippedIndex == null && index != _firstFlippedIndex) {
      _secondFlippedIndex = index;
      _moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    _isChecking = true;
    final first = _cards[_firstFlippedIndex!];
    final second = _cards[_secondFlippedIndex!];

    if (first.emoji == second.emoji) {
      // 配对成功
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          first.isMatched = true;
          second.isMatched = true;
          _matchedPairs++;
          _isChecking = false;
        });

        _firstFlippedIndex = null;
        _secondFlippedIndex = null;

        if (_matchedPairs == _totalPairs) {
          _completeGame();
        }
      });
    } else {
      // 配对失败 - 翻回去
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;

        _flipControllers[_firstFlippedIndex]?.reverse();
        _flipControllers[_secondFlippedIndex]?.reverse();

        setState(() {
          first.isFlipped = false;
          second.isFlipped = false;
          _isChecking = false;
        });

        _firstFlippedIndex = null;
        _secondFlippedIndex = null;
      });
    }
  }

  void _completeGame() {
    _stopwatch.stop();
    _displayTimer?.cancel();

    final totalMs = _stopwatch.elapsedMilliseconds;
    final actualDuration = (totalMs / 1000).round();
    final perfectMoves = _totalPairs; // 最少步数 = 配对数
    final accuracy = max(0, (100 - ((_moves - perfectMoves) / _totalPairs * 100)).round()).clamp(0, 100);
    final score = (accuracy * 10).round();

    if (_trainingRecord != null) {
      context.read<TrainingProvider>().completeTraining(
        _trainingRecord!['recordId'],
        actualDuration,
        0,
        accuracy.toDouble(),
        score,
      );
      context.read<RewardProvider>().loadStarCount();
    }

    setState(() {
      _isPlaying = false;
      _isCompleted = true;
    });
    _resultAnimController.forward();
  }

  int get _gridColumns {
    final totalCards = _totalPairs * 2;
    if (totalCards <= 12) return 4; // 4x3
    if (totalCards <= 16) return 4; // 4x4
    return 5; // 5x4
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
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('卡片配对', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFB347),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.style, size: 48, color: Color(0xFFFFB347)),
              ),
              const SizedBox(height: 24),
              const Text('卡片配对', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
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
                    _buildRuleItem('1️⃣', '翻开两张卡片，找出图案相同的配对'),
                    _buildRuleItem('2️⃣', '配对成功的卡片保持翻开'),
                    _buildRuleItem('3️⃣', '用最少步数找出所有配对'),
                    _buildRuleItem('🎯', '挑战你的记忆极限！'),
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
                    backgroundColor: const Color(0xFFFFB347),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: const Text('开始游戏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          Text(emoji),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5))),
        ],
      ),
    );
  }

  /// ===== 游戏界面 =====
  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('卡片配对', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFB347),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _stopwatch.stop();
              _displayTimer?.cancel();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_elapsedTime, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                    Text('用时', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                Column(
                  children: [
                    Text('$_matchedPairs / $_totalPairs', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('配对', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_moves 步', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFB347))),
                    Text('翻牌', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _matchedPairs / _totalPairs,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB347)),
            minHeight: 4,
          ),
          const Spacer(),
          // 卡片网格
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AspectRatio(
              aspectRatio: _gridColumns <= 4 ? 0.85 : 0.9,
              child: _buildCardGrid(),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCardGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        final controller = _flipControllers[index];

        if (controller == null) return const SizedBox();

        return GestureDetector(
          onTap: () => _onCardTapped(index),
          child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: card.isMatched
                      ? const Color(0xFFFFB347).withOpacity(0.15)
                      : Colors.white,
                  border: card.isMatched
                      ? Border.all(color: const Color(0xFFFFB347), width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(card.isFlipped || card.isMatched ? 0.05 : 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: (card.isFlipped || card.isMatched)
                        ? Text(
                            card.emoji,
                            key: ValueKey('${card.id}-front'),
                            style: TextStyle(
                              fontSize: _gridColumns <= 4 ? 36 : 28,
                            ),
                          )
                        : Icon(
                            Icons.help_outline,
                            key: ValueKey('${card.id}-back'),
                            size: 32,
                            color: const Color(0xFFFFB347),
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
    final timeSeconds = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
    final perfectMoves = _totalPairs;
    final accuracy = max(0, (100 - ((_moves - perfectMoves) / _totalPairs * 100)).round()).clamp(0, 100);
    final score = (accuracy * 10).round();

    int starRating = 1;
    if (_moves <= perfectMoves + 2) {
      starRating = 3;
    } else if (_moves <= perfectMoves * 1.5) {
      starRating = 2;
    }
    final stars = '⭐' * starRating + '☆' * (3 - starRating);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('游戏完成', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFB347),
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
                      const Text('🎉 全部配对成功！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildResultRow('⏱️ 用时', '${timeSeconds}秒'),
                      _buildResultRow('🔄 翻牌', '$_moves 步'),
                      _buildResultRow('✅ 配对', '$_matchedPairs / $_totalPairs 对'),
                      _buildResultRow('🎯 效率', '$accuracy%'),
                      _buildResultRow('🏆 得分', '$score 分'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB347).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          starRating == 3 ? '🌟 记忆大师！' : (starRating == 2 ? '👍 不错哦！' : '💪 继续加油！'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFFB347)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          side: const BorderSide(color: Color(0xFFFFB347)),
                        ),
                        child: const Text('返回', style: TextStyle(fontSize: 16, color: Color(0xFFFFB347))),
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
                          backgroundColor: const Color(0xFFFFB347),
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
