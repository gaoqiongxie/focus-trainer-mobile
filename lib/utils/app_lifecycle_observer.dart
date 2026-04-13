import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App生命周期监听器
/// 用于检测应用进入后台/恢复前台，自动暂停训练
class AppLifecycleObserver extends WidgetsBindingObserver {
  final Widget child;
  final VoidCallback? onPaused; // 暂停回调
  final VoidCallback? onResumed; // 恢复回调
  final bool autoPauseOnBackground; // 是否在退后台时自动暂停

  AppLifecycleObserver({
    required this.child,
    this.onPaused,
    this.onResumed,
    this.autoPauseOnBackground = true,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (autoPauseOnBackground) {
          onPaused?.call();
        }
        // 提示音/震动反馈
        HapticFeedback.mediumImpact();
        break;
      case AppLifecycleState.resumed:
        onResumed?.call();
        break;
      default:
        break;
    }
  }
}

/// 训练锁定包装器
/// 在训练过程中防止意外退出
class TrainingLockWrapper extends StatefulWidget {
  final Widget child;
  final bool lockEnabled;
  final VoidCallback? onExitAttempt; // 尝试退出时的回调

  const TrainingLockWrapper({
    super.key,
    required this.child,
    this.lockEnabled = false,
    this.onExitAttempt,
  });

  @override
  State<TrainingLockWrapper> createState() => _TrainingLockWrapperState();
}

class _TrainingLockWrapperState extends State<TrainingLockWrapper> {
  bool _showingLockDialog = false;

  Future<bool> _onWillPop() async {
    if (!widget.lockEnabled) return true;

    if (!_showingLockDialog) {
      _showingLockDialog = true;
      final shouldPop = await _showLockDialog();
      _showingLockDialog = false;
      if (shouldPop) {
        widget.onExitAttempt?.call();
        return true;
      }
    }
    return false;
  }

  Future<bool> _showLockDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Color(0xFF4A90D9)),
            SizedBox(width: 8),
            Text('训练锁定中'),
          ],
        ),
        content: const Text(
          '当前训练已开启锁定模式，请完成训练后再退出。\n\n'
          '如需退出，请联系家长关闭训练锁定。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续训练'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.lockEnabled) {
      return widget.child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: widget.child,
    );
  }
}
