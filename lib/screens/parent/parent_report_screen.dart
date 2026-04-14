import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/parent_report_provider.dart';
import '../../providers/pdf_export_provider.dart';
import '../ability_evaluation_screen.dart';

/// 家长端训练报告页面
/// 包含: 仪表板总览、训练趋势、能力分析、训练记录
class ParentReportScreen extends StatefulWidget {
  const ParentReportScreen({super.key});

  @override
  State<ParentReportScreen> createState() => _ParentReportScreenState();
}

class _ParentReportScreenState extends State<ParentReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 多孩子切换
  int? _selectedChildId;
  List<Map<String, dynamic>> _childrenList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    // 加载孩子列表（从后端或本地缓存）
    // 这里模拟一个孩子列表
    setState(() {
      _childrenList = [
        {'childId': null, 'nickname': '当前孩子'},
      ];
      _selectedChildId = null;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<ParentReportProvider>().loadAll(childId: _selectedChildId, trendDays: 7);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParentReportProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('训练报告', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_childrenList.length > 1) ...[
              const SizedBox(width: 8),
              _buildChildSelector(),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A90D9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4A90D9),
          tabs: const [
            Tab(text: '总览'),
            Tab(text: '趋势'),
            Tab(text: '记录'),
          ],
        ),
        actions: [
          // 导出PDF按钮
          Consumer<PdfExportProvider>(
            builder: (context, pdfProvider, _) => IconButton(
              icon: pdfProvider.isExporting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: pdfProvider.isExporting ? null : _exportPdf,
              tooltip: '导出PDF报告',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(provider),
                _buildTrendTab(provider),
                _buildRecordsTab(provider),
              ],
            ),
    );
  }

  // ==================== 总览 Tab ====================
  Widget _buildOverviewTab(ParentReportProvider provider) {
    final dashboard = provider.dashboard;
    final ability = provider.ability;
    final weekly = provider.weeklyReport;

    if (dashboard == null) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 儿童信息卡片
          if (dashboard['child'] != null) _buildChildCard(dashboard['child']),
          const SizedBox(height: 16),

          // 本周统计卡片
          _buildPeriodStatsCard('📊 本周统计', dashboard['week'], const Color(0xFF4A90D9)),
          const SizedBox(height: 16),

          // 今日统计卡片
          _buildPeriodStatsCard('📅 今日统计', dashboard['today'], const Color(0xFF50C878)),
          const SizedBox(height: 16),

          // 能力雷达图（简化版）
          if (ability != null) ...[
            _buildAbilityRadarCard(ability),
            const SizedBox(height: 16),
          ],

          // 周报亮点
          if (weekly != null && weekly['highlights'] != null) ...[
            _buildHighlightsCard(weekly['highlights']),
            const SizedBox(height: 16),
          ],

          // 训练类型分布
          if (weekly != null && weekly['typeDistribution'] != null) ...[
            _buildTypeDistCard(weekly['typeDistribution']),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF4A90D9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: (child['avatar'] != null && child['avatar'].toString().isNotEmpty)
                ? ClipOval(child: Image.network(
                    child['avatar'],
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.child_care, size: 28, color: Colors.white),
                  ))
                : const Icon(Icons.child_care, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                child['nickname'] ?? '小朋友',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text('训练报告', style: TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodStatsCard(String title, Map<String, dynamic>? stats, Color accentColor) {
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('训练次数', '${stats['totalCount'] ?? 0}', '次', accentColor),
              _buildStatDivider(),
              _buildStatColumn('总时长', '${_formatMinutes(stats['totalDurationMinutes'])}', '分钟', accentColor),
              _buildStatDivider(),
              _buildStatColumn('完成率', '${stats['completionRate'] ?? 0}%', '', accentColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('⭐ 星星', '${stats['totalStars'] ?? 0}', '', const Color(0xFFFFD700)),
              _buildStatDivider(),
              _buildStatColumn('正确率', '${stats['avgAccuracy'] ?? 0}%', '', const Color(0xFF50C878)),
              _buildStatDivider(),
              _buildStatColumn('🏆 得分', '${stats['totalScore'] ?? 0}', '', const Color(0xFFFF8C42)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            children: [
              if (unit.isNotEmpty)
                TextSpan(text: unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade200);
  }

  // ==================== 能力雷达图（简化柱状版） ====================
  Widget _buildAbilityRadarCard(Map<String, dynamic> ability) {
    final radarData = ability['radarData'] as List<dynamic>?;
    if (radarData == null || radarData.isEmpty) return const SizedBox.shrink();

    final level = ability['level'] ?? 'E';
    final totalScore = ability['totalScore'] ?? 0;
    final levelColors = {
      'A': const Color(0xFF4CAF50),
      'B': const Color(0xFF50C878),
      'C': const Color(0xFFFFB347),
      'D': const Color(0xFFFF8C42),
      'E': const Color(0xFFFF6B6B),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🧠 能力分析', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (levelColors[level] ?? Colors.grey).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '综合 $totalScore 分 · $level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: levelColors[level] ?? Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AbilityEvaluationScreen()),
                    ),
                    tooltip: '详细能力评估',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...radarData.map<Widget>((item) {
            final data = item as Map<String, dynamic>;
            final dimension = data['dimension'] as String;
            final score = (data['score'] as num).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dimension, style: const TextStyle(fontSize: 14)),
                      Text('${score.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _getScoreColor(score))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF50C878);
    if (score >= 40) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  // ==================== 亮点卡片 ====================
  Widget _buildHighlightsCard(List<dynamic> highlights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 训练洞察', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...highlights.map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(h.toString(), style: const TextStyle(fontSize: 14, height: 1.6)),
          )),
        ],
      ),
    );
  }

  // ==================== 训练类型分布 ====================
  Widget _buildTypeDistCard(Map<String, dynamic> typeDist) {
    final dist = typeDist['distribution'] as Map<String, dynamic>?;
    if (dist == null || dist.isEmpty) return const SizedBox.shrink();

    final total = typeDist['total'] ?? 1;
    final typeColors = {
      '专注时长': const Color(0xFF4A90D9),
      '视觉追踪': const Color(0xFF50C878),
      '听觉专注': const Color(0xFFFF6B6B),
      '记忆训练': const Color(0xFFFFB347),
      '数字闪现': const Color(0xFFFF8C42),
      '卡片配对': const Color(0xFF9C27B0),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 训练分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...dist.entries.map((e) {
            final count = e.value as int;
            final pct = (count / total * 100).toStringAsFixed(0);
            final color = typeColors[e.key] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 14)),
                      Text('$count次 ($pct%)', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: count / total,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== 趋势 Tab ====================
  Widget _buildTrendTab(ParentReportProvider provider) {
    final trend = provider.trend;

    if (trend.isEmpty) {
      return const Center(child: Text('暂无趋势数据', style: TextStyle(color: Colors.grey)));
    }

    // 计算最大值用于归一化
    final durationList = trend.map((d) => (d['totalDuration'] as int?) ?? 0).toList();
    final maxDuration = durationList.isEmpty ? 0.0 : durationList.reduce((a, b) => a > b ? a : b).toDouble();
    final countList = trend.map((d) => (d['totalCount'] as int?) ?? 0).toList();
    final maxCount = countList.isEmpty ? 0.0 : countList.reduce((a, b) => a > b ? a : b).toDouble();

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ParentReportProvider>().loadTrend(trendDays: 7);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('📅 最近7天训练趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 训练时长柱状图
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('训练时长（分钟）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: trend.map((d) {
                      final dur = ((d['totalDuration'] as int?) ?? 0) / 60.0;
                      final height = maxDuration > 0 ? (dur / maxDuration * 120) : 0.0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${dur.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Container(
                                height: height.clamp(2.0, 120.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A90D9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: trend.map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d['weekday']?.toString().substring(1) ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 训练次数柱状图
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('训练次数', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: trend.map((d) {
                      final count = (d['totalCount'] as int?) ?? 0;
                      final height = maxCount > 0 ? (count / maxCount * 120) : 0.0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('$count', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Container(
                                height: height.clamp(2.0, 120.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF50C878),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: trend.map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d['weekday']?.toString().substring(1) ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 每日正确率
          ...trend.map((d) {
            final accuracy = (d['avgAccuracy'] as num?)?.toDouble() ?? 0;
            final count = (d['totalCount'] as int?) ?? 0;
            if (count == 0) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(d['weekday'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: accuracy / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(accuracy)),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${accuracy.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== 记录 Tab ====================
  Widget _buildRecordsTab(ParentReportProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ParentReportProvider>().loadRecords();
      },
      child: provider.records.isEmpty
          ? const Center(child: Text('暂无训练记录', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.records.length,
              itemBuilder: (context, index) {
                final record = provider.records[index];
                return _buildRecordCard(record);
              },
            ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final statusColor = record['status'] == 1 ? const Color(0xFF50C878) : (record['status'] == 2 ? Colors.red : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            record['typeName'] ?? '训练',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          record['statusName'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record['startTime'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '⭐ ${record['starReward'] ?? 0}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record['score'] ?? 0}分',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRecordMetric('时长', '${_formatSeconds(record['actualDuration'])}'),
              _buildRecordMetric('正确率', '${record['accuracy'] ?? "-"}%'),
              _buildRecordMetric('难度', 'Lv.${record['level'] ?? 1}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  String _formatMinutes(dynamic value) {
    if (value == null) return '0';
    return (value as num).toStringAsFixed(0);
  }

  String _formatSeconds(dynamic value) {
    if (value == null) return '-';
    final s = (value as num).toInt();
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '${m}分${sec}秒' : '${sec}秒';
  }

  /// 多孩子切换下拉框
  Widget _buildChildSelector() {
    return PopupMenuButton<int?>(
      onSelected: (childId) {
        setState(() => _selectedChildId = childId);
        _loadData();
      },
      itemBuilder: (context) => _childrenList.map((child) {
        return PopupMenuItem<int?>(
          value: child['childId'] as int?,
          child: Row(
            children: [
              if (child['childId'] == _selectedChildId || 
                  (child['childId'] == null && _selectedChildId == null))
                const Icon(Icons.check, size: 18, color: Color(0xFF4A90D9))
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(child['nickname'] ?? '孩子'),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90D9).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, size: 18, color: Color(0xFF4A90D9)),
            const SizedBox(width: 4),
            Text(
              _getSelectedChildName(),
              style: const TextStyle(fontSize: 13, color: Color(0xFF4A90D9), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _getSelectedChildName() {
    final selected = _childrenList.firstWhere(
      (c) => c['childId'] == _selectedChildId,
      orElse: () => _childrenList.first,
    );
    return selected['nickname'] ?? '孩子';
  }

  /// 导出PDF报告
  Future<void> _exportPdf() async {
    final pdfProvider = context.read<PdfExportProvider>();
    
    // 显示导出选项
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.picture_as_pdf, size: 48, color: Color(0xFF4A90D9)),
            const SizedBox(height: 16),
            const Text('导出PDF报告', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildExportOption(
              icon: Icons.calendar_today,
              title: '本周报告',
              subtitle: '导出本周训练数据',
              onTap: () => Navigator.of(context).pop('week'),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.date_range,
              title: '本月报告',
              subtitle: '导出本月训练数据',
              onTap: () => Navigator.of(context).pop('month'),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.analytics,
              title: '完整报告',
              subtitle: '导出所有训练数据',
              onTap: () => Navigator.of(context).pop('all'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result == null) return;

    final url = await pdfProvider.exportTrainingReport(
      childId: _selectedChildId,
      period: result,
    );

    if (!mounted) return;

    if (url != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF报告已生成'),
          action: SnackBarAction(
            label: '下载',
            onPressed: () {
              // TODO: 使用 url_launcher 或其他方式打开PDF
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pdfProvider.errorMessage ?? '导出失败')),
      );
    }
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF4A90D9)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
