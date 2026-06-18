import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/metric_card.dart';
import '../widgets/live_chart.dart';
import '../widgets/insight_panel.dart';
import '../widgets/side_menu.dart';
import 'history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedMenu = 0;
  bool _sidebarCollapsed = false;
  int? _latestBpm;
  int? _latestSpo2;
  bool _firebaseConnected = false;

  final List<Map<String, dynamic>> _tableData = [];
  bool _toastShown = false;

  int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('health_readings')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            _firebaseConnected = true;
            final latest = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            _latestBpm = _toInt(latest['bpm']);
            _latestSpo2 = _toInt(latest['spo2']);

            _tableData.clear();
            for (final doc in snapshot.data!.docs) {
              _tableData.add(doc.data() as Map<String, dynamic>);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAlerts(_latestBpm, _latestSpo2);
            });
          }

          return Row(
            children: [
              SideMenu(
                selectedIndex: _selectedMenu,
                onItemSelected: (i) => setState(() => _selectedMenu = i),
                isCollapsed: _sidebarCollapsed,
              ),
              Expanded(
                child: _buildMainContent(),
              ),
              if (_selectedMenu == 0) const InsightPanel(),
            ],
          );
        },
      ),
    );
  }

  void _checkAlerts(int? bpm, int? spo2) {
    if (_toastShown) return;
    String? message;
    Color? color;

    if (bpm != null && bpm > 120) {
      message = '⚠️ High Heart Rate: $bpm BPM — exceeds safe threshold';
      color = const Color(0xFFFF4D4D);
    } else if (bpm != null && bpm < 50) {
      message = '⚠️ Low Heart Rate: $bpm BPM — below safe threshold';
      color = const Color(0xFFFFAB00);
    }

    if (message != null && mounted) {
      _toastShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 5),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF1B222C),
              border: Border.all(color: color!.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onVisible: () {
            Future.delayed(const Duration(seconds: 6), () {
              _toastShown = false;
            });
          },
        ),
      );
    }
  }

  Widget _buildMainContent() {
    if (_selectedMenu == 1) {
      return const HistoryPage();
    }

    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricCards(),
                const SizedBox(height: 24),
                _buildChartSection(),
                const SizedBox(height: 24),
                _buildDataTable(),
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
          IconButton(
            onPressed: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            icon: Icon(
              _sidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
            splashRadius: 20,
          ),
          const SizedBox(width: 12),
          Text(
            _selectedMenu == 0 ? 'Dashboard' : 'Overview',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          _buildLiveIndicator(),
          const SizedBox(width: 16),
          _buildTimestamp(),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF00C853).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF00C853).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingDot(color: const Color(0xFF00C853)),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: const Color(0xFF00C853),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        final time =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        return Text(
          time,
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        );
      },
    );
  }

  Widget _buildMetricCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 32) / 3;
        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: MetricCard(
                type: MetricType.heartRate,
                value: _latestBpm,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: cardWidth,
              child: MetricCard(
                type: MetricType.spo2,
                value: _latestSpo2,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: cardWidth,
              child: MetricCard(
                type: MetricType.system,
                isConnected: _firebaseConnected,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartSection() {
    return SizedBox(
      height: 320,
      child: const LiveChart(),
    );
  }

  Widget _buildDataTable() {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Readings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last ${_tableData.length} records',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded,
                            color: Colors.white.withOpacity(0.4), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Latest first',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTableHeader(),
            if (_tableData.isEmpty)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Text(
                    'No readings yet',
                    style: TextStyle(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tableData.length,
                itemBuilder: (context, i) => _TableRow(
                  data: _tableData[i],
                  isEven: i.isEven,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _headerCell('TIME'),
          ),
          Expanded(
            flex: 2,
            child: _headerCell('BPM'),
          ),
          Expanded(
            flex: 2,
            child: _headerCell('SPO₂'),
          ),
          Expanded(
            flex: 2,
            child: _headerCell('STATUS'),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isEven;

  const _TableRow({required this.data, required this.isEven});

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _isHovered = false;

  String _getStatus(int? bpm, int? spo2) {
    if (bpm != null && bpm > 120) return 'High BPM';
    if (bpm != null && bpm < 50) return 'Low BPM';
    if (spo2 != null && spo2 < 90) return 'Critical';
    if (spo2 != null && spo2 < 95) return 'Low SpO₂';
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return const Color(0xFF00C853);
      case 'High BPM':
      case 'Critical':
        return const Color(0xFFFF4D4D);
      default:
        return const Color(0xFFFFAB00);
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '--:--:--';
    try {
      // รองรับ String timestamp จาก hardware "2024-01-01 12:30:00"
      if (timestamp is String) {
        final parts = timestamp.split(' ');
        if (parts.length == 2) return parts[1];
        return timestamp;
      }
      // รองรับ Firestore Timestamp
      final dt = (timestamp as Timestamp).toDate();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bpm = widget.data['bpm'] as int?;
    final spo2 = widget.data['spo2'] as int?;
    final status = _getStatus(bpm, spo2);
    final statusColor = _getStatusColor(status);
    final timeStr = _formatTime(widget.data['timestamp']);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withOpacity(0.04)
              : widget.isEven
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.01),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.04),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: Colors.white.withOpacity(0.2),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      color: const Color(0xFFFF4D4D).withOpacity(0.6),
                      size: 12),
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
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: statusColor.withOpacity(0.1),
                  border:
                      Border.all(color: statusColor.withOpacity(0.3), width: 1),
                ),
                constraints: const BoxConstraints(maxWidth: 90),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5 * _anim.value),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}