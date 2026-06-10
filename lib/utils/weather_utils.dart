class WeatherUtils {
  static String translateWeather(String description) {
    description = description.toLowerCase();
    if (description.contains('thunderstorm')) return 'Hujan Petir';
    if (description.contains('drizzle')) return 'Gerimis';
    if (description.contains('rain')) {
      if (description.contains('heavy')) return 'Hujan Deras';
      if (description.contains('light')) return 'Hujan Ringan';
      return 'Hujan';
    }
    if (description.contains('cloud')) return 'Berawan';
    if (description.contains('clear')) return 'Cerah';
    if (description.contains('mist') || description.contains('fog')) {
      return 'Berkabut';
    }
    return description;
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
