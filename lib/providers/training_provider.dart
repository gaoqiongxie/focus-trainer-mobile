import 'package:flutter/material.dart';
import '../models/training_model.dart';
import '../utils/http_util.dart';

class TrainingProvider extends ChangeNotifier {
  List<TrainingConfigModel> _configs = [];
  List<TrainingRecordModel> _records = [];
  Map<String, dynamic>? _statistics;
  TrainingRecordModel? _currentTraining;
  bool _isLoading = false;

  List<TrainingConfigModel> get configs => _configs;
  List<TrainingRecordModel> get records => _records;
  Map<String, dynamic>? get statistics => _statistics;
  TrainingRecordModel? get currentTraining => _currentTraining;
  bool get isLoading => _isLoading;

  /// 获取训练配置列表
  Future<void> loadConfigs({int? trainingType}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await HttpUtil.get('/training/config', params: {
        if (trainingType != null) 'trainingType': trainingType,
      });

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _configs = list
            .map((e) => TrainingConfigModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // 静默处理
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 开始训练
  Future<TrainingRecordModel?> startTraining(int trainingType, int level, int duration) async {
    try {
      final response = await HttpUtil.post('/training/start', data: {
        'trainingType': trainingType,
        'level': level,
        'duration': duration,
      });

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'];
        if (data != null) {
          _currentTraining = TrainingRecordModel.fromJson(data as Map<String, dynamic>);
          notifyListeners();
          return _currentTraining;
        }
      }
    } catch (e) {
      // 静默处理
    }
    return null;
  }

  /// 完成训练
  Future<bool> completeTraining(int recordId, int actualDuration, int interruptCount, double accuracy, int score) async {
    try {
      final response = await HttpUtil.post('/training/complete', data: {
        'recordId': recordId,
        'actualDuration': actualDuration,
        'interruptCount': interruptCount,
        'accuracy': accuracy,
        'score': score,
      });

      if (response.statusCode == 200 && response.data['code'] == 200) {
        _currentTraining = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // 静默处理
    }
    return false;
  }

  /// 获取训练统计
  Future<void> loadStatistics(String period) async {
    try {
      final response = await HttpUtil.get('/training/statistics', params: {'period': period});

      if (response.statusCode == 200 && response.data['code'] == 200) {
        _statistics = response.data['data'] as Map<String, dynamic>?;
        notifyListeners();
      }
    } catch (e) {
      // 静默处理
    }
  }

  /// 获取训练记录
  Future<void> loadRecords({int? trainingType, int page = 1, int size = 20}) async {
    try {
      final response = await HttpUtil.get('/training/records', params: {
        if (trainingType != null) 'trainingType': trainingType,
        'page': page,
        'size': size,
      });

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _records = list
            .map((e) => TrainingRecordModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // 静默处理
    }
  }

  /// 中断训练
  Future<void> interruptTraining(int recordId) async {
    try {
      await HttpUtil.post('/training/interrupt', data: {
        'recordId': recordId,
      });
      _currentTraining = null;
      notifyListeners();
    } catch (e) {
      // 静默处理
    }
  }
}
