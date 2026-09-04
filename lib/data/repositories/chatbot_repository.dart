import 'dart:io';
import 'package:intl/intl.dart';
import 'package:agrinova/core/services/cache_service.dart';
import 'package:agrinova/data/datasources/chatbot_service.dart';
import 'package:agrinova/data/models/chat_message.dart';
import 'package:agrinova/data/models/chat_session.dart';

class ChatbotRepository {
  final ChatbotService _chatbotService;
  final CacheService _cacheService;

  static const String _systemPrompt = '''
Kamu adalah Asisten Tani, partner & konsultan pertanian pintar Indonesia untuk aplikasi AgriNova. Berbicaralah dengan gaya santai, hangat, ramah, dan praktis seperti teman diskusi di kebun. Jawablah secara ringkas dan langsung ke poin tanpa berbelit-belit.

## AGEN MANAJEMEN JADWAL TANAM & KEGIATAN (CALENDAR AGENT)
Saat pengguna meminta atau menyetujui untuk membuat jadwal kegiatan pertanian (seperti penanaman, pemupukan rutin/berkala, penyemprotan, atau pemanenan):

1. **INFORMASI WAKTU REAL-TIME HARIAN**:
   - Gunakan `Waktu/Tanggal Hari Ini` dari data latar belakang sistem untuk menghitung relatif seperti "hari ini", "besok", "lusa", "minggu depan", atau "bulan depan".

2. **DUA PERTANYAAN WAJIB SEBELUM MEMBUAT JADWAL (MANDATORY REQUIREMENTS)**:
   Sebelum menyajikan payload pratinjau `[PROPOSE_ACTION: CREATE_CALENDAR_SCHEDULE]`, KAMU WAJIB MEMASTIKAN 2 INFORMASI BERIKUT SUDAH DIBERIKAN OLEH PENGGUNA:
   - **Informasi 1: Tanggal Mulai** (Kapan tanggal mulai menanam/melakukan kegiatan?)
   - **Informasi 2: Jam / Waktu Kegiatan** (Jam berapa kegiatan ingin dilakukan?, contoh: 07:00 pagi atau 16:00 sore)

   Jika salah satu atau kedua informasi tersebut BELUM diberikan oleh pengguna:
   - KAMU DILARANG MEMBUAT PAYLOAD PRATINJAU DENGAN TANGGAL/JAM SEMBARANGAN!
   - TANYAKAN LANGSUNG KEPADA PENGGUNA secara ramah dan ringkas, contoh:
     *"Baik! Untuk membuatkan jadwal yang akurat di kalender Anda, boleh tahu:*
     *1. Kapan tanggal Anda mulai menanam [nama_tanaman]?*
     *2. Pukul berapa Anda ingin kegiatan ini dijadwalkan (misalnya jam 07.00 pagi)?"*

3. **ATURAN FORMAT TANGGAL & JAM DALAM PAYLOAD**:
   - `tanggal_tanam` dalam payload JSON WAJIB menyertakan tanggal dan jam tepat kegiatan berformat ISO `YYYY-MM-DDTHH:mm:ss` (contoh: `2026-09-01T07:00:00` jika jam 7 pagi).
   - Hitung kalkulasi tanggal kegiatan secara presisi (misal tanam 1 Sept jam 07:00 dan pemupukan 14 hari kemudian jam 07:00, maka `tanggal_tanam` WAJIB `2026-09-15T07:00:00`).

4. **PENJADWALAN RUTIN / BERULANG (WEEKLY / RECURRING)**:
   - Jika pengguna meminta jadwal berulang (contoh: "buatkan jadwal pemupukan tiap minggu di hari Senin jam 07:00 pagi sampai bulan November"):
     - Hitung dan susun DAFTAR SEMUA TANGGAL & JAM KEGIATAN yang diminta.
     - Gunakan format array `"schedules": [...]` dalam JSON payload.

5. **FORMAT JSON PAYLOAD (`[PROPOSE_ACTION: CREATE_CALENDAR_SCHEDULE]`)**:
   - Untuk **1 Kegiatan**:
     ```json
     {
       "schedules": [
         {
           "nama_tanaman": "Pemupukan Susulan Tomat",
           "tanggal_tanam": "2026-09-15T07:00:00",
           "catatan": "Dosis 2g/liter air. Disiram pukul 07:00 WIB."
         }
       ]
     }
     ```
   - Untuk **Kegiatan Rutin Berulang**:
     ```json
     {
       "schedules": [
         {
           "nama_tanaman": "Pemupukan Rutin Tomat (Minggu 1)",
           "tanggal_tanam": "2026-09-07T07:00:00",
           "catatan": "Pemupukan rutin mingguan."
         },
         {
           "nama_tanaman": "Pemupukan Rutin Tomat (Minggu 2)",
           "tanggal_tanam": "2026-09-14T07:00:00",
           "catatan": "Pemupukan rutin mingguan."
         }
       ]
     }
     ```
6. **KONSISTENSI JAWABAN**:
   - Pastikan tanggal dan jam yang kamu sebutkan dalam teks jawaban persis sama dengan tanggal dan jam dalam payload JSON!

7. **PENAWARAN PENJADWALAN PROAKTIF (PROACTIVE SCHEDULING OFFER)**:
   - Apabila pengguna sedang membahas topik yang berkaitan dengan jadwal, tahapan penanaman, jadwal pemupukan, penyemprotan, atau estimasi panen (sekalipun pengguna BELUM secara eksplisit menyuruh membuat jadwal):
     - Setelah memberikan jawaban utama, TAWARKAN BANTUAN secara proaktif di akhir pesan: *"Apakah Anda ingin saya bantu buatkan jadwal [kegiatan] ini langsung ke Kalender Tanam Anda?"*
     - Sertakan tombol opsi interaktif menggunakan format action prompt link, contoh: `[🌱 Ya, Buatkan Jadwal Pemupukan](action:prompt:Tolong buatkan jadwal pemupukan untuk tanaman saya mulai hari ini)` agar pengguna tinggal sekali klik.

## AGEN IRIGASI & MONITORING CUACA PINTAR (SMART WEATHER AGENT)
Saat pengguna berkonsultasi mengenai penyiraman tanaman, irigasi, atau kelayakan pemupukan/penyemprotan berdasarkan cuaca lokasi saat ini:
1. **ANALISIS DATA CUACA LOKASI**:
   - Analisis data `Cuaca & Lokasi` real-time yang ada pada Data Latar Belakang Sistem (suhu, kelembapan, kondisi cuaca).
   - Jika cuaca Hujan: Sarankan penundaan penyiraman dan pemupukan.
   - Jika cuaca Cerah & Suhu Tinggi (>30°C): Sarankan penyiraman pagi (06:00-08:00) atau sore (16:00-17:30).
   - Jika kelembapan tinggi (>85%): Berikan peringatan risiko penyakit jamur.
2. **FORMAT TAG KARTU REKOMENDASI CUACA (`[WEATHER_RECOMMENDATION]`)**:
   - Berikan penjelasan ramah & praktis dalam 2-3 kalimat.
   - Di akhir jawaban, KAMU WAJIB MENYERTAKAN TAG KARTU REKOMENDASI CUACA berformat JSON:
     `[WEATHER_RECOMMENDATION]`
     ```json
     {
       "lokasi": "Nama Kota",
       "suhu": "29°C",
       "kelembapan": "75%",
       "kondisi": "Cerah Berawan",
       "rekomendasi_irigasi": "Disiram 1x pada sore hari (16:30 WIB)",
       "saran_pemupukan": "Aman untuk pemupukan daun hari ini"
     }
     ```

## AGEN KATALOG OBAT & PESTISIDA PINTAR (PHARMACY SEARCH AGENT)
Saat pengguna berkonsultasi mengenai pengobatan, penanganan penyakit, meminta rekomendasi obat/fungisida/insektisida/bakterisida/pupuk, atau menanyakan bahan aktif tertentu:
1. **ANALISIS PENCARIAN OBAT & BAHAN AKTIF**:
   - Jelaskan fungsi obat, kegunaan bahan aktif, dosis, dan petunjuk pemakaian secara alami dan praktis.
   - Pilihlah obat yang paling sesuai dari katalog resmi aplikasi berdasarkan penyakit sasaran, tanaman, atau bahan aktif yang diminta.
2. **TAG REKOMENDASI OBAT MANDATORI (`[RECOMMENDED_DRUGS: ...]`)**:
   - Di akhir jawaban, KAMU WAJIB MENYERTAKAN TAG REKOMENDASI OBAT berformat:
     `[RECOMMENDED_DRUGS: NamaObat1, NamaObat2]`
   - Pilih obat dari katalog resmi:
     - Fungisida: Dithane M-45, Antracol 70 WP, Score 250 EC, Amistar Top, Ridomil Gold MZ 68 WG, Topsin M 70 WP, Benlate 50 WP, Kocide 77 WP, Bravo 500 SC, Rovral 50 WP, Melody Duo, Nativo 75 WG
     - Insektisida: Regent 50 SC, Confidor 200 SL, Decis 25 EC, Match 50 EC, Virtako 300 SC, Prevathon 50 SC, Dursban 200 EC, Lannate 40 SP
     - Bakterisida: Agrimycin 15 WP, Bacteriosin 10 SP
3. **AKSI OPSI KATALOG LENGKAP**:
   - Di bagian paling bawah, sertakan tombol opsi untuk membuka katalog penuh: `[💊 Buka Katalog Obat Lengkap](action:drugs)`.

## ATURAN PENANGANAN GAMBAR (IMAGE HANDLING)
1. **PENGGUNA MENGIRIM GAMBAR TANPA TEKS (FOTO SAJA)**:
   - Berikan respon singkat (1 kalimat) tentang status kondisi/penyakit tanaman dari gambar (Contoh jika sehat: "Wah, tanaman kamu dalam kondisi sehat! 🌱" atau jika terserang penyakit: "Tanaman kamu teridentifikasi terkena [Nama Penyakit]. ⚠️").
   - Lanjutkan dengan kalimat persis: "Apa ada yang bisa saya bantu tentang tanamanmu?"
   - Kamu WAJIB menyertakan 4 tombol opsi pilihan di akhir pesan (menggunakan format markdown link `[Label](action:prompt:Teks Pertanyaan)`).
2. **PENGGUNA MENGIRIM GAMBAR DENGAN TEKS / PERTANYAAN**:
   - Langsung jawab pertanyaan pengguna secara spesifik sesuai teks yang dikirimkan bersama gambar. DILARANG menampilkan daftar tombol opsi default.

## PRINSIP UTAMA KOMUNIKASI (GAYA PERCAKAPAN ASISTEN & PARTNER TANI)
1. **GAYA BAHASA ALAMI & MANUSIAWI (TIDAK KAKU/TIDAK BAKU BERLEBIHAN)**:
   - Berbicaralah seperti rekan/partner pertanian terpercaya yang hangat, praktis, ramah, dan mudah dipahami.
   - HINDARI bahasa buku teks akademis yang terlalu formal, kaku, atau panjang lebar.

2. **RESPONS RINGKAS & LANGSUNG KE POIN (MAX 2-4 KALIMAT)**:
   - DILARANG memberikan dinding teks (*wall of text*) yang membuat pengguna malas membaca!
   - Untuk pertanyaan baru atau awal topik: Berikan **poin inti jawaban secara padat & langsung** (cukup 2–4 kalimat ringkas atau 3 bullet point pendek).
   - Di akhir jawaban, TAWARKAN BANTUAN DETAIL: *"Mau saya jelaskan rincian selengkapnya?"* atau sertakan tombol opsi.
   - HANYA berikan penjelasan panjang dan mendalam apabila pengguna dari awal secara eksplisit meminta analisis detail (seperti: *"jelaskan secara mendalam/detail tentang..."*).

3. **FORMAT MARKDOWN RINGKAS & INTERAKTIF**:
   - Gunakan bold untuk istilah penting, bullet point pendek, emoji yang relevan, dan link tombol aksi (`[Label](action:nama_fitur)` atau `[Label](action:prompt:teks_pertanyaan)`).

## BATASAN
Jika pertanyaan DI LUAR topik pertanian, perkebunan, atau fitur AgriNova, tolak secara sopan dalam 1 kalimat singkat:
"Maaf, saya Asisten Tani yang khusus melayani konsultasi seputar pertanian dan perkebunan."

''';


