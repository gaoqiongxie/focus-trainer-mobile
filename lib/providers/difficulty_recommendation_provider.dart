import 'package:flutter/material.dart';
import '../utils/http_util.dart';

/// 难度推荐数据模型
class DifficultyRecommendation {
  final int trainingType;
  final String trainingName;
  final int recommendedLevel;
  final int? recommendedDuration;
  final String reason; // 推荐理由
  final int confidence; // 置信度 0-100
  final List<dynamic>? weakPoints; // 薄弱项
  final String? improvementTip; // 提升建议

  const DifficultyRecommendation({
    required this.trainingType,
    required this.trainingName,
    required this.recommendedLevel,
    this.recommendedDuration,
    required this.reason,
    this.confidence = 70,
    this.weakPoints,
    this.improvementTip,
  });

  factory DifficultyRecommendation.fromJson(Map<String, dynamic> json) {
    return DifficultyRecommendation(
      trainingType: json['trainingType'] as int? ?? 0,
      trainingName: json['trainingName'] as String? ?? '',
      recommendedLevel: json['recommendedLevel'] as int? ?? 1,
      recommendedDuration: json['recommendedDuration'] as int?,
      reason: json['reason'] as String? ?? '基于您的训练表现推荐',
      confidence: json['confidence'] as int? ?? 70,
      weakPoints: json['weakPoints'] as List<dynamic>?,
      improvementTip: json['improvementTip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trainingType': trainingType,
      'trainingName': trainingName,
      'recommendedLevel': recommendedLevel,
      if (recommendedDuration != null) 'recommendedDuration': recommendedDuration,
      'reason': reason,
      'confidence': confidence,
      if (weakPoints != null) 'weakPoints': weakPoints,
      if (improvementTip != null) 'improvementTip': improvementTip,
    };
  }

  /// 获取难度等级文字描述
  String get levelDescription {
    switch (recommendedLevel) {
      case 1:
        return '初级';
      case 2:
        return '中级';
      case 3:
        return '高级';
      default:
        return '初级';
    }
  }

  /// 获取置信度颜色
  Color get confidenceColor {
    if (confidence >= 80) return const Color(0xFF4CAF50);
    if (confidence >= 60) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }
}

/// 难度推荐 Provider
class DifficultyRecommendationProvider extends ChangeNotifier {
  List<DifficultyRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DifficultyRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取推荐难度列表
  Future<void> loadRecommendations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await HttpUtil.get('/training/recommend');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _recommendations = list
            .map((e) => DifficultyRecommendation.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = response.data['message'] ?? '获取推荐失败';
      }
    } catch (e) {
      _errorMessage = '网络错误，请重试';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 获取单个训练类型的推荐
  DifficultyRecommendation? getRecommendation(int trainingType) {
    try {
      return _recommendations.firstWhere((r) => r.trainingType == trainingType);
    } catch (_) {
      return null;
    }
  }

  /// 获取薄弱项推荐
  List<String> getWeakPointsRecommendation() {
    final List<String> tips = [];
    for (final r in _recommendations) {
      if (r.weakPoints != null) {
        tips.addAll(r.weakPoints!.map((e) => e.toString()));
      }
    }
    return tips;
  }
}
