import 'package:flutter_test/flutter_test.dart';

/// Salinan murni dari logika kuota chat di CacheService, diuji terpisah supaya
/// tidak perlu menyalakan Hive/secure storage.
const int freeChatLimit = 3;

/// Penanda periode harian, 'YYYY-MM-DD'.
String currentQuotaPeriod(DateTime now) {
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

int effectiveCount(String? storedPeriod, int storedCount, DateTime now) =>
    storedPeriod != currentQuotaPeriod(now) ? 0 : storedCount;

/// Tengah malam berikutnya.
DateTime nextReset(DateTime now) =>
    DateTime(now.year, now.month, now.day + 1);

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
    test('bulan dan tanggal satu digit dipad jadi dua digit', () {
      expect(currentQuotaPeriod(DateTime(2026, 3, 5)), '2026-03-05');
      expect(currentQuotaPeriod(DateTime(2026, 11, 20)), '2026-11-20');
    });

    test('jam berapa pun pada hari yang sama menghasilkan periode sama', () {
      expect(currentQuotaPeriod(DateTime(2026, 9, 3, 0, 0)),
          currentQuotaPeriod(DateTime(2026, 9, 3, 23, 59, 59)));
    });

    test('lewat tengah malam periodenya berganti', () {
      expect(currentQuotaPeriod(DateTime(2026, 9, 3, 23, 59)),
          isNot(currentQuotaPeriod(DateTime(2026, 9, 4, 0, 1))));
    });
  });

  group('pemakaian', () {
    test('hitungan berjalan selama masih di hari yang sama', () {
      final now = DateTime(2026, 9, 3, 14);
      expect(effectiveCount('2026-09-03', 2, now), 2);
      expect(remaining('2026-09-03', 2, now), 1);
    });

    test('kuota habis setelah tiga jawaban', () {
      final now = DateTime(2026, 9, 3);
      expect(remaining('2026-09-03', 3, now), 0);
    });

    test('hitungan tidak pernah negatif walau tersimpan berlebih', () {
      expect(remaining('2026-09-03', 9, DateTime(2026, 9, 3)), 0);
    });

    test('ganti hari mengembalikan kuota penuh tanpa menunggu timer', () {
      // Inti perubahannya: kuota yang habis kemarin tersedia lagi hari ini.
      final besok = DateTime(2026, 9, 4, 0, 5);
      expect(effectiveCount('2026-09-03', 3, besok), 0);
      expect(remaining('2026-09-03', 3, besok), freeChatLimit);
    });

    test('belum pernah dipakai berarti kuota penuh', () {
      expect(remaining(null, 0, DateTime(2026, 9, 3)), freeChatLimit);
    });
  });

  group('refund saat AI gagal menjawab', () {
    test('mengembalikan satu kuota', () {
      expect(refund('2026-09-03', 2, DateTime(2026, 9, 3)), 1);
    });

    test('tidak turun di bawah nol', () {
      expect(refund('2026-09-03', 0, DateTime(2026, 9, 3)), 0);
    });

    test('tidak mengembalikan apa pun kalau harinya sudah berganti', () {
      expect(refund('2026-09-03', 3, DateTime(2026, 9, 4)), 0);
    });
  });

  group('tanggal reset berikutnya', () {
    test('hari biasa maju satu hari', () {
      expect(nextReset(DateTime(2026, 9, 3, 14)), DateTime(2026, 9, 4));
    });

    test('akhir bulan berguling ke bulan berikutnya', () {
      expect(nextReset(DateTime(2026, 9, 30, 23)), DateTime(2026, 10, 1));
    });

    test('31 Desember berguling ke tahun berikutnya', () {
      expect(nextReset(DateTime(2026, 12, 31, 23, 59)), DateTime(2027, 1, 1));
    });

    test('28 Februari tahun kabisat maju ke 29, bukan 1 Maret', () {
      expect(nextReset(DateTime(2028, 2, 28)), DateTime(2028, 2, 29));
    });

    test('29 Februari tahun kabisat maju ke 1 Maret', () {
      expect(nextReset(DateTime(2028, 2, 29)), DateTime(2028, 3, 1));
    });

    test('reset selalu di masa depan dan kurang dari 24 jam lagi', () {
      final now = DateTime(2026, 9, 3, 23, 30);
      final reset = nextReset(now);
      expect(reset.isAfter(now), isTrue);
      expect(reset.difference(now).inHours, lessThan(24));
    });
  });
}
