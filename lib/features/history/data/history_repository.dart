import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monitoring_jamur/features/history/data/models/humidity_record.dart';

class HistoryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<HumidityRecord>> fetchHistory() async {
    try {
      final response = await _supabase
          .from('humidity')
          .select()
          .order('id', ascending: false);

      return (response as List)
          .map((json) => HumidityRecord.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  Future<bool> deleteHistoryRecord(int id) async {
    try {
      await _supabase.from('humidity').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting record: $e');
      return false;
    }
  }

  Future<bool> saveHumidityData({
    required double humidity,
    required String status,
    required String lightStatus,
    required String pumpStatus,
  }) async {
    try {
      await _supabase.from('humidity').insert({
        'kelembapan': humidity,
        'status': status,
        'status_lampu': lightStatus,
        'status_pompa': pumpStatus,
        'tanggal_upload': DateFormat('HH:mm:ss').format(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error saving humidity data: $e');
      return false;
    }
  }
}
