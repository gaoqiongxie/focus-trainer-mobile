import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/reward_provider.dart';
import '../providers/training_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<RewardProvider>().loadStarCount(),
      context.read<RewardProvider>().loadBadges(),
      context.read<RewardProvider>().loadStreak(),
      context.read<TrainingProvider>().loadStatistics('week'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), elevation: 0),
      body: Consumer3<UserProvider, RewardProvider, TrainingProvider>(
        builder: (context, user, reward, training, _) => ListView(
          children: [
            // 用户信息卡片
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90D9), Color(0xFF6C63FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.child_care, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userInfo?['nickname'] ?? '小朋友',
                          style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '第${user.userInfo?['grade'] ?? 1}年级 · ${user.userInfo?['age'] ?? 7}岁',
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 统计卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard('⭐', '${reward.starCount}', '总星星', Colors.amber),
                  const SizedBox(width: 12),
                  _buildStatCard('🔥', '${reward.currentStreak}', '连续天数', Colors.red),
                  const SizedBox(width: 12),
                  _buildStatCard('🏆', '${reward.maxStreak}', '最高记录', Colors.purple),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 本周训练统计
            _buildSection('📊 本周训练', [
              _buildInfoRow('训练次数', '${training.statistics?['totalCount'] ?? 0} 次'),
              _buildInfoRow('完成次数', '${training.statistics?['completedCount'] ?? 0} 次'),
              _buildInfoRow('完成率', '${training.statistics?['completionRate'] ?? 0}%'),
              _buildInfoRow('总训练时长', '${((training.statistics?['totalDuration'] ?? 0) ~/ 60)} 分钟'),
              _buildInfoRow('获得星星', '${training.statistics?['totalStars'] ?? 0}'),
            ]),

            const SizedBox(height: 16),

            // 徽章墙
            _buildSection('🏅 徽章墙', [
              ...reward.badges.map((badge) => _buildBadgeItem(badge)),
            ]),

            const SizedBox(height: 32),

            // 登出按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await user.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('退出登录', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> badge) {
    final earned = badge['earned'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: earned ? Colors.amber.withOpacity(0.2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              earned ? Icons.emoji_events : Icons.lock_outline,
              color: earned ? Colors.amber : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            badge['name'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: earned ? Colors.black87 : Colors.grey,
            ),
          ),
          const Spacer(),
          if (earned)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
