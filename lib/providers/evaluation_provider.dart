import 'package:flutter/material.dart';
import '../models/ability_model.dart';
import '../utils/http_util.dart';

/// 能力评估 Provider
class EvaluationProvider extends ChangeNotifier {
  AbilityModel? _ability;
  List<AbilityModel> _history = [];
  List<AbilityRecommendation> _recommendations = [];
  bool _isLoading = false;
  bool _needsEvaluation = true;
  String? _errorMessage;

  AbilityModel? get ability => _ability;
  List<AbilityModel> get history => _history;
  List<AbilityRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  bool get needsEvaluation => _needsEvaluation;
  String? get errorMessage => _errorMessage;

  /// 加载能力引导数据（推荐+评估）
  Future<void> loadGuide() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await HttpUtil.get('/evaluation/guide');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        _needsEvaluation = data['needsEvaluation'] as bool? ?? true;
        if (data['ability'] != null && (data['ability'] as Map).isNotEmpty) {
          _ability = AbilityModel.fromJson(data['ability'] as Map<String, dynamic>);
        }
        final recList = data['recommendations'] as List<dynamic>? ?? [];
        _recommendations = recList
            .map((e) => AbilityRecommendation.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = '加载能力报告失败';
      }
    } catch (e) {
      _errorMessage = '网络错误';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 获取评估历史
  Future<void> loadHistory() async {
    try {
      final response = await HttpUtil.get('/evaluation/history', params: {'limit': 10});
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _history = list
            .map((e) => AbilityModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载评估历史失败: $e');
    }
  }

  /// 触发评估生成（基于历史训练数据计算）
  Future<bool> generateEvaluation() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await HttpUtil.post('/evaluation/submit');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _ability = AbilityModel.fromJson(response.data['data'] as Map<String, dynamic>);
        _needsEvaluation = false;
        await loadGuide(); // 重新加载推荐
        return true;
      }
    } catch (e) {
      debugPrint('生成评估失败: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
