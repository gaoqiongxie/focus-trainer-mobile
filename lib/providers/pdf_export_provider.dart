import 'package:flutter/material.dart';
import '../utils/http_util.dart';

/// PDF导出 Provider
class PdfExportProvider extends ChangeNotifier {
  bool _isExporting = false;
  String? _errorMessage;
  String? _lastExportUrl;

  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;
  String? get lastExportUrl => _lastExportUrl;

  /// 导出训练报告PDF
  Future<String?> exportTrainingReport({int? childId, String period = 'week'}) async {
    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await HttpUtil.get('/report/export', params: {
        if (childId != null) 'childId': childId,
        'period': period,
      });

      if (response.statusCode == 200 && response.data['code'] == 200) {
        _lastExportUrl = response.data['data'];
        _isExporting = false;
        notifyListeners();
        return _lastExportUrl;
      } else {
        _errorMessage = response.data['message'] ?? '导出失败';
      }
    } catch (e) {
      _errorMessage = '网络错误，请重试';
    }

    _isExporting = false;
    notifyListeners();
    return null;
  }

  /// 导出周报PDF
  Future<String?> exportWeeklyReport({int? childId}) async {
    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await HttpUtil.get('/report/weekly/export', params: {
        if (childId != null) 'childId': childId,
      });

      if (response.statusCode == 200 && response.data['code'] == 200) {
        _lastExportUrl = response.data['data'];
        _isExporting = false;
        notifyListeners();
        return _lastExportUrl;
      } else {
        _errorMessage = response.data['message'] ?? '导出失败';
      }
    } catch (e) {
      _errorMessage = '网络错误，请重试';
    }

    _isExporting = false;
    notifyListeners();
    return null;
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
