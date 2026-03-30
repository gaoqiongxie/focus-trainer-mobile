import 'dart:convert';

class TrainingConfigModel {
  final int configId;
  final int trainingType;
  final String? trainingName;
  final int level;
  final int? duration;
  final String? configJson;
  final String? iconUrl;
  final String? description;
  final int isActive;

  const TrainingConfigModel({
    required this.configId,
    required this.trainingType,
    this.trainingName,
    required this.level,
    this.duration,
    this.configJson,
    this.iconUrl,
    this.description,
    this.isActive = 1,
  });

  factory TrainingConfigModel.fromJson(Map<String, dynamic> json) {
    return TrainingConfigModel(
      configId: json['configId'] as int? ?? 0,
      trainingType: json['trainingType'] as int? ?? 0,
      trainingName: json['trainingName'] as String?,
      level: json['level'] as int? ?? 1,
      duration: json['duration'] as int?,
      configJson: json['configJson'] as String?,
      iconUrl: json['iconUrl'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'configId': configId,
      'trainingType': trainingType,
      if (trainingName != null) 'trainingName': trainingName,
      'level': level,
      if (duration != null) 'duration': duration,
      if (configJson != null) 'configJson': configJson,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }

  /// 解析 configJson 字段为 Map
  Map<String, dynamic> getConfig() {
    if (configJson == null || configJson!.isEmpty) return {};
    try {
      return jsonDecode(configJson!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

class TrainingRecordModel {
  final int recordId;
  final int userId;
  final int trainingType;
  final int level;
  final int duration;
  final int actualDuration;
  final int status; // 0=进行中 1=完成 2=中断
  final int interruptCount;
  final double? accuracy;
  final int score;
  final int starReward;
  final String? startTime;
  final String? endTime;

  const TrainingRecordModel({
    required this.recordId,
    required this.userId,
    required this.trainingType,
    required this.level,
    required this.duration,
    this.actualDuration = 0,
    this.status = 0,
    this.interruptCount = 0,
    this.accuracy,
    this.score = 0,
    this.starReward = 0,
    this.startTime,
    this.endTime,
  });

  factory TrainingRecordModel.fromJson(Map<String, dynamic> json) {
    return TrainingRecordModel(
      recordId: json['recordId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      trainingType: json['trainingType'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      duration: json['duration'] as int? ?? 0,
      actualDuration: json['actualDuration'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      interruptCount: json['interruptCount'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      score: json['score'] as int? ?? 0,
      starReward: json['starReward'] as int? ?? 0,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'userId': userId,
      'trainingType': trainingType,
      'level': level,
      'duration': duration,
      'actualDuration': actualDuration,
      'status': status,
      'interruptCount': interruptCount,
      if (accuracy != null) 'accuracy': accuracy,
      'score': score,
      'starReward': starReward,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
    };
  }

  bool get isCompleted => status == 1;
  bool get isInterrupted => status == 2;
  bool get isInProgress => status == 0;
}
