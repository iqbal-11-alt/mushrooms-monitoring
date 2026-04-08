import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';
import 'package:monitoring_jamur/features/home/presentation/pages/statistics_page.dart';
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Demo humidity value
  double _humidity = 85.0;
  bool _isAutoMode = true;
  bool _isPumpManual = false;
  bool _isLightManual = false;

  bool get _pumpStatus => _isAutoMode ? (_humidity < 80) : _isPumpManual;
  bool get _lightStatus => _isAutoMode ? (_humidity > 90) : _isLightManual;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monitor Status',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              // Mushroom Monitor Sign Card
              _buildStatusCard(),
              const SizedBox(height: 48),
              // Consolidated Humidity Frame
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F8E8), // Light greenish/beige frame
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'KELEMBAPAN JAMUR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Cool Humidity Gauge
                    _HumidityGauge(
                      value: _humidity,
                      size: 200,
                    ),
                    const SizedBox(height: 32),
                    // Instruction Panel (Sign-style)
                    _InstructionPanel(humidity: _humidity),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Control Mode Selector
              _buildModeSelector(),
              const SizedBox(height: 24),
              // Device Controls
              _buildDeviceControls(),
              const SizedBox(height: 32),
              // Statistics Button
              _buildStatisticsButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAutoMode = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isAutoMode ? AppTheme.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Otomatis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isAutoMode ? Colors.white : AppTheme.textLight,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAutoMode = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isAutoMode ? AppTheme.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Manual',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_isAutoMode ? Colors.white : AppTheme.textLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceControls() {
    return Column(
      children: [
        _buildDeviceTile(
          title: 'Pompa Air',
          isOn: _pumpStatus,
          onChanged: _isAutoMode ? null : (val) => setState(() => _isPumpManual = val),
        ),
        const SizedBox(height: 16),
        _buildDeviceTile(
          title: 'Lampu Pemanas',
          isOn: _lightStatus,
          onChanged: _isAutoMode ? null : (val) => setState(() => _isLightManual = val),
        ),
      ],
    );
  }

  Widget _buildDeviceTile({
    required String title,
    required bool isOn,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOn ? AppTheme.primaryGreen.withAlpha(30) : Colors.grey.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              title.contains('Pompa') ? Icons.water_drop_rounded : Icons.lightbulb_rounded,
              color: isOn ? AppTheme.primaryGreen : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
          if (onChanged == null)
            Text(
              isOn ? 'MENYALA' : 'MATI',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isOn ? AppTheme.primaryGreen : AppTheme.textLight,
              ),
            )
          else
            Switch(
              value: isOn,
              onChanged: onChanged,
              activeColor: AppTheme.primaryGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatisticsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withAlpha(20),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen, size: 28),
            SizedBox(width: 12),
            Text(
              'Lihat Statistik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.backgroundBeige,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'lib/assets/mushroom.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monitor Jamur',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  'Active & Monitoring',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppTheme.primaryGreen,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _HumidityGauge extends StatelessWidget {
  final double value;
  final double size;

  const _HumidityGauge({required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              percentage: value / 100,
              primaryColor: AppTheme.primaryGreen,
              backgroundColor: AppTheme.backgroundBeige,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Text(
                'HUMIDITY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color primaryColor;
  final Color backgroundColor;

  _GaugePainter({
    required this.percentage,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 15;
    const strokeWidth = 18.0;

    // Background Circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Filter/Progress Arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withAlpha(100),
          primaryColor,
        ],
        stops: const [0.0, 1.0],
        startAngle: -math.pi / 2,
        endAngle: 2 * math.pi * percentage - math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _InstructionPanel extends StatelessWidget {
  final double humidity;

  const _InstructionPanel({required this.humidity});

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color color;
    String subMessage;

    if (humidity < 70) {
      message = 'Sangat Kering';
      subMessage = 'Tidak optimal untuk pertumbuhan aktif. Pompa menyala (penyiraman aktif)';
      icon = Icons.warning_amber_rounded;
      color = Colors.orange.shade800;
    } else if (humidity >= 70 && humidity < 80) {
      message = 'Kering - Lembab';
      subMessage = 'Mulai mendekati kondisi ideal. Pompa menyala (penyiraman terbatas)';
      icon = Icons.info_outline_rounded;
      color = Colors.blueGrey;
    } else if (humidity >= 80 && humidity <= 90) {
      message = 'Lembab (Ideal)';
      subMessage = 'Kondisi optimal pertumbuhan jamur tiram. Pompa mati';
      icon = Icons.check_circle_outline_rounded;
      color = AppTheme.primaryGreen;
    } else {
      message = 'Sangat Lembab';
      subMessage = 'Menyebabkan kontaminasi. Pompa mati';
      icon = Icons.error_outline_rounded;
      color = Colors.red.shade700;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
