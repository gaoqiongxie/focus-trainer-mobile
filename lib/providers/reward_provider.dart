import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../utils/http_util.dart';

class RewardProvider extends ChangeNotifier {
  int _starCount = 0;
  List<BadgeModel> _badges = [];
  int _currentStreak = 0;
  int _maxStreak = 0;
  String? _errorMessage;

  int get starCount => _starCount;
  List<BadgeModel> get badges => _badges;
  int get currentStreak => _currentStreak;
  int get maxStreak => _maxStreak;
  String? get errorMessage => _errorMessage;

  /// 已解锁徽章数量
  int get earnedCount => _badges.where((b) => b.earned).length;

  /// 加载星星数量
  Future<void> loadStarCount() async {
    try {
      final response = await HttpUtil.get('/reward/stars');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _starCount = (response.data['data'] as num?)?.toInt() ?? 0;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '加载星星数量失败';
      debugPrint('[RewardProvider] loadStarCount error: $e');
    }
  }

  /// 加载徽章列表
  Future<void> loadBadges() async {
    try {
      final response = await HttpUtil.get('/reward/badges');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _badges = list
            .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '加载徽章列表失败';
      debugPrint('[RewardProvider] loadBadges error: $e');
    }
  }

  /// 加载连续打卡
  Future<void> loadStreak() async {
    try {
      final response = await HttpUtil.get('/reward/streak');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        _currentStreak = data?['currentStreak'] as int? ?? 0;
        _maxStreak = data?['maxStreak'] as int? ?? 0;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '加载连续打卡失败';
      debugPrint('[RewardProvider] loadStreak error: $e');
    }
  }
}
