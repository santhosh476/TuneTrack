import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../data/models/stats_summary_model.dart';
import '../../../data/models/music_insight_model.dart';
import 'yearly_recap_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsTimeRange _selectedRange = StatsTimeRange.week;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsSummaryProvider(_selectedRange));
    final intelligence = ref.watch(musicIntelligenceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text('Insights & Stats',
            style: AppTypography.displayMedium.copyWith(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.primaryAccent),
            tooltip: 'View Personal Recap',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const YearlyRecapScreen()),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Time Range Selector Segment
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildRangeOption('Day', StatsTimeRange.day),
                    _buildRangeOption('Week', StatsTimeRange.week),
                    _buildRangeOption('Month', StatsTimeRange.month),
                    _buildRangeOption('Year', StatsTimeRange.year),
                    _buildRangeOption('All-Time', StatsTimeRange.allTime),
                  ],
                ),
              ),
            ),
          ),

          // 2. Overview Metric Cards Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildListDelegate([
                _buildMetricCard(
                  title: 'Listening Time',
                  value: DurationFormatter.formatListeningSeconds(
                      stats.totalListeningSeconds),
                  icon: Icons.access_time_filled_rounded,
                  color: AppColors.primaryAccent,
                ),
                _buildMetricCard(
                  title: 'Valid Plays',
                  value: '${stats.validPlaysCount}',
                  subtitle: '${stats.completedPlaysCount} completed',
                  icon: Icons.play_circle_filled_rounded,
                  color: AppColors.secondaryAccent,
                ),
                _buildMetricCard(
                  title: 'Daily Streak',
                  value: '${stats.currentStreak} Days',
                  subtitle: 'Best: ${stats.longestStreak} days',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF7675),
                ),
                _buildMetricCard(
                  title: 'Daily Goal',
                  value: '${(stats.goalProgress * 100).toInt()}%',
                  subtitle:
                      '${stats.todayListeningMinutes}/${stats.dailyGoalMinutes} mins',
                  icon: Icons.flag_rounded,
                  color: const Color(0xFF00CEC9),
                ),
              ]),
            ),
          ),

          // 3. Music Intelligence Highlights Section
          if (intelligence.insightsList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Music Intelligence',
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'LOCAL AI',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: intelligence.insightsList.length,
                  itemBuilder: (context, index) {
                    final item = intelligence.insightsList[index];
                    return _buildInsightCard(item);
                  },
                ),
              ),
            ),
          ],

          // 4. Weekly Activity Bar Chart (fl_chart)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Listening Activity',
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Minutes of playback over the past 7 days',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _calculateMaxY(stats.dailyActivity),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx >= 0 &&
                                      idx < stats.dailyActivity.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        stats.dailyActivity[idx].dayLabel,
                                        style: AppTypography.labelSmall,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups:
                              stats.dailyActivity.asMap().entries.map((e) {
                            final i = e.key;
                            final data = e.value;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: data.listeningMinutes,
                                  color: (data.listeningMinutes >=
                                          stats.dailyGoalMinutes)
                                      ? AppColors.primaryAccentLight
                                      : AppColors.primaryAccent,
                                  width: 14,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Genre Breakdown Pie Chart
          if (stats.genreDistribution.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Genre Distribution',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 130,
                            height: 130,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 30,
                                sections:
                                    _buildPieSections(stats.genreDistribution),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: stats.genreDistribution.entries
                                  .take(4)
                                  .map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 3.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(entry.key,
                                            style: AppTypography.bodySmall),
                                      ),
                                      Text(
                                        DurationFormatter
                                            .formatListeningSeconds(
                                                entry.value),
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Top 5 Tracks Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Top Tracks',
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (stats.topTracks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No tracks recorded for this timeframe yet.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = stats.topTracks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '#${index + 1}',
                              style: AppTypography.titleSmall.copyWith(
                                color: index == 0
                                    ? AppColors.primaryAccent
                                    : AppColors.secondaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          NetworkOrAssetImage(
                            imageUrl: item.artworkUrl,
                            width: 44,
                            height: 44,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                      title: Text(
                        item.title,
                        style: AppTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle:
                          Text(item.subtitle, style: AppTypography.bodySmall),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.playCount} plays',
                            style: AppTypography.labelMedium
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DurationFormatter.formatListeningSeconds(
                                item.totalDurationSeconds),
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: stats.topTracks.length.clamp(0, 5),
              ),
            ),

          // 7. Top Artists Section
          if (stats.topArtists.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Top Artists',
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final artist = stats.topArtists[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 24,
                        child: Text(
                          '#${index + 1}',
                          style: AppTypography.titleSmall.copyWith(
                            color: index == 0
                                ? AppColors.secondaryAccent
                                : AppColors.secondaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        artist.title,
                        style: AppTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        DurationFormatter.formatListeningSeconds(
                            artist.totalDurationSeconds),
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.primaryAccent),
                      ),
                    ),
                  );
                },
                childCount: stats.topArtists.length.clamp(0, 5),
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeOption(String label, StatsTimeRange range) {
    final isSelected = _selectedRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRange = range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.black : AppColors.secondaryText,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.labelMedium),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.secondaryText),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(MusicInsightItem item) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.insights_rounded, size: 16, color: AppColors.secondaryText),
            ],
          ),
          Text(
            item.metricValue,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.description,
            style: AppTypography.bodySmall.copyWith(fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<DailyActivityModel> activity) {
    double max = 30.0;
    for (final a in activity) {
      if (a.listeningMinutes > max) max = a.listeningMinutes;
    }
    return (max * 1.25);
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> genres) {
    final total = genres.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return [];

    final colors = [
      AppColors.primaryAccent,
      AppColors.secondaryAccent,
      const Color(0xFFFF7675),
      const Color(0xFF00CEC9),
      const Color(0xFFFDCB6E),
    ];

    int colorIdx = 0;
    return genres.entries.take(5).map((e) {
      final value = (e.value / total) * 100;
      final color = colors[colorIdx % colors.length];
      colorIdx++;
      return PieChartSectionData(
        value: value,
        color: color,
        radius: 20,
        showTitle: false,
      );
    }).toList();
  }
}
