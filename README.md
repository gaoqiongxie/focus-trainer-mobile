# 🧠 Focus Trainer - 儿童注意力训练APP

> 让注意力成为孩子的超能力 ✨

一款专为3-12岁儿童设计的注意力训练应用，通过科学的训练方法和趣味化的游戏体验，帮助孩子逐步提升专注力。

## 📋 项目简介

Focus Trainer 采用 Flutter 跨平台框架开发，支持 iOS 和 Android 双端。应用包含专注时长训练、视觉追踪、听觉专注、记忆训练四大核心模块，配合星星奖励、徽章成就、连续打卡等激励机制，让孩子在快乐中提升注意力。

## 🛠️ 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.x | 跨平台UI框架 |
| Dart | 3.x | 开发语言 |
| Provider | 6.1.1 | 状态管理 |
| Dio | 5.4.0 | HTTP网络请求 |
| Shared Preferences | 2.2.2 | 本地存储 |
| Hive | 2.2.3 | 本地数据库 |
| Lottie | 3.0.0 | 动画效果 |
| AudioPlayers | 5.2.1 | 音效播放 |

## 📁 项目结构

```
focus-trainer-mobile/
├── lib/
│   ├── main.dart                    # 应用入口（Splash + Provider注册）
│   ├── config/
│   │   └── app_config.dart          # 应用配置（API地址、颜色主题）
│   ├── providers/
│   │   ├── user_provider.dart       # 用户状态管理（登录/注册/登出）
│   │   ├── training_provider.dart   # 训练状态管理（开始/完成/统计）
│   │   └── reward_provider.dart     # 激励状态管理（星星/徽章/打卡）
│   ├── screens/
│   │   ├── login_screen.dart        # 登录/注册页面
│   │   ├── home_screen.dart         # 首页（训练模块 + 统计概览）
│   │   ├── training_screen.dart     # 训练页面（准备→倒计时→结果）
│   │   └── profile_screen.dart      # 个人中心（统计+徽章墙）
│   └── utils/
│       └── http_util.dart           # HTTP工具类（Dio + Token管理）
├── pubspec.yaml                     # 依赖配置
└── README.md
```

## 🎮 核心功能

### 四大训练模块

| 模块 | 图标 | 说明 |
|------|------|------|
| 🎯 专注时长 | timer | 从5分钟开始，逐步提升持续注意力 |
| 👁️ 视觉追踪 | visibility | 增强视觉专注力和追踪能力 |
| 🎧 听觉专注 | headphones | 提升在干扰环境中的听觉注意力 |
| 🧠 记忆训练 | memory | 强化工作记忆和短期记忆 |

### 激励体系

- ⭐ **星星奖励** — 完成训练获得星星，每分钟2颗
- 🏅 **成就徽章** — 解锁各类成就徽章
- 🔥 **连续打卡** — 坚持每天训练，累积连续天数
- 📊 **进步可视化** — 训练数据图表展示

## 🚀 快速开始

### 环境要求

- Flutter 3.x+
- Dart 3.x+
- Android Studio / VS Code
- 后端服务已启动（见 [focus-trainer](../focus-trainer)）

### 1. 克隆项目

```bash
git clone <repository-url>
cd focus-trainer-mobile
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 配置后端地址

编辑 `lib/config/app_config.dart`，修改API地址：

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:8080/api/v1';
```

> 使用Android模拟器时可用 `http://10.0.2.2:8080/api/v1`

### 4. 运行

```bash
# Android
flutter run

# iOS
flutter run -d ios

# 指定设备
flutter devices
flutter run -d <device_id>
```

### 5. 构建

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## 📱 页面预览

### 启动页 → 登录/注册
- 品牌展示 + 登录状态检查
- 手机号+密码注册/登录

### 首页
- 用户信息概览（星星、连续天数、本周完成）
- 四大训练模块快速入口
- 训练模块卡片展示

### 训练页面
- **准备阶段**：训练类型、难度、时长展示
- **训练中**：圆形倒计时进度条、专注提示
- **完成结果**：训练时长、中断次数、获得星星

### 个人中心
- 用户信息卡片
- 本周训练统计
- 徽章墙（已解锁/未解锁）
- 退出登录

## 🔧 后端对接

本应用配合 [focus-trainer](../focus-trainer) 后端服务使用，主要接口：

| 模块 | 接口 |
|------|------|
| 登录 | `POST /auth/login` |
| 注册 | `POST /auth/register` |
| 开始训练 | `POST /training/start` |
| 完成训练 | `POST /training/complete` |
| 训练统计 | `GET /training/statistics` |
| 星星数量 | `GET /reward/stars` |
| 徽章列表 | `GET /reward/badges` |
| 连续打卡 | `GET /reward/streak` |

## 📄 License

MIT
