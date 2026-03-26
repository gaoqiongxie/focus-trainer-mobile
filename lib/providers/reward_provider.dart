import 'package:flutter/material.dart';
import '../utils/http_util.dart';

class RewardProvider extends ChangeNotifier {
  int _starCount = 0;
  List<Map<String, dynamic>> _badges = [];
  int _currentStreak = 0;
  int _maxStreak = 0;

  int get starCount => _starCount;
  List<Map<String, dynamic>> get badges => _badges;
  int get currentStreak => _currentStreak;
  int get maxStreak => _maxStreak;

  /// 加载星星数量
  Future<void> loadStarCount() async {
    try {
      final response = await HttpUtil.get('/reward/stars');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _starCount = response.data['data'];
        notifyListeners();
      }
    } catch (e) {}
  }

  /// 加载徽章列表
  Future<void> loadBadges() async {
    try {
      final response = await HttpUtil.get('/reward/badges');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _badges = List<Map<String, dynamic>>.from(response.data['data']);
        notifyListeners();
      }
    } catch (e) {}
  }

  /// 加载连续打卡
  Future<void> loadStreak() async {
    try {
      final response = await HttpUtil.get('/reward/streak');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'];
        _currentStreak = data['currentStreak'] ?? 0;
        _maxStreak = data['maxStreak'] ?? 0;
        notifyListeners();
      }
    } catch (e) {}
  }
}
