import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Salinan murni dari _formatTime di NotificationHistoryScreen, dengan `now`
/// disuntikkan supaya bisa diuji tanpa merender layar.
String formatTime(DateTime? dateTime, DateTime now) {
  if (dateTime == null) return '';

  if (dateTime.isAfter(now)) {
    final d = dateTime.difference(now);
    if (d.inMinutes < 1) return 'Sebentar lagi';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lagi';
    if (d.inHours < 24) return '${d.inHours} jam lagi';
    if (d.inDays < 7) return '${d.inDays} hari lagi';
    return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
  }

  final d = now.difference(dateTime);
  if (d.inMinutes < 1) return 'Baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  if (d.inDays == 1) return 'Kemarin';
  if (d.inDays < 7) return '${d.inDays} hari lalu';
  return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
}

void main() {
  final now = DateTime(2026, 9, 3, 12, 0);

  group('sudah lewat', () {
    test('di bawah semenit disebut baru saja', () {
      expect(formatTime(now.subtract(const Duration(seconds: 30)), now),
          'Baru saja');
    });

    test('naik ke menit lalu jam', () {
      expect(formatTime(now.subtract(const Duration(minutes: 45)), now),
          '45 menit lalu');
      expect(
          formatTime(now.subtract(const Duration(hours: 5)), now), '5 jam lalu');
    });

    test('tepat sehari disebut kemarin', () {
      expect(formatTime(now.subtract(const Duration(days: 1)), now), 'Kemarin');
    });

    test('lewat seminggu jatuh ke tanggal, bukan hitungan hari', () {
      expect(formatTime(DateTime(2026, 8, 20, 16, 0), now), '20 Aug 2026, 16:00');
    });
  });

  group('masih akan datang', () {
    test('jadwal 15 hari ke depan tidak lagi jadi menit negatif', () {
      final scheduled = now.add(const Duration(days: 15));
      final label = formatTime(scheduled, now);
      expect(label.contains('-'), isFalse);
      expect(label.contains('menit'), isFalse);
      expect(label, '18 Sep 2026, 12:00');
    });

    test('kurang dari sejam memakai kalimat lagi, bukan lalu', () {
      expect(formatTime(now.add(const Duration(minutes: 20)), now),
          '20 menit lagi');
    });

    test('hitungan jam dan hari untuk jadwal dekat', () {
      expect(formatTime(now.add(const Duration(hours: 14)), now), '14 jam lagi');
      expect(formatTime(now.add(const Duration(days: 3)), now), '3 hari lagi');
    });

    test('selisih di bawah semenit disebut sebentar lagi', () {
      expect(formatTime(now.add(const Duration(seconds: 20)), now),
          'Sebentar lagi');
    });
  });

  test('timestamp tidak terbaca menghasilkan string kosong', () {
    expect(formatTime(null, now), '');
  });
}
