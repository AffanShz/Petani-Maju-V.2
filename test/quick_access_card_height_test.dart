import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani_maju/features/home/widgets/quick_access_item.dart';

/// Cerminan perhitungan tinggi di QuickAccess: bagian berukuran tetap
/// (ikon 44 + jarak 16 + padding kartu 32 + garis tepi 1px atas & bawah)
/// ditambah tinggi teks yang diukur.
const double _cardBorder = 1;
const double _fixedChrome = 44 + 16 + 32 + _cardBorder * 2;

const _titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
const _subtitleStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);

double _measure(String text, TextStyle style, double maxWidth, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 2,
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout(maxWidth: maxWidth);
  return painter.height;
}

/// Isi ketiga kartu yang sebenarnya. 'Obat Tanaman' adalah yang terpanjang dan
/// yang meluber 14px sebelum tingginya diukur, bukan ditaksir.
const _entries = <List<String>>[
  ['Info Cuaca', 'Prakiraan 7 hari'],
  ['Hama & Penyakit', 'Penyakit tanaman'],
  ['Obat Tanaman', 'Pencegahan & resep'],
];

double _uniformHeight(double itemWidth, TextScaler scaler) {
  final contentWidth = itemWidth - 32 - _cardBorder * 2;
  var tallest = 0.0;
  for (final e in _entries) {
    final h = _measure(e[0], _titleStyle, contentWidth, scaler) +
        _measure(e[1], _subtitleStyle, contentWidth, scaler);
    if (h > tallest) tallest = h;
  }
  return _fixedChrome + tallest;
}

void main() {
  // Lebar kartu pada layar 360dp: (360 - 48 - 12) / 2
  const itemWidth = 150.0;

  for (final factor in [1.0, 1.15, 1.3, 1.5, 1.8]) {
    testWidgets('kartu tidak meluber pada skala teks $factor',
        (WidgetTester tester) async {
      final scaler = TextScaler.linear(factor);
      final height = _uniformHeight(itemWidth, scaler);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: scaler),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final e in _entries)
                    SizedBox(
                      width: itemWidth,
                      height: height,
                      child: QuickAccessItem(
                        icon: Icons.healing_outlined,
                        title: e[0],
                        subtitle: e[1],
                        iconColor: Colors.green,
                        backgroundColor: Colors.green.shade50,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      // Overflow apa pun dilaporkan sebagai FlutterError dan menggagalkan test.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ketiga kartu berakhir dengan tinggi yang sama',
      (WidgetTester tester) async {
    const scaler = TextScaler.linear(1.3);
    final height = _uniformHeight(itemWidth, scaler);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: scaler),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in _entries)
                  SizedBox(
                    width: itemWidth,
                    height: height,
                    child: QuickAccessItem(
                      icon: Icons.healing_outlined,
                      title: e[0],
                      subtitle: e[1],
                      iconColor: Colors.green,
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final sizes = tester
        .widgetList<QuickAccessItem>(find.byType(QuickAccessItem))
        .map((w) => tester.getSize(find.byWidget(w)).height)
        .toSet();

    expect(sizes.length, 1, reason: 'tinggi kartu harus seragam');
  });
}
