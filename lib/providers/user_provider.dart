import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/http_util.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userInfo;
  String? _token;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userInfo => _userInfo;
  String? get errorMessage => _errorMessage;

  /// 检查登录状态
  Future<void> checkLogin() async {
    final token = await HttpUtil.getToken();
    if (token != null) {
      _isLoggedIn = true;
      _token = token;
      await _fetchProfile();
    }
    notifyListeners();
  }

  /// 登录
  Future<bool> login(String phone, String password) async {
    try {
      final response = await HttpUtil.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'];
        _token = data['token'];
        _isLoggedIn = true;
        await HttpUtil.saveToken(_token!);
        await _fetchProfile();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? '登录失败';
        return false;
      }
    } catch (e) {
      _errorMessage = '网络错误，请重试';
      return false;
    }
  }

  /// 注册
  Future<bool> register(String phone, String password, int userType, String nickname) async {
    try {
      final response = await HttpUtil.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'userType': userType,
        'nickname': nickname,
      });
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'];
        _token = data['token'];
        _isLoggedIn = true;
        await HttpUtil.saveToken(_token!);
        return true;
      } else {
        _errorMessage = response.data['message'] ?? '注册失败';
        return false;
      }
    } catch (e) {
      _errorMessage = '网络错误，请重试';
      return false;
    }
  }

  /// 获取用户信息
  Future<void> _fetchProfile() async {
    try {
      final response = await HttpUtil.get('/user/profile');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _userInfo = response.data['data'];
      }
    } catch (e) {
      // 静默处理
    }
  }

  /// 登出
  Future<void> logout() async {
    await HttpUtil.removeToken();
    _isLoggedIn = false;
    _userInfo = null;
    _token = null;
    notifyListeners();
  }
}
