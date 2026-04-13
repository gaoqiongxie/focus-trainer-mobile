import 'package:flutter/material.dart';
import '../utils/http_util.dart';

/// 通知模型
class NotificationModel {
  final int id;
  final String title;
  final String content;
  final int type; // 1=训练提醒, 2=奖励通知, 3=专家建议
  final bool isRead;
  final String? createTime;
  final Map<String, dynamic>? extra; // 额外数据

  const NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.isRead = false,
    this.createTime,
    this.extra,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as int? ?? 1,
      isRead: json['isRead'] as bool? ?? false,
      createTime: json['createTime'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'isRead': isRead,
      if (createTime != null) 'createTime': createTime,
      if (extra != null) 'extra': extra,
    };
  }

  /// 获取通知类型名称
  String get typeName {
    switch (type) {
      case 1: return '训练提醒';
      case 2: return '奖励通知';
      case 3: return '专家建议';
      default: return '系统通知';
    }
  }

  /// 获取通知类型图标
  IconData get typeIcon {
    switch (type) {
      case 1: return Icons.notifications_active;
      case 2: return Icons.stars;
      case 3: return Icons.lightbulb;
      default: return Icons.notifications;
    }
  }

  /// 获取通知类型颜色
  Color get typeColor {
    switch (type) {
      case 1: return const Color(0xFF4A90D9);
      case 2: return const Color(0xFFFFD700);
      case 3: return const Color(0xFF50C878);
      default: return Colors.grey;
    }
  }
}

/// 通知 Provider
class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取未读数量
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// 加载通知列表
  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await HttpUtil.get('/notification/list');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _notifications = list
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = response.data['message'] ?? '获取通知失败';
      }
    } catch (e) {
      _errorMessage = '网络错误，请重试';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 标记单条通知已读
  Future<bool> markAsRead(int id) async {
    try {
      final response = await HttpUtil.post('/notification/read', data: {'id': id});
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            title: _notifications[index].title,
            content: _notifications[index].content,
            type: _notifications[index].type,
            isRead: true,
            createTime: _notifications[index].createTime,
            extra: _notifications[index].extra,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      // 静默处理
    }
    return false;
  }

  /// 标记全部已读
  Future<bool> markAllAsRead() async {
    try {
      final response = await HttpUtil.post('/notification/read-all');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _notifications = _notifications
            .map((n) => NotificationModel(
                  id: n.id,
                  title: n.title,
                  content: n.content,
                  type: n.type,
                  isRead: true,
                  createTime: n.createTime,
                  extra: n.extra,
                ))
            .toList();
        notifyListeners();
        return true;
      }
    } catch (e) {
      // 静默处理
    }
    return false;
  }

  /// 删除通知
  Future<bool> deleteNotification(int id) async {
    try {
      final response = await HttpUtil.delete('/notification/$id');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      // 静默处理
    }
    return false;
  }
}
