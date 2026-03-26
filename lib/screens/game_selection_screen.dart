import 'package:flutter/material.dart';
import 'games/schulte_grid_screen.dart';
import 'games/flash_number_screen.dart';
import 'games/card_match_screen.dart';
import 'games/sound_sequence_screen.dart';
import 'training_screen.dart';

/// 游戏选择页面
/// 从训练模块进入后，选择具体游戏和难度
class GameSelectionScreen extends StatelessWidget {
  final List<String> games;
  final String title;

  const GameSelectionScreen({
    super.key,
    required this.games,
    required this.title,
  });

  // 游戏信息配置
  static const Map<String, Map<String, dynamic>> _gameInfo = {
    'schulte': {
      'name': '舒尔特方格',
      'emoji': '🎯',
      'desc': '按数字顺序依次点击方格',
      'color': Color(0xFF50C878),
      'levels': [
        {'name': '初级 3×3', 'level': 1, 'desc': '9个数字，入门挑战'},
        {'name': '中级 4×4', 'level': 2, 'desc': '16个数字，进阶训练'},
        {'name': '高级 5×5', 'level': 3, 'desc': '25个数字，极限挑战'},
      ],
    },
    'flash': {
      'name': '数字闪现',
      'emoji': '⚡',
      'desc': '快速记住闪现的数字',
      'color': Color(0xFFFF8C42),
      'levels': [
        {'name': '初级 3位数', 'level': 1, 'desc': '2秒闪现，5轮'},
        {'name': '中级 4位数', 'level': 2, 'desc': '1.5秒闪现，7轮'},
        {'name': '高级 5位数', 'level': 3, 'desc': '1秒闪现，10轮'},
      ],
    },
    'match': {
      'name': '卡片配对',
      'emoji': '🃏',
      'desc': '翻转卡片找到配对',
      'color': Color(0xFFFFB347),
      'levels': [
        {'name': '初级 6对', 'level': 1, 'desc': '12张卡片，简单模式'},
        {'name': '中级 8对', 'level': 2, 'desc': '16张卡片，标准模式'},
        {'name': '高级 10对', 'level': 3, 'desc': '20张卡片，困难模式'},
      ],
    },
    'sound': {
      'name': '声音序列',
      'emoji': '🎵',
      'desc': '记住声音播放顺序',
      'color': Color(0xFFFF6B6B),
      'levels': [
        {'name': '初级 3音序', 'level': 1, 'desc': '3个声音，5轮'},
        {'name': '中级 5音序', 'level': 2, 'desc': '5个声音，5轮'},
        {'name': '高级 7音序', 'level': 3, 'desc': '7个声音，5轮'},
      ],
    },
    'focus': {
      'name': '专注计时',
      'emoji': '⏱️',
      'desc': '保持专注，完成倒计时',
      'color': Color(0xFF4A90D9),
      'levels': [
        {'name': '5分钟', 'level': 1, 'duration': 300, 'desc': '适合初学者'},
        {'name': '10分钟', 'level': 2, 'duration': 600, 'desc': '进阶训练'},
        {'name': '15分钟', 'level': 3, 'duration': 900, 'desc': '挑战模式'},
      ],
    },
  };

  void _navigateToGame(BuildContext context, String gameType, Map<String, dynamic> levelInfo) {
    switch (gameType) {
      case 'schulte':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SchulteGridScreen(level: levelInfo['level'] as int),
        ));
        break;
      case 'flash':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FlashNumberScreen(level: levelInfo['level'] as int),
        ));
        break;
      case 'match':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CardMatchScreen(level: levelInfo['level'] as int),
        ));
        break;
      case 'sound':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SoundSequenceScreen(level: levelInfo['level'] as int),
        ));
        break;
      case 'focus':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TrainingScreen(
            trainingType: 1,
            level: levelInfo['level'] as int,
            duration: levelInfo['duration'] as int,
          ),
        ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: games.map((gameType) {
          final info = _gameInfo[gameType];
          if (info == null) return const SizedBox.shrink();

          return _buildGameSection(context, gameType, info);
        }).toList(),
      ),
    );
  }

  Widget _buildGameSection(BuildContext context, String gameType, Map<String, dynamic> info) {
    final levels = info['levels'] as List<Map<String, dynamic>>;
    final color = info['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // 游戏标题
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(info['emoji'], style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(info['desc'], style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 难度选择
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: levels.map((level) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => _navigateToGame(context, gameType, level),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // 难度等级标识
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${level['level']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(level['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                Text(level['desc'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Icon(Icons.play_circle_outline, color: color, size: 28),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
