import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: const Text('Statistik Monitoring'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(),
            const SizedBox(height: 32),
            _buildChartSection('Tren Kelembapan', [85, 82, 88, 84, 86, 85, 87], AppTheme.primaryGreen),
            const SizedBox(height: 32),
            _buildChartSection('Tren Suhu', [24, 25, 24, 26, 25, 24, 25], Colors.orange),
            const SizedBox(height: 40),
            _buildAnalysisCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        _buildStatCard('Rata-rata', '85%', Icons.water_drop_rounded, AppTheme.primaryGreen),
        const SizedBox(width: 16),
        _buildStatCard('Tertinggi', '89%', Icons.trending_up_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, List<double> values, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.map((v) {
              double height = (v / 100) * 120;
              if (title.contains('Suhu')) height = (v / 40) * 120; // Scale for temperature
              return Container(
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 2),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withAlpha(20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withAlpha(50), width: 2),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryGreen),
              SizedBox(width: 12),
              Text(
                'Analisis Sistem',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Berdasarkan data 24 jam terakhir, kelembapan stabil di rentang ideal (80-90%). Pertumbuhan jamur terpantau optimal.',
            style: TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.5),
          ),
        ],
      ),
    );
  }
}
