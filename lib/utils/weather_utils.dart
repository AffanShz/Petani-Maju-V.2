class WeatherUtils {
  static String translateWeather(String description) {
    if (description.isEmpty) return description;
    final lower = description.toLowerCase();
    if (lower.contains('thunderstorm') || lower.contains('petir')) return 'Hujan Petir';
    if (lower.contains('drizzle') || lower.contains('gerimis')) return 'Gerimis';
    if (lower.contains('rain') || lower.contains('hujan')) {
      if (lower.contains('heavy') || lower.contains('deras')) return 'Hujan Deras';
      if (lower.contains('light') || lower.contains('ringan')) return 'Hujan Ringan';
      return 'Hujan';
    }
    if (lower.contains('cloud') || lower.contains('berawan') || lower.contains('awan')) return 'Berawan';
    if (lower.contains('clear') || lower.contains('cerah')) return 'Cerah';
    if (lower.contains('mist') || lower.contains('fog') || lower.contains('kabut')) return 'Berkabut';
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  static String? getRecommendation(int conditionId) {
    if (conditionId >= 200 && conditionId < 300) {
      return 'Potensi badai petir. Tunda pemupukan karena berisiko hanyut dan hindari area terbuka.';
    }

    if (conditionId >= 300 && conditionId < 400) {
      return 'Gerimis turun. Cek kelembapan tanah, mungkin tidak perlu disiram sore ini.';
    }

    if (conditionId >= 500 && conditionId < 600) {
      if (conditionId >= 502) {
        return 'Hujan deras terdeteksi! Segera buka saluran drainase agar lahan tidak tergenang.';
      }
      return 'Hujan turun. Hentikan penyiraman dan pemupukan sementara agar efisien.';
    }

    if (conditionId == 800) {
      return 'Cuaca cerah terik. Pastikan tanaman mendapat air yang cukup (siram pagi/sore).';
    }

    if (conditionId > 800) {
      return 'Cuaca berawan. Waktu yang tepat untuk pemupukan atau penyemprotan hama.';
    }

    return null; 
  }
}
