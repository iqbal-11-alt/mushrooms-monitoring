import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';
import 'package:monitoring_jamur/features/history/data/history_repository.dart';
import 'package:monitoring_jamur/features/history/data/models/humidity_record.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryRepository _repository = HistoryRepository();
  List<HumidityRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await _repository.fetchHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Histori Monitoring',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  onRefresh: _loadHistory,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen))
                      : _history.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _history.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) =>
                                  _buildHistoryCard(_history[index]),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppTheme.backgroundBeige,
            ),
            SizedBox(height: 16),
            Text(
              'tidak ada data',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Data?'),
        content:
            const Text('Apakah Anda yakin ingin menghapus data monitoring ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Batal', style: TextStyle(color: AppTheme.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _repository.deleteHistoryRecord(id);
      if (success && mounted) {
        _loadHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data berhasil dihapus'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(24),
          ),
        );
      }
    }
  }

  Widget _buildHistoryCard(HumidityRecord record) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECORD DATA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.backgroundBeige,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 22),
                onPressed: () => _confirmDelete(record.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Kelembapan', '${record.humidity.toInt()}%'),
          _buildInfoRow('Status', record.status),
          _buildInfoRow('Status Pompa', record.pumpStatus,
              valueColor: record.pumpStatus.contains('MENYALA')
                  ? AppTheme.primaryGreen
                  : Colors.red),
          _buildInfoRow('Status Lampu', record.lightStatus,
              valueColor: record.lightStatus.contains('MENYALA')
                  ? AppTheme.primaryGreen
                  : Colors.red),
          const Divider(height: 24, color: AppTheme.backgroundBeige),
          _buildInfoRow('Waktu', record.formattedDate, isSmall: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label :',
            style: TextStyle(
              fontSize: isSmall ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
