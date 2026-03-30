import 'package:flutter/material.dart';
import '../models/daily_task_model.dart';
import '../utils/http_util.dart';

class DailyTaskProvider extends ChangeNotifier {
  List<DailyTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DailyTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 完成数量
  int get completedCount => _tasks.where((t) => t.completed).length;

  /// 是否全部完成
  bool get allCompleted => _tasks.isNotEmpty && _tasks.every((t) => t.completed);

  /// 从后端获取今日任务列表
  Future<void> loadDailyTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await HttpUtil.get('/training/daily-tasks');

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _tasks = list
            .map((e) => DailyTaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = response.data['message'] ?? '加载任务失败';
      }
    } catch (e) {
      _errorMessage = '网络错误，请重试';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 标记任务完成（本地更新，实际完成由训练结果触发）
  void markTaskCompleted(int taskId) {
    final index = _tasks.indexWhere((t) => t.taskId == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(completed: true);
      notifyListeners();
    }
  }

  /// 检查某个 trainingType+level 对应的任务是否存在并标记完成
  void checkAndMarkCompleted(int trainingType, int level) {
    bool updated = false;
    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (!task.completed && task.trainingType == trainingType && task.level == level) {
        _tasks[i] = task.copyWith(completed: true);
        updated = true;
      }
    }
    if (updated) notifyListeners();
  }
}
