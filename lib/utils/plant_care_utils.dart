class PlantCareUtils {
  static Map<String, dynamic> getPlantAdvice({
    required int weatherId,
    required double temperature,
    required double humidity,
    required double windSpeed,
  }) {
    String title = "Kondisi Normal";
    String advice = "Lakukan pemantauan rutin pada tanaman Anda.";
    String iconAsset = "assets/images/padi_tips.png"; 
    bool isUrgent = false;

    if (temperature > 32) {
      title = "Suhu Tinggi Terdeteksi";
      advice =
          "Tanaman rentan layu. Lakukan penyiraman ekstra di sore hari dan tunda pemupukan kimia.";
      isUrgent = true;
    }
    else if (weatherId >= 500 && weatherId < 600) {
      title = "Hujan Turun";
      advice =
          "Hentikan penyiraman. Buka saluran pembuangan air (drainase) agar akar tidak membusuk. JANGAN menebar pupuk.";
      isUrgent = true;
    }
    else if (humidity > 90) {
      title = "Kelembapan Tinggi";
      advice =
          "Waspada serangan jamur dan hama wereng. Cek bagian bawah daun dan kurangi kerapatan tanaman jika mungkin.";
      isUrgent = false;
    }
    else if (windSpeed > 5.5) {
      title = "Angin Kencang";
      advice =
          "Pasang penyangga (ajir) pada tanaman tinggi agar batang tidak patah.";
      isUrgent = true;
    }
    else if (weatherId == 800) {
      title = "Cuaca Cerah";
      advice =
          "Waktu yang tepat untuk pemupukan dan penyemprotan pestisida organik.";
      isUrgent = false;
    }

    return {
      'title': title,
      'advice': advice,
      'isUrgent': isUrgent,
      'icon': iconAsset,
    };
  }
}
