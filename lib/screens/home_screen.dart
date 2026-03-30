import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/training_provider.dart';
import '../providers/reward_provider.dart';
import '../providers/daily_task_provider.dart';
import '../models/daily_task_model.dart';
import 'training_screen.dart';
import 'profile_screen.dart';
import 'game_selection_screen.dart';
import 'games/schulte_grid_screen.dart';
import 'games/flash_number_screen.dart';
import 'games/card_match_screen.dart';
import 'games/sound_sequence_screen.dart';
import 'parent/parent_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<RewardProvider>().loadStarCount(),
      context.read<RewardProvider>().loadStreak(),
      context.read<TrainingProvider>().loadStatistics('week'),
      context.read<DailyTaskProvider>().loadDailyTasks(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('专注力训练', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A90D9), Color(0xFF6C63FF)],
                  ),
                ),
                child: SafeArea(
                  child: Consumer3<UserProvider, RewardProvider, TrainingProvider>(
                    builder: (context, user, reward, training, _) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white24,
                                child: const Icon(Icons.child_care, size: 28, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '你好，${user.userInfo?.nickname ?? '小朋友'}',
                                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('⭐', '${reward.starCount}', '星星'),
                              _buildStatItem('🔥', '${reward.currentStreak}', '连续天数'),
                              _buildStatItem('📊', '${training.statistics?['completedCount'] ?? 0}', '本周完成'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: _buildQuickActions()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildDailyTasks()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        body: _buildTrainingGrid(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('快速开始', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickCard('🎯', '舒尔特\n方格', 'schulte'),
                const SizedBox(width: 12),
                _buildQuickCard('⚡', '数字\n闪现', 'flash'),
                const SizedBox(width: 12),
                _buildQuickCard('🃏', '卡片\n配对', 'match'),
                const SizedBox(width: 12),
                _buildQuickCard('🎵', '声音\n序列', 'sound'),
                const SizedBox(width: 12),
                _buildQuickCard('⏱️', '专注\n计时', 'focus'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard(String emoji, String label, String gameType) {
    return InkWell(
      onTap: () => _navigateToGame(gameType, 1),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  /// 今日任务区块
  Widget _buildDailyTasks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<DailyTaskProvider>(
        builder: (context, dailyTask, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('今日任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (!dailyTask.isLoading && dailyTask.tasks.isNotEmpty)
                    Text(
                      '${dailyTask.completedCount}/${dailyTask.tasks.length} 完成',
                      style: TextStyle(
                        fontSize: 13,
                        color: dailyTask.allCompleted ? Colors.green : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (dailyTask.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ))
              else if (dailyTask.tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: Text(
                    dailyTask.errorMessage ?? '暂无今日任务',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              else
                Column(
                  children: dailyTask.tasks
                      .map((task) => _buildDailyTaskCard(task))
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDailyTaskCard(DailyTaskModel task) {
    final gameType = _trainingTypeToGameType(task.trainingType);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: task.completed ? null : () => _navigateToGame(gameType, task.level),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: task.completed ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: task.completed ? Colors.green.shade200 : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: task.completed
                ? null
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              // 完成/未完成图标
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: task.completed ? Colors.green : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  task.completed ? Icons.check : _trainingTypeToIcon(task.trainingType),
                  color: task.completed ? Colors.white : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // 标题和描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: task.completed ? Colors.grey.shade500 : Colors.black87,
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // 星星奖励
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 2),
                      Text(
                        '+${task.starReward}',
                        style: TextStyle(
                          fontSize: 13,
                          color: task.completed ? Colors.grey : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (!task.completed)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// trainingType 转 gameType 字符串
  String _trainingTypeToGameType(int trainingType) {
    switch (trainingType) {
      case 1:
        return 'focus';
      case 2:
        return 'schulte';
      case 3:
        return 'sound';
      case 4:
        return 'match';
      case 21:
        return 'flash';
      case 41:
        return 'match';
      default:
        return 'focus';
    }
  }

  /// trainingType 转图标
  IconData _trainingTypeToIcon(int trainingType) {
    switch (trainingType) {
      case 1:
        return Icons.timer;
      case 2:
        return Icons.visibility;
      case 3:
        return Icons.headphones;
      case 4:
      case 41:
        return Icons.memory;
      case 21:
        return Icons.flash_on;
      default:
        return Icons.star;
    }
  }

  Widget _buildTrainingGrid() {
    final modules = [
      {
        'type': 'visual',
        'name': '视觉追踪',
        'icon': Icons.visibility,
        'color': const Color(0xFF50C878),
        'desc': '舒尔特方格 · 数字闪现',
        'games': ['schulte', 'flash'],
      },
      {
        'type': 'auditory',
        'name': '听觉专注',
        'icon': Icons.headphones,
        'color': const Color(0xFFFF6B6B),
        'desc': '声音序列记忆',
        'games': ['sound'],
      },
      {
        'type': 'memory',
        'name': '记忆训练',
        'icon': Icons.memory,
        'color': const Color(0xFFFFB347),
        'desc': '卡片配对 · 翻牌记忆',
        'games': ['match'],
      },
      {
        'type': 'focus',
        'name': '专注时长',
        'icon': Icons.timer,
        'color': const Color(0xFF4A90D9),
        'desc': '计时专注 · 持续训练',
        'games': ['focus'],
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildTrainingCard(module);
      },
    );
  }

  Widget _buildTrainingCard(Map<String, dynamic> module) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _navigateToGameSelection(module['games'], module['name']),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [module['color'], (module['color'] as Color).withOpacity(0.7)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(module['icon'], size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(module['name'], style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(module['desc'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGame(String gameType, int level) {
    switch (gameType) {
      case 'schulte':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SchulteGridScreen(level: level)));
        break;
      case 'flash':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => FlashNumberScreen(level: level)));
        break;
      case 'match':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CardMatchScreen(level: level)));
        break;
      case 'sound':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SoundSequenceScreen(level: level)));
        break;
      case 'focus':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TrainingScreen(trainingType: 1, level: level, duration: level == 1 ? 300 : (level == 2 ? 600 : 900)),
        ));
        break;
    }
  }

  void _navigateToGameSelection(List<dynamic> games, String title) {
    if (games.length == 1) {
      _navigateToGame(games.first, 1);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameSelectionScreen(
          games: games.cast<String>(),
          title: title,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: const Color(0xFF4A90D9),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '报告'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
      ],
      onTap: (index) {
        if (index == 1) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentReportScreen()));
        } else if (index == 2) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }
      },
    );
  }
}
