/// 称号模型
class TitleModel {
  final int id;
  final String name;
  final String description;
  final String icon;
  final int level; // 称号等级 1-5
  final bool unlocked;
  final String? unlockCriteria; // 解锁条件
  final String? unlockedAt; // 解锁时间

  const TitleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.level,
    this.unlocked = false,
    this.unlockCriteria,
    this.unlockedAt,
  });

  factory TitleModel.fromJson(Map<String, dynamic> json) {
    return TitleModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏅',
      level: json['level'] as int? ?? 1,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockCriteria: json['unlockCriteria'] as String?,
      unlockedAt: json['unlockedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'level': level,
      'unlocked': unlocked,
      if (unlockCriteria != null) 'unlockCriteria': unlockCriteria,
      if (unlockedAt != null) 'unlockedAt': unlockedAt,
    };
  }

  /// 获取等级名称
  String get levelName {
    switch (level) {
      case 1: return '初级';
      case 2: return '中级';
      case 3: return '高级';
      case 4: return '专家';
      case 5: return '大师';
      default: return '初级';
    }
  }

  /// 获取等级颜色
  int get levelColorValue {
    switch (level) {
      case 1: return 0xFF9E9E9E; // 灰色
      case 2: return 0xFF4CAF50; // 绿色
      case 3: return 0xFF2196F3; // 蓝色
      case 4: return 0xFF9C27B0; // 紫色
      case 5: return 0xFFFFD700; // 金色
      default: return 0xFF9E9E9E;
    }
  }

  /// 获取透明度和颜色（用于未解锁显示）
  double get opacity => unlocked ? 1.0 : 0.4;
}
