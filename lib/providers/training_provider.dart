import 'package:flutter/material.dart';
import '../utils/http_util.dart';

class TrainingProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _configs = [];
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _currentTraining;
  bool _isLoading = false;

  List<Map<String, dynamic>> get configs => _configs;
  List<Map<String, dynamic>> get records => _records;
  Map<String, dynamic>? get statistics => _statistics;
  Map<String, dynamic>? get currentTraining => _currentTraining;
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
        _configs = List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      // 静默处理
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// 开始训练
  Future<Map<String, dynamic>?> startTraining(int trainingType, int level, int duration) async {
    try {
      final response = await HttpUtil.post('/training/start', data: {
        'trainingType': trainingType,
        'level': level,
        'duration': duration,
      });
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _currentTraining = response.data['data'];
        notifyListeners();
        return _currentTraining;
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
        _statistics = response.data['data'];
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
        _records = List<Map<String, dynamic>>.from(response.data['data']);
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
