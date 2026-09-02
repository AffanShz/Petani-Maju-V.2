import 'package:flutter_test/flutter_test.dart';

/// Salinan murni dari logika periode kuota di CacheService, diuji terpisah
/// supaya tidak perlu menyalakan Hive/secure storage.
String currentUploadPeriod(DateTime now) =>
    '${now.year}-${now.month.toString().padLeft(2, '0')}';

int effectiveCount(String? storedPeriod, int storedCount, DateTime now) =>
    storedPeriod != currentUploadPeriod(now) ? 0 : storedCount;

DateTime nextReset(DateTime now) => now.month == 12
    ? DateTime(now.year + 1, 1, 1)
    : DateTime(now.year, now.month + 1, 1);

int remaining(String? period, int count, DateTime now) =>
    (3 - effectiveCount(period, count, now)).clamp(0, 3);

void main() {
  group('periode kuota', () {
    test('bulan satu digit dipad jadi dua digit', () {
      expect(currentUploadPeriod(DateTime(2026, 3, 15)), '2026-03');
      expect(currentUploadPeriod(DateTime(2026, 11, 1)), '2026-11');
    });

    test('kuota habis tetap habis di bulan yang sama', () {
      final now = DateTime(2026, 9, 30, 23, 59);
      expect(remaining('2026-09', 3, now), 0);
    });

    test('kuota terisi ulang saat ganti bulan', () {
      expect(remaining('2026-09', 3, DateTime(2026, 10, 1, 0, 0)), 3);
    });

    test('lintas tahun dianggap periode baru, bukan bulan yang sama', () {
      expect(remaining('2025-09', 3, DateTime(2026, 9, 1)), 3);
    });

    test('akun baru tanpa periode tersimpan dapat kuota penuh', () {
      expect(remaining(null, 0, DateTime(2026, 9, 2)), 3);
    });

    test('pemakaian sebagian tetap terhitung dalam bulan berjalan', () {
      expect(remaining('2026-09', 1, DateTime(2026, 9, 20)), 2);
    });
  });

  group('tanggal reset berikutnya', () {
    test('bulan biasa maju satu bulan', () {
      expect(nextReset(DateTime(2026, 9, 2)), DateTime(2026, 10, 1));
    });

    test('Desember berguling ke Januari tahun berikutnya', () {
      expect(nextReset(DateTime(2026, 12, 31)), DateTime(2027, 1, 1));
    });
  });
}
