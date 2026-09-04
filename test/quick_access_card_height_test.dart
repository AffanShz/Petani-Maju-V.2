import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrinova/features/home/widgets/quick_access_item.dart';
import 'package:agrinova/features/home/widgets/quick_access_metrics.dart';

/// Isi ketiga kartu yang sebenarnya. 'Obat Tanaman' yang paling panjang, dan
/// itulah yang meluber sebelum pengukurannya ikut memperhitungkan tema.
const _entries = <QuickAccessText>[
  (title: 'Info Cuaca', subtitle: 'Prakiraan 7 hari'),
  (title: 'Hama & Penyakit', subtitle: 'Penyakit tanaman'),
  (title: 'Obat Tanaman', subtitle: 'Pencegahan & resep'),
];

/// Lebar kartu pada layar 360dp: (360 - 48 - 12) / 2
const double _itemWidth = 150;

/// Merender kartu memakai tinggi yang dihitung fungsi produksi.
///
/// Sengaja dibungkus MaterialApp dengan tema yang sama seperti aplikasi.
/// Versi test sebelumnya merender tanpa MaterialApp, sehingga DefaultTextStyle
/// dari Material 3 (height 1.43, letterSpacing) tidak ikut berlaku dan test
/// lolos walaupun di perangkat kartunya meluber 18px.
Future<void> _pumpCards(WidgetTester tester, TextScaler scaler) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: MediaQuery(
        data: MediaQueryData(textScaler: scaler),
        child: Scaffold(
          body: Builder(
            builder: (context) {
              final height =
                  quickAccessCardHeight(context, _entries, _itemWidth);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final e in _entries)
                    SizedBox(
                      width: _itemWidth,
                      height: height,
                      child: QuickAccessItem(
                        icon: Icons.healing_outlined,
                        title: e.title,
                        subtitle: e.subtitle,
                        iconColor: Colors.green,
                        backgroundColor: Colors.green.shade50,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final factor in [1.0, 1.15, 1.3, 1.5, 1.8, 2.0]) {
    testWidgets('kartu tidak meluber pada skala teks $factor',
        (WidgetTester tester) async {
      await _pumpCards(tester, TextScaler.linear(factor));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ketiga kartu berakhir dengan tinggi yang sama',
      (WidgetTester tester) async {
    await _pumpCards(tester, const TextScaler.linear(1.3));

    final heights = tester
        .widgetList<QuickAccessItem>(find.byType(QuickAccessItem))
        .map((w) => tester.getSize(find.byWidget(w)).height)
        .toSet();

    expect(heights.length, 1, reason: 'tinggi kartu harus seragam');
  });

  testWidgets('tinggi mengikuti tema, bukan metrik font telanjang',
      (WidgetTester tester) async {
    late double themed;
    late double bare;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              themed = quickAccessCardHeight(context, _entries, _itemWidth);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            bare = quickAccessCardHeight(context, _entries, _itemWidth);
            return const SizedBox();
          },
        ),
      ),
    );

    // Tema Material 3 memberi height 1.43, jauh di atas metrik font apa adanya.
    expect(themed, greaterThan(bare),
        reason: 'gaya tema harus ikut diperhitungkan saat mengukur');
  });

  testWidgets('teks kartu tidak terpotong oleh tinggi yang dihitung',
      (WidgetTester tester) async {
    // Jaring pengaman Flexible di QuickAccessItem menahan garis overflow, jadi
    // "tidak meluber" saja tidak membuktikan tingginya cukup: teks bisa
    // terpotong diam-diam. Di sini tiap teks dibandingkan dengan tinggi yang
    // sama saat dirender tanpa batas tinggi. Pembandingnya render sungguhan,
    // bukan TextPainter, supaya tidak ada selisih metrik antara cara mengukur
    // dan cara menggambar.
    const scaler = TextScaler.linear(1.3);

    await _pumpCards(tester, scaler);
    final inCard = <String, double>{
      for (final e in _entries) ...{
        e.title: tester.getSize(find.text(e.title).first).height,
        e.subtitle: tester.getSize(find.text(e.subtitle).first).height,
      }
    };

    for (final e in _entries) {
      for (final item in <(String, TextStyle)>[
        (e.title, quickAccessTitleStyle),
        (e.subtitle, quickAccessSubtitleStyle),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: scaler),
              child: Scaffold(
                body: SizedBox(
                  width: _itemWidth - 34, // lebar isi kartu
                  child: Text(
                    item.$1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: item.$2,
                  ),
                ),
              ),
            ),
          ),
        );

        final unconstrained = tester.getSize(find.text(item.$1)).height;

        expect(inCard[item.$1], unconstrained,
            reason: '"${item.$1}" terpotong di dalam kartu');
      }
    }
  });
}