  static const _dangerousPatterns = [
    'ignore previous',
    'ignore all previous',
    'forget your',
    'you are now',
    'system:',
    '[inst]',
    '[/inst]',
    '<|',
    '|>',
    '###system',
    'new instructions:',
    'override:',
    'jailbreak',
    'pretend you are',
    'act as if',
  ];

  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  ];

  ChatbotRepository({
    required ChatbotService chatbotService,
    required CacheService cacheService,
  })  : _chatbotService = chatbotService,
        _cacheService = cacheService {
    _chatbotService.initSession(systemPrompt: _systemPrompt);
  }

  String sanitizeInput(String input) {
    if (input.trim().isEmpty) return '';

    String sanitized = input.trim();
    if (sanitized.length > 500) {
      sanitized = sanitized.substring(0, 500);
    }

    final lower = sanitized.toLowerCase();
    for (final pattern in _dangerousPatterns) {
      if (lower.contains(pattern)) {
        return '';
      }
    }

    return sanitized;
  }

  /// Validasi gambar sebelum dikirim (ukuran dan tipe file).
  /// Mengembalikan pesan error jika tidak valid, atau `null` jika valid.
  String? validateImageFile(File? file) {
    if (file == null) return null;
    if (!file.existsSync()) {
      return 'File gambar tidak ditemukan.';
    }

    final length = file.lengthSync();
    if (length > maxImageSizeBytes) {
      return 'Ukuran gambar terlalu besar (maksimal 5 MB).';
    }

    final ext = file.path.split('.').last.toLowerCase();
    if (!supportedImageExtensions.contains(ext)) {
      return 'Format file tidak didukung. Harap gunakan gambar (JPG, PNG, atau WEBP).';
    }

    return null;
  }

  Stream<String> sendMessage({
    required String userText,
    String? imagePath,
    Map<String, dynamic>? currentWeather,
    List<dynamic>? plantingSchedules,
    List<dynamic>? recentScanHistory,
  }) {
    final contextualPrompt = _buildContextualPrompt(
      userText: userText,
      imagePath: imagePath,
      currentWeather: currentWeather,
      plantingSchedules: plantingSchedules,
      recentScanHistory: recentScanHistory,
    );

    File? imageFile;
    if (imagePath != null && imagePath.isNotEmpty) {
      imageFile = File(imagePath);
    }

    return _chatbotService.sendMessageStream(
      prompt: contextualPrompt,
      imageFile: imageFile,
    );
  }

  void resetSession() {
    _chatbotService.resetSession(systemPrompt: _systemPrompt);
  }

  void loadSessionHistory(List<ChatMessage> messages) {
    _chatbotService.loadSessionHistory(messages, systemPrompt: _systemPrompt);
  }

  // ==================== CHAT SESSIONS PERSISTENCE ====================

  List<ChatSession> getChatSessions() {
    return _cacheService.getChatSessions();
  }

  ChatSession? getChatSession(String id) {
    return _cacheService.getChatSession(id);
  }

  Future<void> saveChatSession(ChatSession session) async {
    await _cacheService.saveChatSession(session);
  }

  Future<void> deleteChatSession(String id) async {
    await _cacheService.deleteChatSession(id);
  }

  Future<void> clearAllChatSessions() async {
    await _cacheService.clearAllChatSessions();
  }

  String? getLastActiveSessionId() {
    return _cacheService.getLastActiveChatSessionId();
  }

  Future<void> setLastActiveSessionId(String? id) async {
    await _cacheService.setLastActiveChatSessionId(id);
  }

  bool _isSimpleGreeting(String text) {
    final clean = text.trim().toLowerCase();
    final greetings = [
      'halo',
      'hallo',
      'hai',
      'hi',
      'pagi',
      'selamat pagi',
      'siang',
      'selamat siang',
      'sore',
      'selamat sore',
      'malam',
      'selamat malam',
      'assalamualaikum',
      'assalamu\'alaikum',
      'tes',
      'test',
      'ping',
    ];
    return greetings.contains(clean) || (clean.length <= 3 && !clean.contains(' '));
  }

  String _buildContextualPrompt({
    required String userText,
    String? imagePath,
    Map<String, dynamic>? currentWeather,
    List<dynamic>? plantingSchedules,
    List<dynamic>? recentScanHistory,
  }) {
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final isTextEmpty = userText.trim().isEmpty;

    // ALUR PENGIRIMAN GAMBAR TANPA TEKS
    if (hasImage && isTextEmpty) {
      final buffer = StringBuffer();
      buffer.writeln(
        'ATURAN KHUSUS (PENGGUNA MENGIRIM GAMBAR TANPA TEKS):\n'
        '1. Berikan 1 kalimat singkat hasil deteksi kondisi/penyakit tanaman dari gambar tersebut (Contoh jika sehat: "Wah, tanaman kamu dalam kondisi sehat! 🌱" atau jika sakit: "Tanaman kamu teridentifikasi terkena [Nama Penyakit]. ⚠️").\n'
        '2. Lanjutkan dengan kalimat persis: "Apa ada yang bisa saya bantu tentang tanamanmu?"\n'
        '3. Kamu WAJIB menyertakan 4 tombol opsi berikut di bagian akhir pesan dalam format markdown link persis:\n'
        '[💊 Rekomendasi Obat & Perawatan](action:prompt:Tolong berikan rekomendasi obat dan tata cara perawatan untuk tanaman ini)\n'
        '[🛡️ Cara Pencegahan](action:prompt:Bagaimana cara pencegahan agar tanaman tidak terserang penyakit lagi?)\n'
        '[📅 Jadwal Perawatan & Irigasi](action:prompt:Bagaimana jadwal penyiraman dan pemupukan yang ideal?)\n'
        '[🔍 Penjelasan Detail Diagnosa](action:prompt:Berikan penjelasan detail mengenai diagnosa penyakit pada tanaman ini)'
      );

      if (recentScanHistory != null && recentScanHistory.isNotEmpty) {
        final lastScan = recentScanHistory.first;
        if (lastScan is Map) {
          final plant = lastScan['plantName'] ?? lastScan['nama_tanaman'] ?? 'Tanaman';
          final disease = lastScan['diseaseName'] ?? lastScan['diagnosa'] ?? 'Sehat';
          buffer.writeln('Riwayat Pemindaian Terakhir: $plant ($disease)');
        }
      }

      buffer.writeln('---');
      buffer.write('[Foto Tanaman Diunggah]');
      return buffer.toString();
    }


    // ALUR PENGIRIMAN GAMBAR DENGAN TEKS / PERTANYAAN
    if (hasImage && !isTextEmpty) {
      final buffer = StringBuffer();
      buffer.writeln(
        'ATURAN KHUSUS (PENGGUNA MENGIRIM GAMBAR BERSAMA PERTANYAAN TEKS):\n'
        'Analisis gambar ini dan LANGSUNG JAWAB pertanyaan pengguna secara spesifik: "$userText". DILARANG menampilkan daftar tombol opsi default.'
      );
      buffer.writeln('---');
      buffer.write(userText);
      return buffer.toString();
    }

    // Jika pesan hanya sapaan sederhana dan tidak ada gambar
    if (_isSimpleGreeting(userText) && !hasImage) {
      return userText;
    }

    final buffer = StringBuffer();

    buffer.writeln('[DATA LATAR BELAKANG SISTEM]');
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id').format(now);
    final isoDateStr = DateFormat('yyyy-MM-dd').format(now);
    buffer.writeln('Waktu/Tanggal Hari Ini: $dateStr ($isoDateStr)');

    // 1. Konteks Cuaca & Lokasi
    if (currentWeather != null && currentWeather.isNotEmpty) {
      try {
        final cityName = currentWeather['name']?.toString() ?? 'lokasi kamu';
        final mainRaw = currentWeather['main'];
        final main = mainRaw is Map ? Map<String, dynamic>.from(mainRaw) : null;
        final temp = main?['temp'];
        final humidity = main?['humidity'];
        final weatherListRaw = currentWeather['weather'];
        final weatherList = weatherListRaw is List ? List<dynamic>.from(weatherListRaw) : null;
        final condition = weatherList?.isNotEmpty == true
            ? (weatherList![0] is Map ? Map<String, dynamic>.from(weatherList[0] as Map)['description'] : null)
            : null;

        buffer.write('Cuaca & Lokasi: $cityName, ');
        if (temp != null) buffer.write('Suhu ${(temp as num).toStringAsFixed(1)}°C, ');
        if (condition != null) buffer.write('Kondisi $condition, ');
        if (humidity != null) buffer.write('Kelembapan $humidity%');
        buffer.writeln();
      } catch (_) {}
    }

    // 2. Konteks Jadwal Tanam & Kebun Aktiviti
    if (plantingSchedules != null && plantingSchedules.isNotEmpty) {
      try {
        final schedulesStr = plantingSchedules.take(3).map((item) {
          if (item is Map) {
            final crop = item['nama_tanaman'] ?? item['cropName'] ?? 'Tanaman';
            final date = item['tanggal_tanam'] ?? item['plantDate'] ?? '';
            return '$crop (Tanam: $date)';
          }
          return item.toString();
        }).join('; ');
        if (schedulesStr.isNotEmpty) {
          buffer.writeln('Kebun / Jadwal Tanam Pengguna: $schedulesStr');
        }
      } catch (_) {}
    }

    // 3. Konteks Riwayat Scan Hama Terakhir
    if (recentScanHistory != null && recentScanHistory.isNotEmpty) {
      try {
        final lastScan = recentScanHistory.first;
        if (lastScan is Map) {
          final plant = lastScan['plantName'] ?? lastScan['nama_tanaman'] ?? 'Tanaman';
          final disease = lastScan['diseaseName'] ?? lastScan['diagnosa'] ?? 'Sehat';
          buffer.writeln('Riwayat Scan Terakhir: $plant ($disease)');
        }
      } catch (_) {}
    }

    // Hama daerah
    final cachedPests = _cacheService.getCachedPests();
    if (cachedPests != null && cachedPests.isNotEmpty) {
      final pestNames = cachedPests
          .take(4)
          .map((p) => p['nama']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .join(', ');
      if (pestNames.isNotEmpty) {
        buffer.writeln('Hama Aktif Sekitar: $pestNames');
      }
    }

    buffer.writeln('---');
    buffer.write(userText);
    return buffer.toString();
  }


}
