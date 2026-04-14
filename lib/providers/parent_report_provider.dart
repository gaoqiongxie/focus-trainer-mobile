import 'package:flutter/material.dart';
import '../utils/http_util.dart';

/// 家长端数据报告 Provider
class ParentReportProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // 仪表板数据
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? get dashboard => _dashboard;

  // 趋势数据
  List<Map<String, dynamic>> _trend = [];
  List<Map<String, dynamic>> get trend => _trend;

  // 能力分析数据
  Map<String, dynamic>? _ability;
  Map<String, dynamic>? get ability => _ability;

  // 训练记录
  List<Map<String, dynamic>> _records = [];
  int _totalRecords = 0;
  int _currentPage = 1;
  List<Map<String, dynamic>> get records => _records;
  int get totalRecords => _totalRecords;

  // 周报
  Map<String, dynamic>? _weeklyReport;
  Map<String, dynamic>? get weeklyReport => _weeklyReport;

  bool get isLoading => _isLoading;

  /// 加载仪表板
  Future<void> loadDashboard({int? childId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await HttpUtil.get('/parent/report/dashboard', params: {
        if (childId != null) 'childId': childId,
      });
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _dashboard = response.data['data'];
      }
    } catch (e) {
      _errorMessage = '加载仪表板失败';
      debugPrint('[ParentReportProvider] loadDashboard error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// 加载训练趋势
  Future<void> loadTrend({int? childId, int days = 7}) async {
    try {
      final response = await HttpUtil.get('/parent/report/trend', params: {
        if (childId != null) 'childId': childId,
        'days': days,
      });
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _trend = List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      _errorMessage = '加载趋势数据失败';
      debugPrint('[ParentReportProvider] loadTrend error: $e');
    }
    notifyListeners();
  }

  /// 加载能力分析
  Future<void> loadAbility({int? childId}) async {
    try {
      final response = await HttpUtil.get('/parent/report/ability', params: {
        if (childId != null) 'childId': childId,
      });
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _ability = response.data['data'];
      }
    } catch (e) {
      _errorMessage = '加载能力分析失败';
      debugPrint('[ParentReportProvider] loadAbility error: $e');
    }
    notifyListeners();
  }

  /// 加载训练记录
  Future<void> loadRecords({int? childId, int? trainingType, int page = 1, int size = 20}) async {
    try {
      final response = await HttpUtil.get('/parent/report/records', params: {
        if (childId != null) 'childId': childId,
        if (trainingType != null) 'trainingType': trainingType,
        'page': page,
        'size': size,
      });
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'];
        _records = List<Map<String, dynamic>>.from(data['records'] ?? []);
        _totalRecords = data['total'] ?? 0;
        _currentPage = page;
      }
    } catch (e) {
      _errorMessage = '加载训练记录失败';
      debugPrint('[ParentReportProvider] loadRecords error: $e');
    }
    notifyListeners();
  }

  /// 加载周报
  Future<void> loadWeeklyReport({int? childId}) async {
    try {
      final response = await HttpUtil.get('/parent/report/weekly', params: {
        if (childId != null) 'childId': childId,
      });
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _weeklyReport = response.data['data'];
      }
    } catch (e) {
      _errorMessage = '加载周报失败';
      debugPrint('[ParentReportProvider] loadWeeklyReport error: $e');
    }
    notifyListeners();
  }

  /// 一次性加载所有报告数据
  Future<void> loadAll({int? childId, int trendDays = 7}) async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadDashboard(childId: childId),
      loadTrend(childId: childId, days: trendDays),
      loadAbility(childId: childId),
      loadWeeklyReport(childId: childId),
    ]);

    _isLoading = false;
    notifyListeners();
  }
}
