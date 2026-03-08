import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/models/global_stats_model.dart';

class AnalyticsChart extends StatelessWidget {
  final GlobalStats stats;

  const AnalyticsChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            tooltipBorder: const BorderSide(color: AppColors.primary, width: 1),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = '';
              switch (group.x) {
                case 0:
                  label = 'Bottles';
                  break;
                case 1:
                  label = 'Cans';
                  break;
                case 2:
                  label = 'Kg';
                  break;
              }
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.toInt().toString(),
                    style: TextStyle(
                      color: rod.gradient?.colors.first ?? rod.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Bottles';
                    break;
                  case 1:
                    text = 'Cans';
                    break;
                  case 2:
                    text = 'Weight';
                    break;
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, stats.totalBottles.toDouble(), AppColors.primary),
          _makeGroupData(1, stats.totalCans.toDouble(), AppColors.secondary),
          _makeGroupData(2, stats.totalWeightKg, Colors.purple),
        ],
      ),
    );
  }

  double _getMaxValue() {
    double max = stats.totalBottles.toDouble();
    if (stats.totalCans > max) max = stats.totalCans.toDouble();
    if (stats.totalWeightKg > max) max = stats.totalWeightKg;
    return max > 0 ? max : 10;
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _getMaxValue() * 1.2,
            color: color.withOpacity(0.05),
          ),
        ),
      ],
    );
  }
}
