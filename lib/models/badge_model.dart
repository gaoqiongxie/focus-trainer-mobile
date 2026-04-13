/// 徽章数据模型（对应后端 badge + user_badge 表）
class BadgeModel {
  final int badgeId;
  final String badgeKey;
  final String name;
  final String description;
  final String icon;
  final String category;  // completion/streak/accuracy/stars/special
  final bool earned;
  final String? earnedAt;

  const BadgeModel({
    required this.badgeId,
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.earned,
    this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeId:    json['badgeId']    as int?    ?? 0,
      badgeKey:   json['badgeKey']   as String? ?? '',
      name:       json['name']        as String? ?? '',
      description:json['description'] as String? ?? '',
      icon:       json['icon']       as String? ?? '🏅',
      category:   json['category']    as String? ?? '',
      earned:     json['earned']     as bool?   ?? false,
      earnedAt:   json['earnedAt']   as String?,
    );
  }

  /// 徽章分类颜色
  String get categoryLabel {
    switch (category) {
      case 'completion': return '训练';
      case 'streak':     return '打卡';
      case 'accuracy':   return '正确率';
      case 'stars':      return '星星';
      case 'special':    return '特殊';
      default:           return '其他';
    }
  }

  /// 未解锁徽章的灰色遮罩透明度
  double get opacity => earned ? 1.0 : 0.35;
}
