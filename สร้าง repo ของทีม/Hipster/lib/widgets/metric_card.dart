import 'package:flutter/material.dart';
import 'dart:math' as math;

enum MetricType { heartRate, spo2, system }

class MetricCard extends StatefulWidget {
  final MetricType type;
  final int? value;
  final bool isConnected;

  const MetricCard({
    super.key,
    required this.type,
    this.value,
    this.isConnected = false,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _blinkController;
  late Animation<double> _pulseAnim;
  late Animation<double> _blinkAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  String get _status {
    if (widget.type == MetricType.heartRate) {
      final v = widget.value ?? 0;
      if (v > 120) return 'High';
      if (v < 50) return 'Low';
      return 'Normal';
    }
    if (widget.type == MetricType.spo2) {
      final v = widget.value ?? 0;
      if (v < 90) return 'Critical';
      if (v < 95) return 'Low';
      return 'Normal';
    }
    return widget.isConnected ? 'Connected' : 'Offline';
  }

  Color get _statusColor {
    switch (_status) {
      case 'Normal':
      case 'Connected':
        return const Color(0xFF00C853);
      case 'High':
      case 'Critical':
        return const Color(0xFFFF4D4D);
      case 'Low':
        return const Color(0xFFFFAB00);
      default:
        return Colors.grey;
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case MetricType.heartRate:
        return const Color(0xFFFF4D4D);
      case MetricType.spo2:
        return const Color(0xFF00E5FF);
      case MetricType.system:
        return const Color(0xFF00C853);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1B222C),
          border: Border.all(
            color: _isHovered
                ? _accentColor.withOpacity(0.35)
                : Colors.white.withOpacity(0.07),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            if (_isHovered)
              BoxShadow(
                color: _accentColor.withOpacity(0.12),
                blurRadius: 28,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              _buildGlassOverlay(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.04),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIcon(),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 20),
        _buildValueDisplay(),
        const SizedBox(height: 8),
        _buildLabel(),
      ],
    );
  }

  Widget _buildIcon() {
    if (widget.type == MetricType.heartRate) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnim.value,
            child: Icon(Icons.favorite_rounded,
                color: const Color(0xFFFF4D4D), size: 26),
          );
        },
      );
    }

    if (widget.type == MetricType.spo2) {
      return _buildOxygenIcon();
    }

    return _buildSystemIcon();
  }

  Widget _buildOxygenIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00E5FF).withOpacity(0.12),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: const Center(
        child: Text(
          'O₂',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemIcon() {
    return AnimatedBuilder(
      animation: _blinkAnim,
      builder: (context, child) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00C853).withOpacity(0.12 * _blinkAnim.value),
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C853).withOpacity(_blinkAnim.value),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withOpacity(0.5 * _blinkAnim.value),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _statusColor.withOpacity(0.12),
        border: Border.all(color: _statusColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        _status,
        style: TextStyle(
          color: _statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildValueDisplay() {
    if (widget.type == MetricType.system) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Firebase',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Firestore',
            style: TextStyle(
              color: _accentColor,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          widget.value?.toString() ?? '--',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.type == MetricType.heartRate ? 'bpm' : '%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel() {
    final labels = {
      MetricType.heartRate: 'Heart Rate',
      MetricType.spo2: 'Blood Oxygen',
      MetricType.system: 'System Status',
    };

    return Text(
      labels[widget.type]!,
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      ),
    );
  }
}