import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Normal', 'High BPM', 'Low BPM', 'Low SpO₂'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(),
                const SizedBox(height: 24),
                _buildTable(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1116),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• health_readings collection',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: _filters.map((f) {
        final isSelected = _filter == f;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected
                    ? const Color(0xFFFF4D4D).withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF4D4D).withOpacity(0.4)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFFF4D4D)
                      : Colors.white.withOpacity(0.45),
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('health_readings')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final readings =
            docs.map((d) => d.data() as Map<String, dynamic>).toList();

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
        final maxBpm = bpmValues.isEmpty
            ? null
            : bpmValues.reduce((a, b) => a > b ? a : b);
        final minBpm = bpmValues.isEmpty
            ? null
            : bpmValues.reduce((a, b) => a < b ? a : b);

        return Row(
          children: [
            Expanded(
                child: _statCard('Total Records', '${readings.length}',
                    Icons.storage_rounded, const Color(0xFF7B61FF))),
            const SizedBox(width: 16),
            Expanded(
                child: _statCard(
                    'Avg BPM',
                    avgBpm != null ? '${avgBpm.toInt()}' : '--',
                    Icons.favorite_rounded,
                    const Color(0xFFFF4D4D))),
            const SizedBox(width: 16),
            Expanded(
                child: _statCard(
                    'Avg SpO₂',
                    avgSpo2 != null ? '${avgSpo2.toStringAsFixed(1)}%' : '--',
                    Icons.water_drop_rounded,
                    const Color(0xFF00E5FF))),
            const SizedBox(width: 16),
            Expanded(
                child: _statCard(
                    'BPM Range',
                    maxBpm != null && minBpm != null
                        ? '${minBpm.toInt()}–${maxBpm.toInt()}'
                        : '--',
                    Icons.bar_chart_rounded,
                    const Color(0xFFFFAB00))),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1B222C),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('health_readings')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(
              color: Color(0xFFFF4D4D),
              strokeWidth: 2,
            ),
          ),
        );
      }

      final docs = snapshot.data!.docs;

      // 🔥 STEP 1: filter status == 2 (hardware gate)
      final rawRows = docs.map((d) {
        final data = d.data() as Map<String, dynamic>;

        final status = data['status'];

        if (status != 2) return null; // ❌ drop invalid data

        return {
          ...data,
          '_status': _computeStatus(
            data['bpm'] as int?,
            data['spo2'] as int?,
          ),
        };
      }).where((e) => e != null).toList();

      final rows = rawRows.cast<Map<String, dynamic>>();

      // 🔥 STEP 2: UI filter (เดิมของนาย)
      final filtered = _filter == 'All'
          ? rows
          : rows.where((r) => r['_status'] == _filter).toList();

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1B222C),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _tableHeader(),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Text(
                    'No records matching "$_filter"',
                    style: TextStyle(color: Colors.white.withOpacity(0.2)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _HistoryRow(data: filtered[i], index: i),
                ),
            ],
          ),
        ),
      );
    },
  );
}

  String _computeStatus(int? bpm, int? spo2) {
    if (bpm != null && bpm > 120) return 'High BPM';
    if (bpm != null && bpm < 50) return 'Low BPM';
    if (spo2 != null && spo2 < 95) return 'Low SpO₂';
    return 'Normal';
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: _hCell('#')),
          Expanded(flex: 3, child: _hCell('TIMESTAMP')),
          Expanded(flex: 2, child: _hCell('BPM')),
          Expanded(flex: 2, child: _hCell('SPO₂')),
          Expanded(flex: 2, child: _hCell('STATUS')),
        ],
      ),
    );
  }

  Widget _hCell(String t) => Text(
        t,
        style: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _HistoryRow extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  const _HistoryRow({required this.data, required this.index});

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _isHovered = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'Normal':
        return const Color(0xFF00C853);
      case 'High BPM':
        return const Color(0xFFFF4D4D);
      case 'Low BPM':
        return const Color(0xFFFFAB00);
      case 'Low SpO₂':
        return const Color(0xFFFFAB00);
      default:
        return Colors.grey;
    }
  }

 String _formatFull(dynamic timestamp) {
  if (timestamp == null) return '--';

  try {
    // กรณี Firestore Timestamp
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return _formatDate(dt);
    }

    // กรณี ESP32 ส่งมาเป็น String
    if (timestamp is String) {
      return timestamp; // หรือจะ parse เพิ่มก็ได้
    }

    return '--';
  } catch (_) {
    return '--';
  }
}

String _formatDate(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}

  @override
  Widget build(BuildContext context) {
    final bpm = widget.data['bpm'] as int?;
    final spo2 = widget.data['spo2'] as int?;
    final status = widget.data['_status'] as String? ?? 'Normal';
    final sc = _statusColor(status);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withOpacity(0.04)
              : widget.index.isEven
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.01),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.04), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _formatFull(widget.data['timestamp']),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      color: const Color(0xFFFF4D4D).withOpacity(0.5), size: 12),
                  const SizedBox(width: 6),
                  Text(
                    bpm?.toString() ?? '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                spo2 != null ? '$spo2%' : '--',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sc.withOpacity(0.1),
                    border: Border.all(color: sc.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: sc,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}