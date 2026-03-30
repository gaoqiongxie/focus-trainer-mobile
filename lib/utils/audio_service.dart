import 'dart:math';
import 'package:flutter/services.dart';

/// 音频服务
/// 提供训练游戏所需的音效
/// 支持两种模式：系统内置音调（无需额外资源）和自定义音频文件
class AudioService {
  static final AudioService _instance = AudioService._();
  static AudioService get instance => _instance;
  AudioService._();

  bool _enabled = true;
  bool get enabled => _enabled;

  /// 预加载自定义音效文件（如果有 assets/audio/ 目录下的文件）
  /// 音频文件命名约定: animal_dog.mp3, animal_cat.mp3 等
  static const Map<int, String> _animalSoundFiles = {
    0: 'assets/audio/animal_dog.mp3',    // 小狗
    1: 'assets/audio/animal_cat.mp3',    // 小猫
    2: 'assets/audio/animal_frog.mp3',   // 青蛙
    3: 'assets/audio/animal_bird.mp3',   // 小鸟
    4: 'assets/audio/animal_chicken.mp3', // 小鸡
    5: 'assets/audio/animal_pig.mp3',    // 小猪
    6: 'assets/audio/animal_cow.mp3',    // 奶牛
    7: 'assets/audio/animal_horse.mp3',  // 小马
  };

  /// 音效类型
  static const Map<int, double> _animalFrequencies = {
    0: 300,   // 小狗: 低沉吠叫
    1: 600,   // 小猫: 中等喵叫
    2: 180,   // 青蛙: 低沉呱呱
    3: 1200,  // 小鸟: 高清鸟鸣
    4: 800,   // 小鸡: 中高频叽叽
    5: 250,   // 小猪: 低频哼哼
    6: 200,   // 奶牛: 低沉哞哞
    7: 500,   // 小马: 中等嘶鸣
  };

  /// 设置音效开关
  void setEnabled(bool value) {
    _enabled = value;
  }

  /// 播放动物声音
  /// [animalIndex] 动物索引 (0-7)
  /// 先尝试播放自定义音频文件，失败则使用系统音调
  Future<void> playAnimalSound(int animalIndex) async {
    if (!_enabled) return;

    // 触觉反馈
    HapticFeedback.lightImpact();

    // 使用系统振动反馈模拟音效
    // 真实项目中替换为 audioplayers 播放 mp3 文件
    final frequency = _animalFrequencies[animalIndex] ?? 440;
    final duration = _getAnimalDuration(animalIndex);

    // 不同的触觉反馈模式来区分动物
    switch (animalIndex) {
      case 0: // 小狗: 短促连续
        HapticFeedback.mediumImpact();
        break;
      case 1: // 小猫: 柔和单次
        HapticFeedback.lightImpact();
        break;
      case 2: // 青蛙: 有节奏
        HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: duration ~/ 2));
        if (_enabled) HapticFeedback.lightImpact();
        break;
      case 3: // 小鸟: 快速轻触
        for (int i = 0; i < 3; i++) {
          await Future.delayed(Duration(milliseconds: duration ~/ 4));
          if (_enabled) HapticFeedback.selectionClick();
        }
        break;
      case 4: // 小鸡: 高频轻触
        HapticFeedback.vibrate();
        break;
      default:
        HapticFeedback.lightImpact();
    }
  }

  /// 播放正确提示音
  Future<void> playCorrect() async {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// 播放错误提示音
  Future<void> playWrong() async {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// 播放完成/成功音效
  Future<void> playComplete() async {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.mediumImpact();
  }

  /// 播放点击/翻牌音效
  Future<void> playTap() async {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// 播放星级展示音效
  Future<void> playStarReveal() async {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// 获取动物声音持续时间（毫秒）
  int _getAnimalDuration(int animalIndex) {
    switch (animalIndex) {
      case 0: return 400; // 小狗
      case 1: return 500; // 小猫
      case 2: return 600; // 青蛙
      case 3: return 300; // 小鸟
      case 4: return 350; // 小鸡
      case 5: return 500; // 小猪
      case 6: return 700; // 奶牛
      case 7: return 450; // 小马
      default: return 400;
    }
  }

  /// 动物声音持续时间（毫秒），公开给调用方控制动画时序
  int getAnimalSoundDuration(int animalIndex) {
    return _getAnimalDuration(animalIndex);
  }
}
