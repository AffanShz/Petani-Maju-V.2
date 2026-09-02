import 'package:flutter/material.dart';

/// Isi satu kartu akses cepat, sebatas yang mempengaruhi tinggi.
typedef QuickAccessText = ({String title, String subtitle});

/// Gaya teks kartu. Harus sama persis dengan yang dipakai QuickAccessItem.
const TextStyle quickAccessTitleStyle =
    TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
const TextStyle quickAccessSubtitleStyle =
    TextStyle(fontSize: 12, fontWeight: FontWeight.w400);

const int _maxLines = 2;

/// Garis tepi kartu, 1px. Mudah terlewat padahal memakan 2px tinggi dan
/// menyempitkan lebar isi sehingga teks turun baris lebih cepat.
const double _cardBorder = 1;

/// Bagian kartu yang tingginya tetap: ikon (padding 10*2 + ikon 24), jarak
/// antar elemen (12 + 4), padding kartu (16 atas + 16 bawah), dan garis tepi.
const double _fixedChrome = 44 + 16 + 32 + _cardBorder * 2;

/// Tinggi sebenarnya sebuah teks pada lebar dan skala font yang berlaku.
///
/// Gaya yang diukur harus digabung dulu dengan [DefaultTextStyle] milik
/// context. Widget Text menggabungkannya saat merender, dan tema Material 3
/// menyumbang `height` serta `letterSpacing` di sana. Mengukur dengan
/// TextStyle telanjang memakai metrik font apa adanya (sekitar 1.17) padahal
/// yang tampil memakai 1.43, sehingga tinggi kartu keluar terlalu pendek.
double _measure(
  BuildContext context,
  String text,
  TextStyle style,
  double maxWidth,
) {
  final effective = DefaultTextStyle.of(context).style.merge(style);

  final painter = TextPainter(
    text: TextSpan(text: text, style: effective),
    maxLines: _maxLines,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: maxWidth);

  return painter.height;
}

/// Tinggi seragam untuk semua kartu akses cepat: setinggi kartu yang isinya
/// paling panjang.
///
/// Wrap menghitung tinggi tiap anak sendiri-sendiri, jadi tanpa ini kartu
/// berjudul dua baris berdiri lebih jangkung dari yang satu baris.
double quickAccessCardHeight(
  BuildContext context,
  Iterable<QuickAccessText> entries,
  double itemWidth,
) {
  final contentWidth = itemWidth - 32 - _cardBorder * 2;
  var tallest = 0.0;

  for (final e in entries) {
    final h = _measure(context, e.title, quickAccessTitleStyle, contentWidth) +
        _measure(context, e.subtitle, quickAccessSubtitleStyle, contentWidth);
    if (h > tallest) tallest = h;
  }

  return _fixedChrome + tallest;
}
