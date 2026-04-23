import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';
import 'package:monitoring_jamur/features/home/presentation/pages/statistics_page.dart';
import 'package:monitoring_jamur/core/services/mqtt_service.dart';
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Demo humidity value
  double _humidity = 1;
  bool _isAutoMode = true;
  bool _isPumpManual = false;
  bool _isLightManual = false;

  bool get _pumpStatus => _isAutoMode ? (_humidity < 80) : _isPumpManual;
  bool get _lightStatus => _isAutoMode ? (_humidity > 90) : _isLightManual;

  final MqttService _mqttService = MqttService();

  @override
  void initState() {
    super.initState();
    _mqttService.init();
    
    // Listen to all changes
    _mqttService.isConnected.addListener(_onMqttChanged);
    _mqttService.isHardwareOnline.addListener(_onMqttChanged);
    _mqttService.humidity.addListener(_onMqttChanged);
    _mqttService.relayStatus.addListener(_onMqttChanged);
    _mqttService.isAutoMode.addListener(_onMqttChanged);
    _mqttService.isPumpOn.addListener(_onMqttChanged);
    _mqttService.isLightOn.addListener(_onMqttChanged);
  }

  @override
  void dispose() {
    _mqttService.isConnected.removeListener(_onMqttChanged);
    _mqttService.isHardwareOnline.removeListener(_onMqttChanged);
    _mqttService.humidity.removeListener(_onMqttChanged);
    _mqttService.relayStatus.removeListener(_onMqttChanged);
    _mqttService.isAutoMode.removeListener(_onMqttChanged);
    _mqttService.isPumpOn.removeListener(_onMqttChanged);
    _mqttService.isLightOn.removeListener(_onMqttChanged);
    super.dispose();
  }

  void _onMqttChanged() {
    if (mounted) {
      setState(() {
        _humidity = _mqttService.humidity.value;
        _isAutoMode = _mqttService.isAutoMode.value;
        // In Auto mode, we follow the status reported by hardware
        // In Manual mode, we show what we set locally (which will be confirmed by hardware status later)
        if (_isAutoMode) {
          _isPumpManual = _mqttService.isPumpOn.value;
          _isLightManual = _mqttService.isLightOn.value;
        }
      });
    }
  }

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
    return ValueListenableBuilder<bool>(
      valueListenable: _mqttService.isAutoMode,
      builder: (context, isAuto, _) {
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
                  onTap: () => _mqttService.publishControl('mode', 'auto'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isAuto ? AppTheme.primaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Otomatis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAuto ? Colors.white : AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _mqttService.publishControl('mode', 'manual'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isAuto ? AppTheme.primaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Manual',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !isAuto ? Colors.white : AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceControls() {
    return ValueListenableBuilder<bool>(
      valueListenable: _mqttService.isAutoMode,
      builder: (context, isAuto, _) {
        return Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _mqttService.isPumpOn,
              builder: (context, isOn, _) {
                return _buildDeviceTile(
                  title: 'Pompa Air',
                  isOn: isOn,
                  onChanged: isAuto ? null : (val) {
                    _mqttService.publishControl('pump', val ? 'on' : 'off');
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: _mqttService.isLightOn,
              builder: (context, isOn, _) {
                return _buildDeviceTile(
                  title: 'Lampu Pemanas',
                  isOn: isOn,
                  onChanged: isAuto ? null : (val) {
                    _mqttService.publishControl('light', val ? 'on' : 'off');
                  },
                );
              },
            ),
          ],
        );
      },
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
      constraints: const BoxConstraints(minHeight: 104), // Fixed minimum height
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fixed size image container
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
          // Scroll-stable text column
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitor Jamur',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    height: 1.2, // Consistent leading
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<AppMqttStatus>(
                  valueListenable: _mqttService.connectionState,
                  builder: (context, state, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _mqttService.isHardwareOnline,
                      builder: (context, hwOnline, _) {
                        String statusText = "";
                        Color statusColor = Colors.red;
                        
                        if (state == AppMqttStatus.connecting) {
                          statusText = "Connecting to Broker...";
                          statusColor = Colors.orange;
                        } else if (state == AppMqttStatus.connected) {
                          if (hwOnline) {
                            statusText = "All Online ✅";
                            statusColor = AppTheme.primaryGreen;
                          } else {
                            statusText = "Broker OK (Hardware Offline)";
                            statusColor = Colors.blue;
                          }
                        } else if (state == AppMqttStatus.error) {
                          statusText = "Connection Error ❌";
                          statusColor = Colors.red;
                        } else {
                          statusText = "MQTT Offline";
                          statusColor = Colors.red;
                        }
                        
                        return SizedBox(
                          height: 20,
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // Fixed width icon slot
          Container(
            width: 32,
            alignment: Alignment.center,
            child: ValueListenableBuilder<AppMqttStatus>(
              valueListenable: _mqttService.connectionState,
              builder: (context, state, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _mqttService.isHardwareOnline,
                  builder: (context, hwOnline, _) {
                    IconData iconData = Icons.offline_bolt_rounded;
                    Color iconColor = Colors.red;
                    
                    if (state == AppMqttStatus.connecting) {
                      iconData = Icons.hourglass_empty_rounded;
                      iconColor = Colors.orange;
                    } else if (state == AppMqttStatus.connected) {
                      if (hwOnline) {
                        iconData = Icons.check_circle;
                        iconColor = AppTheme.primaryGreen;
                      } else {
                        iconData = Icons.wifi_tethering_rounded;
                        iconColor = Colors.blue;
                      }
                    }
                    
                    return Icon(
                      iconData,
                      color: iconColor,
                      size: 28,
                    );
                  },
                );
              },
            ),
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
