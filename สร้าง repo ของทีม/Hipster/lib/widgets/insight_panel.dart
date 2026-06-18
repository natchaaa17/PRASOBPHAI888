import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsightPanel extends StatelessWidget {
  const InsightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('health_readings')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final readings = docs.map((d) => d.data() as Map<String, dynamic>).toList();

        final bpmValues = readings
            .map((r) => (r['bpm'] as num?)?.toDouble() ?? 0)
            .where((v) => v > 0)
            .toList();
        final spo2Values = readings
            .map((r) => (r['spo2'] as num?)?.toDouble() ?? 0)
            .where((v) => v > 0)
            .toList();

        final avgBpm = bpmValues.isEmpty
            ? null
            : bpmValues.reduce((a, b) => a + b) / bpmValues.length;
        final avgSpo2 = spo2Values.isEmpty
            ? null
            : spo2Values.reduce((a, b) => a + b) / spo2Values.length;
        final maxBpm =
            bpmValues.isEmpty ? null : bpmValues.reduce((a, b) => a > b ? a : b);
        final minSpo2 = spo2Values.isEmpty
            ? null
            : spo2Values.reduce((a, b) => a < b ? a : b);

        return Container(
          width: 260,
          decoration: BoxDecoration(
            color: const Color(0xFF111720),
            border: Border(
              left: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Analytics'),
              const SizedBox(height: 16),
              _buildInsightCard(
                label: 'Avg Heart Rate',
                value: avgBpm != null ? '${avgBpm.toInt()}' : '--',
                unit: 'bpm',
                color: const Color(0xFFFF4D4D),
                icon: Icons.favorite_rounded,
                sparkData: bpmValues.reversed.take(20).toList(),
                subtitle: '24h window',
              ),
              const SizedBox(height: 12),
              _buildInsightCard(
                label: 'Avg Blood Oxygen',
                value: avgSpo2 != null ? '${avgSpo2.toStringAsFixed(1)}' : '--',
                unit: '%',
                color: const Color(0xFF00E5FF),
                icon: Icons.water_drop_rounded,
                sparkData: spo2Values.reversed.take(20).toList(),
                subtitle: '24h window',
              ),
              const SizedBox(height: 12),
              _buildInsightCard(
                label: 'Peak Heart Rate',
                value: maxBpm != null ? '${maxBpm.toInt()}' : '--',
                unit: 'bpm',
                color: const Color(0xFFFFAB00),
                icon: Icons.trending_up_rounded,
                sparkData: bpmValues.reversed.take(20).toList(),
                subtitle: 'All-time max',
              ),
              const SizedBox(height: 12),
              _buildInsightCard(
                label: 'Min Blood Oxygen',
                value: minSpo2 != null ? '${minSpo2.toInt()}' : '--',
                unit: '%',
                color: minSpo2 != null && minSpo2 < 95
                    ? const Color(0xFFFF4D4D)
                    : const Color(0xFF00C853),
                icon: Icons.warning_amber_rounded,
                sparkData: spo2Values.reversed.take(20).toList(),
                subtitle: 'Lowest recorded',
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Health Score'),
              const SizedBox(height: 12),
              _buildHealthScore(avgBpm, avgSpo2),
              const SizedBox(height: 24),
              _buildSectionTitle('Summary'),
              const SizedBox(height: 12),
              _buildSummaryItem(
                'Total Readings',
                '${readings.length}',
                Icons.data_usage_rounded,
                const Color(0xFF7B61FF),
              ),
              const SizedBox(height: 8),
              _buildSummaryItem(
                'Data Source',
                'Firestore',
                Icons.cloud_rounded,
                const Color(0xFF00C853),
              ),
              const SizedBox(height: 8),
              _buildSummaryItem(
                'Update Rate',
                'Real-time',
                Icons.bolt_rounded,
                const Color(0xFFFFAB00),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInsightCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
    required List<double> sparkData,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF1B222C),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: ' $unit',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (sparkData.length > 2)
                SizedBox(
                  width: 60,
                  height: 30,
                  child: _buildSparkline(sparkData, color),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline(List<double> data, Color color) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore(double? avgBpm, double? avgSpo2) {
    int score = 100;
    if (avgBpm != null) {
      if (avgBpm > 100 || avgBpm < 60) score -= 20;
      if (avgBpm > 120 || avgBpm < 50) score -= 20;
    }
    if (avgSpo2 != null) {
      if (avgSpo2 < 95) score -= 20;
      if (avgSpo2 < 90) score -= 20;
    }
    score = score.clamp(0, 100);

    final scoreColor = score >= 80
        ? const Color(0xFF00C853)
        : score >= 60
            ? const Color(0xFFFFAB00)
            : const Color(0xFFFF4D4D);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF1B222C),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vitals Health Score',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                ),
              ),
              Text(
                '$score / 100',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation(scoreColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}