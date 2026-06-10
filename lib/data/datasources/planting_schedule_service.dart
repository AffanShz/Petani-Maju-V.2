import 'package:hive_flutter/hive_flutter.dart';

class PlantingScheduleService {
  // Use the same box name as defined in CacheService
  static const String _boxName = 'plantingSchedule';

  Box get _box {
    if (!Hive.isBoxOpen(_boxName)) {
      throw Exception('Hive box $_boxName is not open');
    }
    return Hive.box(_boxName);
  }

  Future<List<Map<String, dynamic>>> fetchSchedules() async {
    try {
      // Use toMap() to get keys (IDs) and values
      final data = _box.toMap();

      final List<Map<String, dynamic>> schedules = data.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value);
        map['id'] = e.key; // Inject Hive key as ID
        return map;
      }).toList();

      schedules.sort((a, b) {
        final dateA = DateTime.parse(a['tanggal_tanam']);
        final dateB = DateTime.parse(b['tanggal_tanam']);
        return dateA.compareTo(dateB);
      });

      return schedules;
    } catch (e) {
      throw Exception('Gagal mengambil jadwal lokal: $e');
    }
  }

  Future<int> addSchedule({
    required String namaTanaman,
    required DateTime tanggalTanam,
    String? catatan,
  }) async {
    try {
      final schedule = {
        'nama_tanaman': namaTanaman,
        'tanggal_tanam': tanggalTanam.toIso8601String(),
        'catatan': catatan,
      };
      // Use Hive's auto-increment key
      final id = await _box.add(schedule);
      return id;
    } catch (e) {
      throw Exception('Gagal menambahkan jadwal lokal: $e');
    }
  }

  Future<void> updateSchedule({
    required int id,
    required String namaTanaman,
    required DateTime tanggalTanam,
    String? catatan,
  }) async {
    try {
      final schedule = {
        'nama_tanaman': namaTanaman,
        'tanggal_tanam': tanggalTanam.toIso8601String(),
        'catatan': catatan,
      };
      await _box.put(id, schedule);
    } catch (e) {
      throw Exception('Gagal mengupdate jadwal lokal: $e');
    }
  }

  Future<void> deleteSchedule(int id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw Exception('Gagal menghapus jadwal lokal: $e');
    }
  }
}
