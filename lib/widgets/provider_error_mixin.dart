import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Provider 错误横幅 Mixin
///
/// 在 State 中混入此类，即可自动监听 errorMessage 并弹出 Snackbar。
///
/// 示例:
///   class _HomeScreenState extends State<HomeScreen> with ProviderErrorMixin {
///     @override
///     void initState() {
///       // 注册要监听的 Provider (返回 errorMessage)
///       registerProviderError<RewardProvider>((p) => p.errorMessage);
///       registerProviderError<TrainingProvider>((p) => p.errorMessage);
///       super.initState();
///     }
///   }
mixin ProviderErrorMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  final List<_ErrorBinding> _errorBindings = [];
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _errorBindings.clear();
    super.dispose();
  }

  /// 注册一个 Provider 的 errorMessage 监听
  void registerProviderError<P extends ChangeNotifier>(
    String? Function(P) getError,
  ) {
    _errorBindings.add(_ErrorBinding<P>(getError));
  }

  /// 显示错误 Snackbar（子类可重写定制样式）
  void showErrorSnackbar(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// 刷新所有已注册 Provider 的错误状态（每次 build 时调用）
  void checkProviderErrors(BuildContext context) {
    for (final binding in _errorBindings) {
      binding.checkAndNotify(context, this);
    }
  }
}

class _ErrorBinding<P extends ChangeNotifier> {
  final String? Function(P) _getError;

  _ErrorBinding(this._getError);

  void checkAndNotify(BuildContext context, WidgetRef state) {
    if (!context.mounted) return;
    final provider = context.read<P>();
    final error = _getError(provider);
    if (error != null && error != _getErrorPrevious) {
      _getErrorPrevious = error;
      state.showErrorSnackbar(context, error);
      // 清除错误，阻止重复弹窗
      Future.microtask(() {
        if (state.mounted) {
          provider.notifyListeners(); // 触发重新检查
        }
      });
    }
  }

  String? _getErrorPrevious;
}
