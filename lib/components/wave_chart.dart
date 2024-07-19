import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wavefinder/components/functions.dart';
import 'package:wavefinder/theme/colors.dart';

class WaveChart extends StatelessWidget {
  final List<Map<String, dynamic>> waveData;

  const WaveChart({super.key, required this.waveData});

  @override
  Widget build(BuildContext context) {
    // Create a list of data points for wave height
    final List<FlSpot> waveHeightPoints = waveData.asMap().entries.map((entry) {
      final index = entry.key;
      final wave = entry.value;
      final waveHeight = wave['waveheight'] != null ? double.tryParse(wave['waveheight'].toString()) ?? 0.0 : 0.0;
      return FlSpot(index.toDouble(), waveHeight);
    }).toList();

    // Create a list of data points for swell height
    final List<FlSpot> swellHeightPoints = waveData.asMap().entries.map((entry) {
      final index = entry.key;
      final wave = entry.value;
      final swellHeight = wave['swellwaveheight'] != null ? double.tryParse(wave['swellwaveheight'].toString()) ?? 0.0 : 0.0;
      return FlSpot(index.toDouble(), swellHeight);
    }).toList();

    // Calculate the maximum y-value for wave height
    final double maxWaveHeight = waveHeightPoints.isNotEmpty
        ? waveHeightPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Calculate the maximum y-value for swell height
    final double maxSwellHeight = swellHeightPoints.isNotEmpty
        ? swellHeightPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Determine the maximum y-value for the chart
    final double maxY = maxWaveHeight > maxSwellHeight ? maxWaveHeight : maxSwellHeight;

    // Calculate the minimum y-value for wave height
    final double minWaveHeight = waveHeightPoints.isNotEmpty
        ? waveHeightPoints.map((e) => e.y).reduce((a, b) => a < b ? a : b)
        : 0.0;

    // Calculate the minimum y-value for swell height
    final double minSwellHeight = swellHeightPoints.isNotEmpty
        ? swellHeightPoints.map((e) => e.y).reduce((a, b) => a < b ? a : b)
        : 0.0;
    // Determine the minimum y-value for the chart
    final double minY = (minWaveHeight < 0 || minSwellHeight < 0) 
      ? (minWaveHeight < minSwellHeight ? minWaveHeight : minSwellHeight) 
      : 0.0;

    return Column(
      children: [
        // Add a legend
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(ThemeColors.bubblesColor, 'Wave Height'),
              const SizedBox(width: 16),
              _buildLegendItem(ThemeColors.swellBlue, 'Swell Height'),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              backgroundColor: ThemeColors.background,
              lineBarsData: [
                // Line for swell height (drawn first, in the background)
                LineChartBarData(
                  spots: swellHeightPoints,
                  preventCurveOverShooting: true,
                  shadow: const Shadow(color: ThemeColors.bubblesColor),
                  isCurved: true,
                  color: ThemeColors.swellBlue,
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: true,
                    color: ThemeColors.swellBlue.withOpacity(0.3),
                  ),
                  dotData: const FlDotData(show: false),
                ),
                // Line for wave height (drawn second, in the foreground)
                LineChartBarData(
                  spots: waveHeightPoints,
                  preventCurveOverShooting: true,
                  shadow: const Shadow(color: ThemeColors.bubblesColor),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.3),
                  ),
                  dotData: const FlDotData(show: false),
                ),
              ],
              minX: 0,
              maxX: waveData.length.toDouble() - 1,
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 19,
                    getTitlesWidget: (value, meta) {
                      // Check if value is an integer
                      if (value % 1 == 0) {
                        final index = value.toInt();
                        if (index >= 0 && index < waveData.length && index % 2 == 0) { // Check if index is even
                          final timeOfDay = waveData[index]['timeofday'];
                          if (timeOfDay != null) {
                            return Text(getTimeString(int.parse(timeOfDay.split(':')[0])));
                          }
                        }
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
