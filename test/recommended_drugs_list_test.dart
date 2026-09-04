import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani_maju/features/chatbot/widgets/recommended_drugs_list.dart';

/// Isi khas jawaban chatbot: nama obat panjang, kategori, bahan aktif.
const _drugs = <Map<String, dynamic>>[
  {
    'nama_obat': 'Antracol 70 WP',
    'kategori': 'Fungisida',
    'bahan_aktif': 'Propineb 70%',
  },
  {
    'nama_obat': 'Amistar Top 325 SC Sistemik',
    'kategori': 'Fungisida Sistemik',
    'bahan_aktif': 'Azoksistrobin 200 g/l + Difenokonazol 125 g/l',
  },
];

/// Lebar gelembung chat pada layar 360dp, sudah dikurangi padding percakapan.
const double _bubbleWidth = 270;

Future<void> _pump(WidgetTester tester, TextScaler scaler,
    {List<Map<String, dynamic>> drugs = _drugs}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(textScaler: scaler),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _bubbleWidth,
              child: RecommendedDrugsList(drugs: drugs),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final factor in [1.0, 1.15, 1.3, 1.5, 1.8, 2.0]) {
    testWidgets('tidak meluber pada skala teks $factor', (tester) async {
      await _pump(tester, TextScaler.linear(factor));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('baris judul tetap di dalam lebar gelembung', (tester) async {
    // Ini yang meluber 55px: judul dan tautan katalog sama-sama tidak
    // dibatasi lebarnya di dalam Row berpola spaceBetween.
    await _pump(tester, const TextScaler.linear(1.5));

    final header = tester.getSize(find.text('Rekomendasi Produk Obat:'));
    final link = tester.getSize(find.text('Katalog Lengkap'));

    expect(header.width + link.width, lessThanOrEqualTo(_bubbleWidth));
  });

  testWidgets('semua kartu setinggi kartu tertinggi', (tester) async {
    await _pump(tester, const TextScaler.linear(1.3));

    // Tiap kartu dibungkus GestureDetector agar bisa dibuka; chip kategori
    // di dalamnya juga sebuah Container, jadi jangan pakai Container sebagai
    // penanda kartu.
    final cards = find.descendant(
      of: find.byType(IntrinsicHeight),
      matching: find.byType(GestureDetector),
    );

    expect(tester.widgetList(cards).length, _drugs.length);

    final heights = tester
        .widgetList<GestureDetector>(cards)
        .map((c) => tester.getSize(find.byWidget(c)).height)
        .toSet();

    expect(heights.length, 1, reason: 'tinggi kartu obat harus seragam');
  });

  testWidgets('daftar tumbuh mengikuti skala teks, tidak terkunci 145',
      (tester) async {
    await _pump(tester, const TextScaler.linear(1.0));
    final small = tester.getSize(find.byType(IntrinsicHeight)).height;

    await _pump(tester, const TextScaler.linear(1.8));
    final large = tester.getSize(find.byType(IntrinsicHeight)).height;

    expect(large, greaterThan(small));
  });

  testWidgets('satu obat saja tetap dirender', (tester) async {
    await _pump(tester, const TextScaler.linear(1.3), drugs: [_drugs.first]);
    expect(find.text('Antracol 70 WP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
