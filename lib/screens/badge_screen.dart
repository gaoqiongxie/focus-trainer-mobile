import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge_model.dart';
import '../providers/reward_provider.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  String _selectedCategory = 'all';

  final List<String> _categories = ['all', 'completion', 'streak', 'accuracy', 'stars'];

  @override
  void initState() {
    super.initState();
    // 确保徽章数据已加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<RewardProvider>();
      if (rp.badges.isEmpty) {
        rp.loadBadges();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('🏅 徽章墙'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<RewardProvider>(
        builder: (context, rp, _) {
          if (rp.badges.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final earned = rp.badges.where((b) => b.earned).length;
          final total  = rp.badges.length;

          // 按分类筛选
          final filtered = _selectedCategory == 'all'
              ? rp.badges
              : rp.badges.where((b) => b.category == _selectedCategory).toList();

          return Column(
            children: [
              // 顶部统计卡片
              _buildStatHeader(earned, total),

              // 分类筛选
              _buildCategoryTabs(filtered.isEmpty ? rp.badges : filtered),

              // 徽章网格
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildBadgeCard(filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatHeader(int earned, int total) {
    final pct = total > 0 ? (earned / total * 100).round() : 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$earned / $total',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  '已解锁徽章',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? earned / total : 0,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pct%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<BadgeModel> allBadges) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          final label = _getCategoryLabel(cat);
          final count = cat == 'all'
              ? allBadges.length
              : allBadges.where((b) => b.category == cat).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('$label ($count)'),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              selectedColor: const Color(0xFF667EEA).withOpacity(0.2),
              checkmarkColor: const Color(0xFF667EEA),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'all':       return '全部';
      case 'completion': return '训练';
      case 'streak':    return '打卡';
      case 'accuracy':  return '正确率';
      case 'stars':     return '星星';
      default:          return cat;
    }
  }

  Widget _buildBadgeCard(BadgeModel badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(badge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: badge.earned ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: badge.earned
              ? Border.all(color: Colors.amber.withOpacity(0.5), width: 2)
              : null,
          boxShadow: badge.earned
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 徽章图标
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: badge.earned
                          ? _getCategoryColor(badge.category).withOpacity(0.15)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: badge.opacity,
                        child: Text(
                          badge.icon,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 徽章名称
                  Opacity(
                    opacity: badge.opacity,
                    child: Text(
                      badge.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: badge.earned ? Colors.black87 : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 分类标签
                  Opacity(
                    opacity: badge.opacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badge.earned
                            ? _getCategoryColor(badge.category).withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge.categoryLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: badge.earned
                              ? _getCategoryColor(badge.category)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 已解锁角标
            if (badge.earned)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            // 未解锁遮罩
            if (!badge.earned)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'completion': return const Color(0xFF4CAF50);
      case 'streak':     return const Color(0xFFFF7043);
      case 'accuracy':   return const Color(0xFF42A5F5);
      case 'stars':      return const Color(0xFFFFD700);
      default:           return const Color(0xFF9E9E9E);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '该分类暂无徽章',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BadgeModel badge) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: badge.earned
                    ? _getCategoryColor(badge.category).withOpacity(0.15)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Opacity(
                  opacity: badge.opacity,
                  child: Text(badge.icon, style: const TextStyle(fontSize: 48)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: badge.opacity,
              child: Text(
                badge.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badge.earned
                    ? _getCategoryColor(badge.category).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.categoryLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: badge.earned
                      ? _getCategoryColor(badge.category)
                      : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.description,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (badge.earned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '已解锁',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                '继续加油，解锁条件：${badge.description}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
