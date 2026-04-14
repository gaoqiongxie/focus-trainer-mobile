import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 错误 Snackbar 监听器
///
/// 包装页面 body，通过 didChangeDependencies 监听多个 Provider 的 errorMessage，
/// 首次出现错误时弹出 Snackbar。
///
/// 使用示例：
/// ```dart
/// ErrorSnackbarListener(
///   providers: [
///     context.read<RewardProvider>,
///     context.read<TrainingProvider>,
///   ],
///   child: MyScreenBody(),
/// )
/// ```
class ErrorSnackbarListener extends StatefulWidget {
  /// 要监听的 Provider 列表，传入 Provider 实例
  final List<ChangeNotifier> providers;
  final Widget child;

  const ErrorSnackbarListener({
    super.key,
    required this.providers,
    required this.child,
  });

  @override
  State<ErrorSnackbarListener> createState() => _ErrorSnackbarListenerState();
}

class _ErrorSnackbarListenerState extends State<ErrorSnackbarListener> {
  String? _lastShownError;

  String? _collectError() {
    for (final p in widget.providers) {
      final err = (p as dynamic).errorMessage as String?;
      if (err != null && err.isNotEmpty) return err;
    }
    return null;
  }

  void _checkAndShowError(BuildContext context) {
    if (!mounted || !context.mounted) return;
    final error = _collectError();
    if (error != null && error != _lastShownError) {
      _lastShownError = error;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '关闭',
            textColor: Colors.white,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
    // 错误被清除后，重置 guard，允许下次报错时再弹
    if (error == null) _lastShownError = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndShowError(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
