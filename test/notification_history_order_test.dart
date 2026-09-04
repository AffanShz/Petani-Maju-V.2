import 'package:flutter_test/flutter_test.dart';

/// Cerminan CacheService.getNotificationHistory: entri yang waktunya belum
/// tiba disaring, sisanya diurutkan menurun berdasarkan 'timestamp'.
List<Map<String, dynamic>> history(
  List<Map<String, dynamic>> raw,
  DateTime now,
) {
  final entries = raw
      .asMap()
      .entries
      .map((e) => (seq: e.key, data: Map<String, dynamic>.from(e.value)))
      .where((e) {
        final t = DateTime.tryParse(e.data['timestamp'] ?? '');
        return t != null && !t.isAfter(now);
      })
      .toList();

  entries.sort((a, b) {
    final tA = DateTime.parse(a.data['timestamp']);
    final tB = DateTime.parse(b.data['timestamp']);
    final byTime = tB.compareTo(tA);
    if (byTime != 0) return byTime;

    final cA = DateTime.tryParse(a.data['createdAt'] ?? '');
    final cB = DateTime.tryParse(b.data['createdAt'] ?? '');
    if (cA != null && cB != null) return cB.compareTo(cA);

    return b.seq.compareTo(a.seq);
  });

  return entries.map((e) => e.data).toList();
}

Map<String, dynamic> n(String title, String timestamp, {String? createdAt}) => {
      'title': title,
      'timestamp': timestamp,
      if (createdAt != null) 'createdAt': createdAt,
    };

List<String> titles(List<Map<String, dynamic>> l) =>
    l.map((e) => e['title'] as String).toList();

void main() {
  final now = DateTime(2026, 9, 3, 2, 9);

  test('hanya yang sudah tayang yang tampil', () {
    final out = history([
      n('jadwal 13 jam lagi', '2026-09-03T15:09:00'),
      n('info tanaman', '2026-09-03T02:06:00'),
      n('jadwal 2 jam lagi', '2026-09-03T04:09:00'),
      n('waspada jamur', '2026-09-02T22:09:00'),
    ], now);

    expect(titles(out), ['info tanaman', 'waspada jamur']);
  });

  test('urut menurun sesuai waktu yang tampil di layar', () {
    final out = history([
      n('4 jam lalu', '2026-09-02T22:09:00'),
      n('3 menit lalu', '2026-09-03T02:06:00'),
      n('9 jam lalu', '2026-09-02T17:09:00'),
    ], now);

    expect(titles(out), ['3 menit lalu', '4 jam lalu', '9 jam lalu']);
  });

  test('entri lama tanpa createdAt tetap ikut terurut menurut waktunya', () {
    // Inilah yang bikin daftarnya tampak acak sebelumnya: entri warisan
    // jatuh ke urutan penyimpanan, yang tidak ada hubungannya dengan waktu.
    final out = history([
      n('warisan lama', '2026-09-01T08:00:00'),
      n('baru', '2026-09-03T01:00:00', createdAt: '2026-09-03T01:00:00'),
      n('warisan agak baru', '2026-09-03T02:00:00'),
    ], now);

    expect(titles(out), ['warisan agak baru', 'baru', 'warisan lama']);
  });

  test('waktu kembar dipecah createdAt, yang terbaru dicatat lebih dulu', () {
    final out = history([
      n('dicatat duluan', '2026-09-03T01:00:00',
          createdAt: '2026-09-03T01:00:00'),
      n('dicatat belakangan', '2026-09-03T01:00:00',
          createdAt: '2026-09-03T01:30:00'),
    ], now);

    expect(titles(out).first, 'dicatat belakangan');
  });

  test('entri tepat pada detik ini dianggap sudah tayang', () {
    final out = history([n('pas sekarang', now.toIso8601String())], now);
    expect(titles(out), ['pas sekarang']);
  });

  test('timestamp rusak dibuang, tidak menggagalkan pengurutan', () {
    final out = history([
      n('rusak', 'bukan-tanggal'),
      n('sah', '2026-09-03T01:00:00'),
    ], now);

    expect(titles(out), ['sah']);
  });

  test('semuanya masih terjadwal menghasilkan daftar kosong', () {
    final out = history([n('nanti', '2026-09-04T08:00:00')], now);
    expect(out, isEmpty);
  });
}
