import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/title_model.dart';
import '../utils/http_util.dart';

/// 称号墙页面
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  List<TitleModel> _titles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTitles();
  }

  Future<void> _loadTitles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HttpUtil.get('/title/list');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _titles = list.map((e) => TitleModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = response.data['message'] ?? '获取称号失败';
      }
    } catch (e) {
      _errorMessage = '网络错误，请重试';
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('称号墙', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTitles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTitles,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _titles.isEmpty
                  ? _buildEmptyState()
                  : _buildTitleGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            '暂无可用称号',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '完成训练任务解锁专属称号',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleGrid() {
    // 按等级分组
    final unlockedTitles = _titles.where((t) => t.unlocked).toList();
    final lockedTitles = _titles.where((t) => !t.unlocked).toList();

    return RefreshIndicator(
      onRefresh: _loadTitles,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 已获得称号
          if (unlockedTitles.isNotEmpty) ...[
            _buildSectionHeader('已获得称号', unlockedTitles.length, const Color(0xFFFFD700)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: unlockedTitles.length,
              itemBuilder: (context, index) => _buildTitleCard(unlockedTitles[index], showAnimation: true),
            ),
            const SizedBox(height: 24),
          ],

          // 未解锁称号
          if (lockedTitles.isNotEmpty) ...[
            _buildSectionHeader('待解锁', lockedTitles.length, Colors.grey),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: lockedTitles.length,
              itemBuilder: (context, index) => _buildTitleCard(lockedTitles[index], showAnimation: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleCard(TitleModel title, {required bool showAnimation}) {
    final color = Color(title.levelColorValue);

    return GestureDetector(
      onTap: () => _showTitleDetail(title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: title.unlocked
              ? Border.all(color: color.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: title.unlocked
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: title.unlocked ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 称号图标/动画
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(title.opacity * 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: showAnimation && title.level >= 4
                        ? SizedBox(
                            width: 50, height: 50,
                            child: Lottie.asset(
                              'assets/animations/star.json',
                              repeat: true,
                              errorBuilder: (_, __) => Text(
                                title.icon,
                                style: TextStyle(fontSize: 32, color: Color(title.levelColorValue)),
                              ),
                            ),
                          )
                        : Text(
                            title.icon,
                            style: TextStyle(
                              fontSize: 32,
                              color: Color(title.levelColorValue),
                            ),
                          ),
                  ),
                ),
                if (!title.unlocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 称号名称
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: title.unlocked ? Colors.black87 : Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 等级标签
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(title.opacity * 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                title.levelName,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(title.opacity),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTitleDetail(TitleModel title) {
    final color = Color(title.levelColorValue);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // 称号图标
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(title.icon, style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 16),

            // 称号名称
            Text(
              title.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),

            // 等级
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${title.levelName}称号',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 描述
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('称号描述', title.description),
                  if (title.unlockCriteria != null)
                    _buildDetailRow('解锁条件', title.unlockCriteria!),
                  if (title.unlockedAt != null)
                    _buildDetailRow('获得时间', title.unlockedAt!),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
