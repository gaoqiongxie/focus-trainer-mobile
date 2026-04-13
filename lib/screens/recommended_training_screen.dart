import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/difficulty_recommendation_provider.dart';
import '../config/app_config.dart';
import 'games/schulte_grid_screen.dart';
import 'games/flash_number_screen.dart';
import 'games/card_match_screen.dart';
import 'games/sound_sequence_screen.dart';
import 'training_screen.dart';

/// 推荐训练页面
/// 展示个性化推荐难度和推荐理由
class RecommendedTrainingScreen extends StatefulWidget {
  const RecommendedTrainingScreen({super.key});

  @override
  State<RecommendedTrainingScreen> createState() => _RecommendedTrainingScreenState();
}

class _RecommendedTrainingScreenState extends State<RecommendedTrainingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DifficultyRecommendationProvider>().loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('推荐训练', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DifficultyRecommendationProvider>().loadRecommendations();
            },
          ),
        ],
      ),
      body: Consumer<DifficultyRecommendationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadRecommendations(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.recommendations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('暂无推荐', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '完成更多训练后获得个性化推荐',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadRecommendations(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 头部说明
                _buildHeader(),
                const SizedBox(height: 20),

                // 推荐卡片列表
                ...provider.recommendations.map((rec) => _buildRecommendationCard(rec)),
                const SizedBox(height: 20),

                // 薄弱项提升建议
                if (provider.getWeakPointsRecommendation().isNotEmpty) ...[
                  _buildWeakPointsSection(provider.getWeakPointsRecommendation()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// 头部说明区域
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF4A90D9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                '智能推荐',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '基于您最近的训练表现，为您推荐最适合的难度和训练内容。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 推荐卡片
  Widget _buildRecommendationCard(DifficultyRecommendation rec) {
    final color = AppConfig.trainingColors[rec.trainingType] ?? AppConfig.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // 卡片头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTrainingIcon(rec.trainingType),
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.trainingName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTag('难度 ${rec.levelDescription}', color),
                          const SizedBox(width: 8),
                          _buildConfidenceTag(rec.confidence),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 推荐理由
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFFFB347)),
                    const SizedBox(width: 8),
                    const Text(
                      '推荐理由',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rec.reason,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                ),
                if (rec.improvementTip != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB347).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates, size: 18, color: Color(0xFFFFB347)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.improvementTip!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFFE67E00)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 开始训练按钮
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startTraining(rec),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  '开始 ${rec.levelDescription} 训练',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 薄弱项提升建议区域
  Widget _buildWeakPointsSection(List<String> weakPoints) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber, color: Color(0xFFFF6B6B), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                '需要加强的能力',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...weakPoints.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right, color: Color(0xFFFF6B6B), size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildConfidenceTag(int confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            '置信度 $confidence%',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  IconData _getTrainingIcon(int type) {
    switch (type) {
      case 1: return Icons.timer;
      case 2: return Icons.visibility;
      case 3: return Icons.headphones;
      case 4: return Icons.memory;
      case 21: return Icons.flash_on;
      default: return Icons.star;
    }
  }

  void _startTraining(DifficultyRecommendation rec) {
    final level = rec.recommendedLevel;
    final duration = rec.recommendedDuration;

    switch (rec.trainingType) {
      case 2: // 舒尔特方格
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SchulteGridScreen(level: level),
        ));
        break;
      case 21: // 数字闪现
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FlashNumberScreen(level: level),
        ));
        break;
      case 4: // 卡片配对
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CardMatchScreen(level: level),
        ));
        break;
      case 3: // 声音序列
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SoundSequenceScreen(level: level),
        ));
        break;
      case 1: // 专注时长
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TrainingScreen(
            trainingType: 1,
            level: level,
            duration: duration ?? (level == 1 ? 300 : (level == 2 ? 600 : 900)),
          ),
        ));
        break;
      default:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TrainingScreen(trainingType: rec.trainingType, level: level, duration: 300),
        ));
    }
  }
}
