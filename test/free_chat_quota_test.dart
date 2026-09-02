import 'package:flutter_test/flutter_test.dart';

/// Salinan murni dari logika kuota chat di CacheService, diuji terpisah supaya
/// tidak perlu menyalakan Hive/secure storage.
const int freeChatLimit = 3;

String currentQuotaPeriod(DateTime now) =>
    '${now.year}-${now.month.toString().padLeft(2, '0')}';

int effectiveCount(String? storedPeriod, int storedCount, DateTime now) =>
    storedPeriod != currentQuotaPeriod(now) ? 0 : storedCount;

DateTime nextReset(DateTime now) => now.month == 12
    ? DateTime(now.year + 1, 1, 1)
    : DateTime(now.year, now.month + 1, 1);

int remaining(String? period, int count, DateTime now) =>
    (freeChatLimit - effectiveCount(period, count, now)).clamp(0, freeChatLimit);

/// Cerminan refundFreeChatCount: tidak pernah turun di bawah nol, dan tidak
/// mengembalikan apa pun kalau periodenya sudah berganti.
int refund(String? period, int count, DateTime now) {
  final current = effectiveCount(period, count, now);
  return current <= 0 ? current : current - 1;
}

void main() {
  group('periode kuota', () {
    test('bulan satu digit dipad jadi dua digit', () {
      expect(currentQuotaPeriod(DateTime(2026, 3, 15)), '2026-03');
      expect(currentQuotaPeriod(DateTime(2026, 11, 1)), '2026-11');
    });

    test('kuota habis tetap habis di bulan yang sama', () {
      expect(remaining('2026-09', 3, DateTime(2026, 9, 30, 23, 59)), 0);
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

    test('counter melebihi batas tidak membuat sisa jadi negatif', () {
      expect(remaining('2026-09', 5, DateTime(2026, 9, 20)), 0);
    });
  });

  group('refund saat AI gagal menjawab', () {
    test('mengembalikan satu kuota di bulan berjalan', () {
      final now = DateTime(2026, 9, 20);
      expect(refund('2026-09', 3, now), 2);
      expect(remaining('2026-09', refund('2026-09', 3, now), now), 1);
    });

    test('tidak turun di bawah nol saat belum ada pemakaian', () {
      expect(refund('2026-09', 0, DateTime(2026, 9, 20)), 0);
    });

    test('tidak mengembalikan apa pun kalau periodenya sudah berganti', () {
      expect(refund('2026-08', 3, DateTime(2026, 9, 1)), 0);
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
