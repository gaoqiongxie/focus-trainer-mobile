import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 训练锁定设置 Provider
/// 管理训练防中断功能
class TrainingLockProvider extends ChangeNotifier {
  static const String _lockEnabledKey = 'training_lock_enabled';
  static const String _lockDurationKey = 'training_lock_duration';
  
  bool _lockEnabled = false;
  int _lockDuration = 30; // 默认锁定30分钟
  bool _isLoading = false;

  bool get lockEnabled => _lockEnabled;
  int get lockDuration => _lockDuration;
  bool get isLoading => _isLoading;

  /// 初始化，加载保存的设置
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _lockEnabled = prefs.getBool(_lockEnabledKey) ?? false;
      _lockDuration = prefs.getInt(_lockDurationKey) ?? 30;
    } catch (_) {
      // 使用默认值
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 开启/关闭训练锁定
  Future<void> setLockEnabled(bool enabled) async {
    _lockEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockEnabledKey, enabled);
    } catch (_) {
      // 保存失败，回滚状态
      _lockEnabled = !enabled;
      notifyListeners();
    }
  }

  /// 设置锁定时长
  Future<void> setLockDuration(int minutes) async {
    _lockDuration = minutes;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lockDurationKey, minutes);
    } catch (_) {
      // 保存失败
    }
  }

  /// 获取锁定时长的文字描述
  String get lockDurationText {
    if (_lockDuration < 60) {
      return '$_lockDuration 分钟';
    } else {
      final hours = _lockDuration ~/ 60;
      final mins = _lockDuration % 60;
      if (mins == 0) {
        return '$hours 小时';
      }
      return '$hours 小时 $mins 分钟';
    }
  }
}
