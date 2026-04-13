class DailyTaskModel {
  final int taskId;
  final String title;
  final String description;
  final int trainingType;
  final int level;
  final bool completed;
  final int starReward;
  /// 奖励是否已领取（status=2）
  final bool claimed;
  /// 任务状态 0=未完成 1=已完成 2=已领取
  final int status;

  const DailyTaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.trainingType,
    required this.level,
    this.completed = false,
    this.starReward = 0,
    this.claimed = false,
    this.status = 0,
  });

  factory DailyTaskModel.fromJson(Map<String, dynamic> json) {
    final s = json['status'] as int? ?? 0;
    return DailyTaskModel(
      taskId: json['taskId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      trainingType: json['trainingType'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      completed: s >= 1,
      starReward: json['starReward'] as int? ?? 0,
      claimed: s >= 2,
      status: s,
    );
  }

  DailyTaskModel copyWith({bool? completed, bool? claimed}) {
    return DailyTaskModel(
      taskId: taskId,
      title: title,
      description: description,
      trainingType: trainingType,
      level: level,
      completed: completed ?? this.completed,
      starReward: starReward,
      claimed: claimed ?? this.claimed,
      status: claimed == true ? 2 : (completed == true ? 1 : 0),
    );
  }
}
