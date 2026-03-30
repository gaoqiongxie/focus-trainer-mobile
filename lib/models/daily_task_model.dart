class DailyTaskModel {
  final int taskId;
  final String title;
  final String description;
  final int trainingType;
  final int level;
  final bool completed;
  final int starReward;

  const DailyTaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.trainingType,
    required this.level,
    this.completed = false,
    this.starReward = 0,
  });

  factory DailyTaskModel.fromJson(Map<String, dynamic> json) {
    return DailyTaskModel(
      taskId: json['taskId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      trainingType: json['trainingType'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      completed: json['completed'] as bool? ?? false,
      starReward: json['starReward'] as int? ?? 0,
    );
  }

  DailyTaskModel copyWith({bool? completed}) {
    return DailyTaskModel(
      taskId: taskId,
      title: title,
      description: description,
      trainingType: trainingType,
      level: level,
      completed: completed ?? this.completed,
      starReward: starReward,
    );
  }
}
