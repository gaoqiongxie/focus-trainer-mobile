import 'package:flutter/material.dart';
import '../utils/http_util.dart';

class AppConfig {
  static const String appName = '专注力训练';
  
  // 后端API地址 — 统一使用 HttpUtil 中的 baseUrl
  static String get baseUrl => HttpUtil._baseUrl;
  
  // 训练类型
  static const Map<int, String> trainingTypes = {
    1: '专注时长',
    2: '视觉追踪',
    3: '听觉专注',
    4: '记忆训练',
  };

  // 训练颜色
  static const Map<int, Color> trainingColors = {
    1: Color(0xFF4A90D9),
    2: Color(0xFF50C878),
    3: Color(0xFFFF6B6B),
    4: Color(0xFFFFB347),
  };

  // 星星颜色
  static const Color starColor = Color(0xFFFFD700);
  
  // 应用主色
  static const Color primaryColor = Color(0xFF4A90D9);
  static const Color secondaryColor = Color(0xFF6C63FF);
}
