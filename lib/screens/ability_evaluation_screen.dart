import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/charts_flutter.dart' as charts;
import '../providers/evaluation_provider.dart';
import '../models/ability_model.dart';
import '../models/daily_task_model.dart';
import 'games/schulte_grid_screen.dart';
import 'games/flash_number_screen.dart';
import 'games/card_match_screen.dart';
import 'games/sound_sequence_screen.dart';
import 'training_screen.dart';

class AbilityEvaluationScreen extends StatefulWidget {
  const AbilityEvaluationScreen({super.key});

  @override
  State<AbilityEvaluationScreen> createState() => _AbilityEvaluationScreenState();
}

class _AbilityEvaluationScreenState extends State<AbilityEvaluationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvaluationProvider>().loadGuide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('能力评估'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: Consumer<EvaluationProvider>(
        builder: (context, eval, _) {
          if (eval.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 能力等级卡片
                _buildLevelCard(eval),
                const SizedBox(height: 16),

                // 雷达图
                if (eval.ability != null) ...[
                  _buildRadarChart(eval.ability!),
                  const SizedBox(height: 16),
                ],

                // 推荐训练
                _buildRecommendations(eval),
                const SizedBox(height: 16),

                // 评估历史
                if (eval.history.isNotEmpty) _buildHistory(eval),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelCard(EvaluationProvider eval) {
    final ability = eval.ability;
    final level = ability?.abilityLevel ?? '?';
    final levelDesc = ability?.levelDescription ?? '等待评估';
    final totalScore = ability?.totalScore ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(ability?.levelColorValue ?? 0xFF9E9E9E),
            Color(ability?.levelColorValue ?? 0xFF9E9E9E).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '能力等级',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Text(
                level,
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(levelDesc, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('综合 $totalScore 分', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (eval.needsEvaluation)
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await eval.generateEvaluation();
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('能力评估已生成！'), backgroundColor: Colors.green),
                  );
                }
              },
              icon: const Icon(Icons.psychology),
              label: const Text('开始评估'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(ability?.levelColorValue ?? 0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            )
          else if (ability != null)
            Text(
              '评估日期: ${ability.evaluateDate} · 基于近30天训练数据',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(AbilityModel ability) {
    final series = [
      charts.Series<double, String>(
        id: '能力雷达',
        domainFn: (_, i) => AbilityModel.dimensions[i],
        measureFn: (score, _) => score,
        data: ability.scores,
        colorFn: (_, __) => charts.MaterialPalette.purple.shadeDefault,
        fillColorFn: (_, __) => charts.MaterialPalette.purple.shadeDefault.withOpacity(0.3),
      ),
    ];

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('能力雷达图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
              Expanded(
                child: charts.RadarChart(
                  series,
                  animate: true,
                  defaultRenderer: charts.RadarRendererDefaultIdentity<String>(
                    labelAccessorFn: (val, i) => '${AbilityModel.dimensions[i]}\n${val.toInt()}',
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(EvaluationProvider eval) {
    final recs = eval.recommendations;
    if (recs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('个性化推荐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...recs.map((rec) => _buildRecommendationCard(rec)),
      ],
    );
  }

  Widget _buildRecommendationCard(AbilityRecommendation rec) {
    final isWeak = rec.score < 60;
    final color = isWeak ? Colors.red.shade50 : Colors.orange.shade50;
    final borderColor = isWeak ? Colors.red.shade200 : Colors.orange.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _dimColor(rec.dimension).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_dimEmoji(rec.dimension), style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(rec.dimension, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _scoreColor(rec.score).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${rec.score.toInt()}分',
                        style: TextStyle(fontSize: 11, color: _scoreColor(rec.score), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(rec.reason, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('推荐: ${rec.trainingName}', style: const TextStyle(fontSize: 12, color: Color(0xFF6C63FF))),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _startTraining(rec.trainingType),
            icon: const Icon(Icons.play_circle_filled, color: Color(0xFF6C63FF), size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(EvaluationProvider eval) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('历史评估', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...eval.history.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Color(a.levelColorValue).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(a.abilityLevel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(a.levelColorValue))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.evaluateDate, style: const TextStyle(fontSize: 13)),
                    Text('综合 ${a.totalScore.toStringAsFixed(1)} 分', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _startTraining(int trainingType) {
    Navigator.of(context).pop(); // 返回上一页
    // 通过 bottom nav 或直接 push 到对应游戏
    Widget screen;
    switch (trainingType) {
      case 1:
        screen = TrainingScreen(trainingType: 1, level: 1, duration: 300);
        break;
      case 2:
        screen = const SchulteGridScreen(level: 1);
        break;
      case 3:
        screen = const SoundSequenceScreen(level: 1);
        break;
      case 4:
        screen = const CardMatchScreen(level: 1);
        break;
      case 21:
        screen = const FlashNumberScreen(level: 1);
        break;
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  String _dimEmoji(String dim) {
    switch (dim) {
      case '专注时长': return '⏱';
      case '视觉注意力': return '👁';
      case '听觉注意力': return '👂';
      case '工作记忆': return '🧠';
      case '抑制控制': return '🎯';
      default: return '⭐';
    }
  }

  Color _dimColor(String dim) {
    switch (dim) {
      case '专注时长': return Colors.blue;
      case '视觉注意力': return Colors.green;
      case '听觉注意力': return Colors.orange;
      case '工作记忆': return Colors.purple;
      case '抑制控制': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _scoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
