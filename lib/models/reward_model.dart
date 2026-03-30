class RewardRecordModel {
  final int rewardId;
  final int userId;
  final int rewardType;
  final int? rewardValue;
  final String? rewardName;
  final int? sourceType;
  final int? sourceId;
  final String? createTime;

  const RewardRecordModel({
    required this.rewardId,
    required this.userId,
    required this.rewardType,
    this.rewardValue,
    this.rewardName,
    this.sourceType,
    this.sourceId,
    this.createTime,
  });

  factory RewardRecordModel.fromJson(Map<String, dynamic> json) {
    return RewardRecordModel(
      rewardId: json['rewardId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      rewardType: json['rewardType'] as int? ?? 0,
      rewardValue: json['rewardValue'] as int?,
      rewardName: json['rewardName'] as String?,
      sourceType: json['sourceType'] as int?,
      sourceId: json['sourceId'] as int?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rewardId': rewardId,
      'userId': userId,
      'rewardType': rewardType,
      if (rewardValue != null) 'rewardValue': rewardValue,
      if (rewardName != null) 'rewardName': rewardName,
      if (sourceType != null) 'sourceType': sourceType,
      if (sourceId != null) 'sourceId': sourceId,
      if (createTime != null) 'createTime': createTime,
    };
  }
}
