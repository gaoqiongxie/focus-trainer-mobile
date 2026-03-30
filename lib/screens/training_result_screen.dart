import 'dart:math';
import 'package:flutter/material.dart';

/// 统一训练结果页
/// 所有训练游戏共用，提供一致的结果展示体验
class TrainingResultScreen extends StatefulWidget {
  final String gameName;
  final Color themeColor;
  final int starRating; // 1-3
  final int score;
  final String duration; // 如 "12.3秒"
  final List<ResultItem> items;
  final String encouragement;
  final int earnedStars; // 本局获得的星星数
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const TrainingResultScreen({
    super.key,
    required this.gameName,
    required this.themeColor,
    required this.starRating,
    required this.score,
    required this.duration,
    required this.items,
    required this.encouragement,
    this.earnedStars = 0,
    this.onRetry,
    this.onBack,
  });

  @override
  State<TrainingResultScreen> createState() => _TrainingResultScreenState();
}

class _TrainingResultScreenState extends State<TrainingResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimController;
  late Animation<double> _mainScaleAnimation;
  late AnimationController _starAnimController;
  late Animation<double> _starBounceAnimation;
  late AnimationController _confettiController;
  List<_Particle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();

    // 主卡片弹入动画
    _mainAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _mainScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimController, curve: Curves.elasticOut),
    );

    // 星星弹跳动画
    _starAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _starBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starAnimController, curve: Curves.elasticOut),
    );

    // 彩纸动画
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _generateConfetti();

    // 启动动画序列
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _mainAnimController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _starAnimController.forward();
    });
    if (widget.starRating >= 2) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _confettiController.forward();
      });
    }
  }

  void _generateConfetti() {
    final rng = Random();
    _confettiParticles = List.generate(30, (i) {
      return _Particle(
        x: rng.nextDouble(),
        vx: (rng.nextDouble() - 0.5) * 0.003,
        vy: rng.nextDouble() * 0.002 + 0.001,
        size: rng.nextDouble() * 4 + 3,
        colorIndex: i % 5,
        rotation: rng.nextDouble() * 6.28,
        rotationSpeed: (rng.nextDouble() - 0.5) * 0.1,
      );
    });
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _starAnimController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.themeColor.withOpacity(0.05),
      appBar: AppBar(
        title: const Text('训练完成', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // 彩纸效果
          if (widget.starRating >= 2)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(
                    progress: _confettiController.value,
                    particles: _confettiParticles,
                    themeColor: widget.themeColor,
                  ),
                );
              },
            ),
          // 主内容
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildMainCard(),
                  const SizedBox(height: 24),
                  _buildStarReward(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 主成绩卡片
  Widget _buildMainCard() {
    return ScaleTransition(
      scale: _mainScaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // 游戏名称
            Text(
              widget.gameName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // 标题
            const Text(
              '🎉 挑战完成！',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 星级动画
            _buildStars(),
            const SizedBox(height: 24),

            // 分数大字展示
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${widget.score}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: widget.themeColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '总得分',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 详细数据行
            ...widget.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.label,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                      Text(item.value,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),

            // 鼓励语
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.encouragement,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.themeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 星星展示（逐个亮起）
  Widget _buildStars() {
    return ScaleTransition(
      scale: _starBounceAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isActive = index < widget.starRating;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isActive ? '⭐' : '☆',
                key: ValueKey('$index-active-$isActive'),
                style: TextStyle(
                  fontSize: isActive ? 40 : 32,
                  color: isActive ? null : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 星星奖励提示
  Widget _buildStarReward() {
    if (widget.earnedStars <= 0) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _starBounceAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              '+${widget.earnedStars} 星星已入账',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                side: BorderSide(color: widget.themeColor, width: 1.5),
              ),
              child: Text(
                '返回',
                style: TextStyle(fontSize: 16, color: widget.themeColor, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                elevation: 0,
              ),
              child: const Text('再来一次', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

/// 结果数据项
class ResultItem {
  final String label;
  final String value;

  const ResultItem({required this.label, required this.value});
}

/// 彩纸粒子
class _Particle {
  final double x;
  final double vx;
  final double vy;
  final double size;
  final int colorIndex;
  final double rotation;
  final double rotationSpeed;
  _Particle({
    required this.x,
    required this.vx,
    required this.vy,
    required this.size,
    required this.colorIndex,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// 彩纸绘制器
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Color themeColor;

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFFFF6B6B),
    Color(0xFF4CAF50),
    Color(0xFF42A5F5),
    Color(0xFFFF8C42),
  ];

  _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final t = progress;

      // 粒子从顶部中央向下散开
      final x = size.width * (0.5 + (p.x - 0.5) * t * 2 + sin(t * 3 + i) * 0.05);
      final y = size.height * t * 0.8 + p.vy * t * size.height * 10;
      final alpha = (1.0 - t * 0.6).clamp(0.0, 1.0);
      final color = (i == 0 ? themeColor : _colors[p.colorIndex]).withOpacity(alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t * 20);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        Paint()..color = color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
