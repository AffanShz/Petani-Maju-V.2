import 'package:flutter_test/flutter_test.dart';

/// Cerminan pengurutan di CacheService.getNotificationHistory.
///
/// 'seq' adalah urutan penyimpanan di Hive; 'createdAt' kapan entri dicatat;
/// 'timestamp' kapan notifikasi berbunyi (bisa di masa depan untuk jadwal).
List<Map<String, dynamic>> sortHistory(List<Map<String, dynamic>> raw) {
  final entries = raw
      .asMap()
      .entries
      .map((e) => (seq: e.key, data: Map<String, dynamic>.from(e.value)))
      .toList();

  entries.sort((a, b) {
    final cA = DateTime.tryParse(a.data['createdAt'] ?? '');
    final cB = DateTime.tryParse(b.data['createdAt'] ?? '');
    if (cA != null && cB != null) return cB.compareTo(cA);
    if (cA != null) return -1;
    if (cB != null) return 1;
    return b.seq.compareTo(a.seq);
  });

  return entries.map((e) => e.data).toList();
}

Map<String, dynamic> entry(String title,
        {String? createdAt, required String timestamp}) =>
    {
      'title': title,
      'timestamp': timestamp,
      if (createdAt != null) 'createdAt': createdAt,
    };

List<String> titles(List<Map<String, dynamic>> l) =>
    l.map((e) => e['title'] as String).toList();

void main() {
  test('yang paling baru dicatat berada di atas', () {
    final sorted = sortHistory([
      entry('lama', createdAt: '2026-09-01T08:00:00', timestamp: '2026-09-01T08:00:00'),
      entry('terbaru', createdAt: '2026-09-03T10:00:00', timestamp: '2026-09-03T10:00:00'),
      entry('tengah', createdAt: '2026-09-02T09:00:00', timestamp: '2026-09-02T09:00:00'),
    ]);
    expect(titles(sorted), ['terbaru', 'tengah', 'lama']);
  });

  test('jadwal jauh di masa depan tidak lagi naik ke paling atas', () {
    // Inilah bug aslinya: diurutkan dengan 'timestamp', jadwal 15 hari ke
    // depan mengalahkan notifikasi yang baru saja tayang.
    final sorted = sortHistory([
      entry('baru tayang',
          createdAt: '2026-09-03T10:00:00', timestamp: '2026-09-03T10:00:00'),
      entry('jadwal jauh',
          createdAt: '2026-09-01T07:00:00', timestamp: '2026-09-18T16:00:00'),
    ]);
    expect(titles(sorted).first, 'baru tayang');
  });

  test('entri lama tanpa createdAt turun di bawah entri baru', () {
    final sorted = sortHistory([
      entry('warisan', timestamp: '2026-09-20T16:00:00'),
      entry('baru', createdAt: '2026-09-02T09:00:00', timestamp: '2026-09-02T09:00:00'),
    ]);
    expect(titles(sorted), ['baru', 'warisan']);
  });

  test('sesama entri lama memakai urutan penyimpanan terbalik', () {
    final sorted = sortHistory([
      entry('disimpan pertama', timestamp: '2026-09-20T16:00:00'),
      entry('disimpan kedua', timestamp: '2026-09-01T16:00:00'),
      entry('disimpan ketiga', timestamp: '2026-09-10T16:00:00'),
    ]);
    expect(titles(sorted),
        ['disimpan ketiga', 'disimpan kedua', 'disimpan pertama']);
  });

  test('daftar kosong tidak meledak', () {
    expect(sortHistory([]), isEmpty);
  });
}
