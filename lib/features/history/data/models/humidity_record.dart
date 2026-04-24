import 'package:intl/intl.dart';

class HumidityRecord {
  final int id;
  final double humidity;
  final String status;
  final DateTime uploadDate;
  final String lightStatus;
  final String pumpStatus;

  HumidityRecord({
    required this.id,
    required this.humidity,
    required this.status,
    required this.uploadDate,
    required this.lightStatus,
    required this.pumpStatus,
  });

  factory HumidityRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final String rawDate = json['tanggal_upload'] as String;

    try {
      // Try parsing as full ISO8601
      parsedDate = DateTime.parse(rawDate).toLocal();
    } catch (_) {
      // Handle "HH:mm:ss" format from 'time' column
      final now = DateTime.now();
      final parts = rawDate.split(':');
      parsedDate = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2].split('.')[0]) : 0,
      );
    }

    return HumidityRecord(
      id: json['id'] as int,
      humidity: (json['kelembapan'] as num).toDouble(),
      status: json['status'] as String,
      uploadDate: parsedDate,
      lightStatus: json['status_lampu'] as String,
      pumpStatus: json['status_pompa'] as String,
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy, HH:mm').format(uploadDate);
}
