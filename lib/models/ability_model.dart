/// 能力评估数据模型
class AbilityModel {
  final int abilityId;
  final int userId;
  final double attentionDuration; // 专注时长
  final double visualAttention;    // 视觉注意力
  final double auditoryAttention;  // 听觉注意力
  final double workingMemory;       // 工作记忆
  final double inhibitoryControl;   // 抑制控制
  final double totalScore;         // 综合得分
  final String abilityLevel;        // A/B/C/D/E
  final String evaluateDate;

  const AbilityModel({
    required this.abilityId,
    required this.userId,
    required this.attentionDuration,
    required this.visualAttention,
    required this.auditoryAttention,
    required this.workingMemory,
    required this.inhibitoryControl,
    required this.totalScore,
    required this.abilityLevel,
    required this.evaluateDate,
  });

  factory AbilityModel.fromJson(Map<String, dynamic> json) {
    return AbilityModel(
      abilityId: json['abilityId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      attentionDuration: (json['attentionDuration'] ?? 0).toDouble(),
      visualAttention: (json['visualAttention'] ?? 0).toDouble(),
      auditoryAttention: (json['auditoryAttention'] ?? 0).toDouble(),
      workingMemory: (json['workingMemory'] ?? 0).toDouble(),
      inhibitoryControl: (json['inhibitoryControl'] ?? 0).toDouble(),
      totalScore: (json['totalScore'] ?? 0).toDouble(),
      abilityLevel: json['abilityLevel'] as String? ?? 'E',
      evaluateDate: json['evaluateDate'] as String? ?? '',
    );
  }

  /// 维度标签
  static const List<String> dimensions = [
    '专注时长',
    '视觉注意力',
    '听觉注意力',
    '工作记忆',
    '抑制控制',
  ];

  /// 获取各维度分数列表
  List<double> get scores => [
        attentionDuration,
        visualAttention,
        auditoryAttention,
        workingMemory,
        inhibitoryControl,
      ];

  /// 等级描述
  String get levelDescription {
    switch (abilityLevel) {
      case 'A':
        return '优秀';
      case 'B':
        return '良好';
      case 'C':
        return '中等';
      case 'D':
        return '待提升';
      default:
        return '加油';
    }
  }

  /// 等级颜色
  int get levelColorValue {
    switch (abilityLevel) {
      case 'A':
        return 0xFF4CAF50; // 绿
      case 'B':
        return 0xFF8BC34A; // 浅绿
      case 'C':
        return 0xFFFF9800; // 橙
      case 'D':
        return 0xFFFF5722; // 红橙
      default:
        return 0xFF9E9E9E; // 灰
    }
  }
}

/// 能力引导推荐
class AbilityRecommendation {
  final String dimension;
  final double score;
  final int trainingType;
  final String trainingName;
  final String reason;
  final int priority;

  const AbilityRecommendation({
    required this.dimension,
    required this.score,
    required this.trainingType,
    required this.trainingName,
    required this.reason,
    required this.priority,
  });

  factory AbilityRecommendation.fromJson(Map<String, dynamic> json) {
    return AbilityRecommendation(
      dimension: json['dimension'] as String? ?? '',
      score: (json['score'] ?? 0).toDouble(),
      trainingType: json['trainingType'] as int? ?? 1,
      trainingName: json['trainingName'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      priority: json['priority'] as int? ?? 99,
    );
  }
}
