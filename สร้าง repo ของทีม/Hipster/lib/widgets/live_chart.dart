import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveChart extends StatelessWidget {
  const LiveChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1B222C),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildChart()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Vitals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time stream from Firestore',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildLegend(const Color(0xFFFF4D4D), 'BPM'),
            const SizedBox(width: 16),
            _buildLegend(const Color(0xFF00E5FF), 'SpO₂'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: color,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('health_readings')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFFFF4D4D).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Connecting to stream...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.reversed.toList();
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No data yet',
              style: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          );
        }

        final bpmSpots = <FlSpot>[];
        final spo2Spots = <FlSpot>[];

        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          final bpm = (data['bpm'] as num?)?.toDouble() ?? 0;
          final spo2 = (data['spo2'] as num?)?.toDouble() ?? 0;
          bpmSpots.add(FlSpot(i.toDouble(), bpm));
          spo2Spots.add(FlSpot(i.toDouble(), spo2));
        }

        return LineChart(
          LineChartData(
            backgroundColor: Colors.transparent,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withOpacity(0.05),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: 20,
                  getTitlesWidget: (val, meta) => Text(
                    val.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF0E1116).withOpacity(0.9),
                tooltipBorder: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final color = spot.barIndex == 0
                        ? const Color(0xFFFF4D4D)
                        : const Color(0xFF00E5FF);
                    final label = spot.barIndex == 0 ? 'BPM' : 'SpO₂';
                    return LineTooltipItem(
                      '${spot.y.toInt()} $label',
                      TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            minY: 40,
            maxY: 140,
            lineBarsData: [
              _buildLine(bpmSpots, const Color(0xFFFF4D4D)),
              _buildLine(spo2Spots, const Color(0xFF00E5FF)),
            ],
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.0),
          ],
        ),
      ),
      shadow: Shadow(
        color: color.withOpacity(0.4),
        blurRadius: 8,
      ),
    );
  }
}