import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../utils/http_util.dart';

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
          final old = _notifications[index];
          _notifications[index] = NotificationModel(
            id: old.id,
            title: old.title,
            content: old.content,
            type: old.type,
            isRead: true,
            createTime: old.createTime,
            extra: old.extra,
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
