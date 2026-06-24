# 📖 Dokumentasi Teknis - Petani Maju

Dokumentasi lengkap tentang arsitektur, komponen, dan cara kerja aplikasi Petani Maju.

## 📑 Daftar Isi

- [Arsitektur Aplikasi](#arsitektur-aplikasi)
- [Struktur Folder](#struktur-folder)
- [Data Layer](#data-layer)
- [Features](#features)
- [Widgets](#widgets)
- [Utils](#utils)
- [Flow Aplikasi](#flow-aplikasi)

---

## 🏗️ Arsitektur Aplikasi

Aplikasi Petani Maju menggunakan arsitektur **Feature-First** dengan pemisahan layer yang jelas:

```
┌──────────────────────────────────────────┐
│              Presentation                │
│    (Screens, Widgets, UI Components)     │
├──────────────────────────────────────────┤
│              Business Logic              │
│        (State Management, Utils)         │
├──────────────────────────────────────────┤
│               Data Layer                 │
│   (Services, Repositories, Datasources)  │
├──────────────────────────────────────────┤
│            External Sources              │
│    (APIs, Database, Local Storage)       │
└──────────────────────────────────────────┘
```

### Prinsip Arsitektur

1. **Feature-First Organization** - Kode diorganisir berdasarkan fitur (home, tips, calendar, dll)
2. **Separation of Concerns** - Pemisahan antara UI, logic, dan data
3. **Offline-First Approach** - Data cache dimuat terlebih dahulu, API fetch di background
4. **Single Responsibility** - Setiap service/class memiliki satu tanggung jawab

---

## 📁 Struktur Folder

```
lib/
├── core/                      # Konfigurasi dan konstanta global
│   ├── services/              # Service inti aplikasi
│   │   ├── cache_service.dart        # Local caching & enkripsi (Hive)
│   │   ├── notification_service.dart # Local notifications
│   │   ├── background_service.dart   # Workmanager background tasks
│   │   └── connectivity_service.dart # Deteksi koneksi (non-blocking)
│   └── constants/             # Colors, EnvConfig (env vars)
├── data/
│   ├── datasources/           # Service untuk akses data eksternal
│   │   ├── location_service.dart          # Reverse geocoding
│   │   ├── tips_services.dart             # Supabase tips API
│   │   ├── weather_service.dart           # OpenWeatherMap API
│   │   ├── pest_services.dart             # Supabase hama/penyakit/history + Storage
│   │   ├── pest_scanner_service.dart      # Model API deteksi penyakit (HTTP)
│   │   ├── planting_schedule_service.dart # Jadwal tanam (Hive)
│   │   └── chatbot_service.dart           # Google Gemini (streaming SSE)
│   ├── repositories/          # Mediasi data (BLoC ↔ datasource)
│   │   ├── weather_repository.dart
│   │   ├── tips_repository.dart
│   │   ├── pest_repository.dart
│   │   ├── calendar_repository.dart
│   │   ├── history_repository.dart        # Riwayat prediksi (Supabase + cache)
│   │   └── chatbot_repository.dart        # System prompt, context inject, guard
│   └── models/                # Data models (chat_message, prediction_history, pest, ...)
├── features/
│   ├── calendar/              # Kalender tanam
│   ├── home/                  # Home screen + skeleton
│   ├── pests/                 # Hama & penyakit
│   ├── scanner/              # Deteksi penyakit AI (bloc/ + screens/)
│   ├── drugs/                 # Katalog obat tanaman (screens/)
│   ├── history/               # Riwayat prediksi (bloc/ + screens/)
│   ├── chatbot/               # Asisten Tani (bloc/ + widgets/ + screens/)
│   ├── settings/              # Pengaturan
│   ├── tips/                  # Tips pertanian
│   ├── weather/               # Detail cuaca
│   ├── onboarding/            # First-time user guide
│   └── notifications/         # Riwayat notifikasi
├── logic/
│   └── app_lifecycle/         # AppBloc (global lifecycle)
├── utils/
│   └── weather_utils.dart     # Utility terjemahan cuaca
├── widgets/                   # Widget reusable global
└── main.dart                  # Entry point & DI (MultiRepositoryProvider)
```

> ⚠️ **Catatan:** `cache_service.dart` berada di `core/services/` (bukan `data/datasources/` seperti dokumen versi lama).

---

## 📊 Data Layer

### CacheService (`cache_service.dart`)

Service singleton untuk caching data lokal menggunakan Hive.

#### Inisialisasi
```dart
// Di main.dart, sebelum runApp()
await CacheService.init();
```

> **Keamanan:** Semua box dibuka dengan `HiveAesCipher` (AES-256). Kunci enkripsi di-generate sekali dan disimpan di `flutter_secure_storage` (Keystore/Keychain).

#### Boxes yang Digunakan
| Box Name | Deskripsi |
|----------|-----------|
| `weatherCache` | Menyimpan data cuaca terkini dan forecast |
| `tipsCache` | Menyimpan daftar tips pertanian (& pests) |
| `locationCache` | Menyimpan lokasi detail dan koordinat |
| `settingsCache` | Profil user, notif settings, offline mode, raw data generik (mis. cache history) |
| `plantingSchedule` | Jadwal tanam (kalender) |
| `notificationHistory` | Riwayat notifikasi yang diterima |

#### Methods

| Method | Return Type | Deskripsi |
|--------|-------------|-----------|
| `init()` | `Future<void>` | Inisialisasi Hive dan buka semua boxes |
| `saveWeatherData()` | `Future<void>` | Simpan data cuaca ke cache |
| `getCachedCurrentWeather()` | `Map<String, dynamic>?` | Ambil data cuaca cached |
| `getCachedForecast()` | `List<dynamic>?` | Ambil data forecast cached |
| `getWeatherCacheTime()` | `DateTime?` | Ambil timestamp cache cuaca |
| `isWeatherCacheStale()` | `bool` | Cek apakah cache sudah kadaluarsa |
| `saveTipsData()` | `Future<void>` | Simpan data tips ke cache |
| `getCachedTips()` | `List<Map<String, dynamic>>?` | Ambil data tips cached |
| `savePestsData()` | `Future<void>` | Simpan data hama ke cache |
| `getCachedPests()` | `List<Map<String, dynamic>>?` | Ambil data hama cached |
| `saveLocationData()` | `Future<void>` | Simpan data lokasi ke cache |
| `getCachedDetailedLocation()` | `String?` | Ambil lokasi detail cached |
| `getCachedCoordinates()` | `Map<String, double>?` | Ambil koordinat cached |
| `setOfflineMode()` | `Future<void>` | Set status offline mode |
| `getOfflineMode()` | `bool` | Ambil status offline mode |
| `saveUserProfile()` / `getUserProfile()` | `Future<void>` / `Map` | Simpan/ambil nama & foto profil (broadcast via `profileUpdateStream`) |
| `saveNotificationSettings()` / `getNotificationSettings()` | — | Pengaturan notifikasi |
| `saveNotification()` / `getNotificationHistory()` / `removeNotification()` | — | CRUD riwayat notifikasi (sort terbaru) |
| `saveRawData(key, value)` / `getRawData(key)` | — | Key-value string generik (dipakai cache history prediksi) |
| `clearAllCache()` | `Future<void>` | Hapus semua data cache |

#### Contoh Penggunaan
```dart
final cacheService = CacheService();

// Simpan data cuaca
await cacheService.saveWeatherData(
  currentWeather: weatherData,
  forecastList: forecastData,
);

// Ambil dari cache
final cachedWeather = cacheService.getCachedCurrentWeather();
if (cachedWeather != null) {
  // Gunakan data cached
}
```

---

### WeatherService (`weather_service.dart`)

Service untuk mengambil data cuaca dari OpenWeatherMap API.

#### Methods

| Method | Return Type | Deskripsi |
|--------|-------------|-----------|
| `fetchCurrentWeather({double? lat, double? lon})` | `Future<Map<String, dynamic>>` | Ambil data cuaca terkini |
| `fetchForecast({double? lat, double? lon})` | `Future<Map<String, dynamic>>` | Ambil data forecast 5 hari |

#### Contoh Penggunaan
```dart
final weatherService = WeatherService();

// Dengan koordinat custom
final weather = await weatherService.fetchCurrentWeather(
  lat: -6.5716,
  lon: 107.7587,
);

// Dengan koordinat default
final forecast = await weatherService.fetchForecast();
```

---

### LocationService (`location_service.dart`)

Service untuk reverse geocoding menggunakan OpenStreetMap Nominatim.

#### Methods

| Method | Return Type | Deskripsi |
|--------|-------------|-----------|
| `getDetailedLocation(double lat, double lon)` | `Future<Map<String, String>>` | Dapatkan detail lokasi dari koordinat |

#### Response Format
```dart
{
  'village': 'Nama Desa/Kelurahan',
  'district': 'Nama Kecamatan',
  'regency': 'Nama Kabupaten/Kota',
  'province': 'Nama Provinsi',
  'full': 'Alamat Lengkap',
}
```

---

### TipsService (`tips_services.dart`)

Service untuk mengambil data tips dari Supabase.

#### Methods

| Method | Return Type | Deskripsi |
|--------|-------------|-----------|
| `fetchTips()` | `Future<List<Map<String, dynamic>>>` | Ambil semua tips dari database |

> **Note**: Semua API service memiliki timeout 10 detik untuk mencegah app freeze saat offline.

---

### PestService (`pest_services.dart`)

Service Supabase untuk hama, penyakit tomat, riwayat prediksi, dan upload gambar.

#### Methods

| Method | Return Type | Deskripsi |
|--------|-------------|-----------|
| `fetchPests({String? query})` | `Future<List<Map>>` | Ambil semua hama (tabel `hama`) |
| `fetchPestById(int id)` | `Future<Map?>` | Ambil hama berdasarkan ID |
| `fetchPestByName(String name)` | `Future<Map?>` | Ambil hama berdasarkan nama |
| `fetchTomatoDiseaseByName(String name)` | `Future<Map?>` | Detail penyakit (tabel `penyakit_tomat`) — deskripsi, penanganan, obat |
| `uploadImage(String filePath)` | `Future<String>` | Upload foto ke Storage `images/history`, return public URL |
| `savePredictionHistory(Map data)` | `Future<void>` | Simpan hasil scan ke `prediction_history` |
| `fetchPredictionHistory()` | `Future<List<Map>>` | Ambil riwayat (terbaru dulu) |
| `deletePredictionHistory(String id)` | `Future<void>` | Hapus 1 riwayat |
| `deleteAllPredictionHistory()` | `Future<void>` | Hapus semua riwayat |

---

### PestScannerService (`pest_scanner_service.dart`)

Service deteksi penyakit tanaman via model API eksternal (HTTP).

| Property | Value |
|----------|-------|
| Base URL | `dotenv.env['MODEL_TOMATO']` (lihat `EnvConfig.modelTomatoUrl`) |
| Endpoint | `POST /predict` |
| Timeout | 45 detik |

**Request:** `{ "image_url": "<public-url>" }`
**Response:** `{ "label": "...", "confidence": 98.45 }` (confidence dalam persen, dibagi 100 oleh service).

Error handling spesifik per status: 404 (URL salah), 500 (server error), 503 (model warming up / sibuk), `SocketException` (koneksi).

---

### ChatbotService (`chatbot_service.dart`)

Wrapper Google Gemini dengan respons **streaming** (SSE).

| Property | Value |
|----------|-------|
| Model | `gemini-2.5-flash` |
| API Base | `https://generativelanguage.googleapis.com/v1` |
| Endpoint | `POST /models/{model}:streamGenerateContent?alt=sse&key={GEMINI_API_KEY}` |

#### Methods
| Method | Deskripsi |
|--------|-----------|
| `initSession({systemPrompt})` | Reset histori + seed system prompt |
| `sendMessageStream(prompt)` | `Stream<String>` — yield token per token |
| `resetSession({systemPrompt})` | Mulai sesi baru |
| `isReady` | `bool` apakah sesi sudah ter-init |

Service menjaga histori percakapan in-memory (`_history`) untuk konteks multi-turn.

---

## 🗂️ Repositories (sorotan)

### HistoryRepository (`history_repository.dart`)
Offline-first untuk riwayat prediksi. `getHistory()` coba Supabase dulu (`PestService.fetchPredictionHistory`), simpan ke cache lokal (`CacheService.saveRawData`), dan fallback ke cache jika gagal. Mendukung hapus per item & hapus semua (sinkron ke cache).

### ChatbotRepository (`chatbot_repository.dart`)
Lapisan logika chatbot:
- **System Prompt**: mengunci peran "Asisten Tani" & topik pertanian, larangan markdown, jawaban singkat.
- **`sanitizeInput()`**: potong ke 500 karakter + blokir pola prompt-injection (`ignore previous`, `you are now`, `jailbreak`, dll). Input berbahaya → string kosong (ditolak).
- **`_buildContextualPrompt()`**: inject konteks cuaca terkini (kota, suhu, kondisi, kelembaban) + daftar hama aktif dari cache sebelum pertanyaan user.

---

## 🎯 Features

### Scanner (`features/scanner/`)
Deteksi penyakit tanaman berbasis AI (BLoC: `PickImage` → auto `RunInference`).
Alur: pilih gambar (kamera/galeri) → upload ke Supabase Storage → `PestScannerService.predict()` → mapping label ke detail penyakit (`penyakit_tomat`) → tampilkan deskripsi, penanganan, **rekomendasi obat** → simpan ke `prediction_history`.

### Drugs (`features/drugs/`)
Katalog obat tanaman dari aset lokal `katalog_obat_tanaman.json`. Pencarian (nama/bahan aktif/sasaran/produsen/tanaman), filter kategori (termasuk Organik), layout grid/list, dan halaman detail (dosis, cara pakai, bahan aktif).

### History (`features/history/`)
Daftar riwayat hasil scan (gambar, jenis tanaman, penyakit, confidence, severity, tanggal). BLoC: load, hapus item, hapus semua. Offline-first via `HistoryRepository`.

### Chatbot (`features/chatbot/`)
Asisten Tani berbasis Gemini. UI: welcome state, daftar pesan, `StreamingText`, `ChatBubble`, `ChatInputBar`. Diakses lewat FAB di Home Screen. BLoC menangani streaming pesan.

### Home (`features/home/`)

Halaman utama aplikasi yang menampilkan:
- Cuaca terkini dengan kartu utama
- Prediksi cuaca 4 jam ke depan
- Peringatan hujan jika ada
- Quick access ke fitur lain

### Tips (`features/tips/`)

Fitur tips pertanian yang berisi:
- Daftar tips dari database Supabase
- Filter berdasarkan kategori
- Halaman detail tips

### Calendar (`features/calendar/`)

Fitur kalender tanam untuk:
- Perencanaan aktivitas pertanian
- Pengingat jadwal tanam

### Pests (`features/pests/`)

Fitur informasi hama dan penyakit:
- Daftar hama umum
- Daftar penyakit tanaman
- Cara penanganan

### Weather (`features/weather/`)

Detail cuaca yang lebih lengkap:
- Prediksi cuaca extended
- Informasi cuaca detail

### Settings (`features/settings/`)

Halaman pengaturan aplikasi yang mencakup:
- **Profil Pengguna**: Edit nama dan foto profil (Local Hive Storage).
- **Notifikasi**: Pengaturan granular untuk alert cuaca dan jadwal.
- **Bantuan & Dukungan**: Direct email support.
- **Tentang Aplikasi**: Informasi versi.
- **Bahasa**: Pengaturan bahasa aplikasi (Indonesia / English).

### Localization
Menggunakan `easy_localization` untuk manajemen bahasa. File terjemahan berupa JSON yang tersimpan di `assets/translations/`:
- `id.json` (Bahasa Indonesia)
- `en.json` (English)

---

## 🧩 Widgets

### MainWeatherCard (`main_weather_card.dart`)

Kartu cuaca utama yang menampilkan kondisi cuaca terkini dengan theme dinamis.

#### Properties
| Property | Type | Deskripsi |
|----------|------|-----------|
| `temperature` | `double` | Suhu dalam Celsius |
| `description` | `String` | Deskripsi cuaca |
| `location` | `String` | Nama lokasi |
| `onRefresh` | `VoidCallback` | Callback saat tombol refresh ditekan |

### CustomAppBar (`custom_app_bar.dart`)

AppBar kustom dengan styling konsisten.

### NavBar (`navbaar.dart`)

Bottom navigation bar dengan 4 tab:
- Home
- Calendar
- Tips
- Settings

### SectionHeader (`section_header.dart`)

Header untuk setiap section dengan styling konsisten.

### SkeletonContainer (`skeleton_container.dart`)

Widget dasar untuk membuat loading placeholder dengan efek shimmer.

### HomeSkeleton (`home_skeleton.dart`)

Placeholder UI khusus untuk Home Screen saat data sedang dimuat.

---

## 🛠️ Utils

### WeatherUtils (`weather_utils.dart`)

Utility class untuk translasi deskripsi cuaca dari bahasa Inggris ke Indonesia.

#### Methods

| Method | Parameters | Return | Deskripsi |
|--------|------------|--------|-----------|
| `translateWeather` | `String description` | `String` | Terjemahkan deskripsi cuaca |

#### Mapping Terjemahan

| English | Indonesian |
|---------|------------|
| thunderstorm | Hujan Petir |
| drizzle | Hujan Rintik-rintik |
| heavy rain | Hujan Deras |
| light rain | Hujan Ringan |
| rain | Hujan |
| scattered clouds | Cerah Berawan |
| broken clouds | Cerah Berawan |
| clouds | Berawan |
| clear | Cerah |
| mist/fog | Berkabut |

---

## 🔄 Flow Aplikasi

### Startup Flow

```
main()
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── CacheService.init()           # Inisialisasi Hive
  ├── Supabase.initialize()         # Inisialisasi Supabase
  ├── ConnectivityService.init()    # Non-blocking network check
  └── runApp(MainApp())
        └── MainScreen (NavBar)
              └── HomeScreen (default)
```

### Data Loading Flow (Offline-First)

```
Screen dibuka
    │
    ├── Load dari Cache (instant)
    │       ├── Data ada? → Tampilkan ke UI
    │       └── Data kosong? → Tampilkan loading
    │
    ├── Fetch dari API (background)
    │       ├── Berhasil? → Update cache + Update UI
    │       └── Gagal? → Tetap tampilkan data cache
    │                    → Tampilkan error jika cache kosong
    │
    └── UI ter-update
```

### Refresh Flow

```
User tekan tombol Refresh
    │
    ├── Cek Offline Mode?
    │       └── Ya → Skip fetch, tampilkan cache
    │
    ├── Ambil koordinat GPS saat ini (timeout 5 detik)
    │       └── Gagal? → Gunakan koordinat cached
    │
    ├── Fetch data cuaca baru dari API (timeout 10 detik)
    │       ├── Berhasil? → Update cache + Update UI
    │       └── Gagal? → Tampilkan error message
    │
    └── UI ter-update
```

### Scanner → History Flow (AI)

```
User pilih foto (kamera/galeri)
    │
    ├── Upload ke Supabase Storage (images/history) → public URL
    │
    ├── POST {image_url} ke MODEL_TOMATO/predict (timeout 45s)
    │       └── return { label, confidence }
    │
    ├── Mapping label → detail penyakit (tabel penyakit_tomat)
    │       └── deskripsi, penanganan, rekomendasi obat
    │
    ├── Tampilkan hasil ke UI
    │
    └── Simpan ke prediction_history (Supabase + cache lokal)
```

### Chatbot Flow (Gemini)

```
User kirim pesan
    │
    ├── sanitizeInput() — potong 500 char + blokir prompt-injection
    │       └── ditolak? → abaikan
    │
    ├── _buildContextualPrompt() — inject cuaca + hama aktif
    │
    └── streamGenerateContent (SSE) → yield token → UI streaming
```

### Offline Mode Flow

```
App Start tanpa Internet
    │
    ├── Supabase.initialize() timeout (10 detik)
    │       └── TimeoutException → Set appStartedOffline = true
    │
    ├── Auto-enable Offline Mode
    │       └── CacheService.setOfflineMode(true)
    │
    ├── Show Offline Notification Snackbar
    │
    └── Load semua data dari cache
            └── Skip semua API fetch
```

---

## 📱 Konfigurasi Platform

### Android

Permissions yang dibutuhkan (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS

Permissions yang dibutuhkan (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Aplikasi membutuhkan akses lokasi untuk menampilkan cuaca di lokasi Anda</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Aplikasi membutuhkan akses lokasi untuk menampilkan cuaca di lokasi Anda</string>
```

---

## 🔑 API Keys & Configuration

### OpenWeatherMap
- **API Key**: Dikonfigurasi di `weather_service.dart`
- **Endpoints yang digunakan**:
  - `/data/2.5/weather` - Cuaca terkini
  - `/data/2.5/forecast` - Forecast 5 hari

### Supabase
- **URL & Anon Key**: Diload dari `.env` via `EnvConfig` di `main.dart`
- **Tables yang digunakan**:
  - `tips` - Tips pertanian
  - `hama` - Data hama
  - `penyakit_tomat` - Detail penyakit tomat (deskripsi, penanganan, obat)
  - `prediction_history` - Riwayat hasil scan
- **Storage Bucket**: `images` (folder `history/` untuk foto scan)

### Google Gemini (Chatbot)
- **API Key**: `GEMINI_API_KEY` di `.env`
- **Model**: `gemini-2.5-flash` (streaming SSE)

### Model Deteksi Penyakit (Scanner)
- **Base URL**: `MODEL_TOMATO` di `.env`
- **Endpoint**: `POST /predict` (body `image_url`)

### OpenStreetMap Nominatim
- **Tidak memerlukan API key**
- **User-Agent**: `PetaniMaju/1.0`

---

## 📝 Best Practices

### State Management
- Gunakan `StatefulWidget` untuk komponen dengan state lokal
- Simpan data ke cache setelah setiap fetch berhasil

### Error Handling
- Selalu gunakan try-catch untuk operasi async
- Tampilkan fallback data dari cache jika fetch gagal
- Berikan feedback yang jelas ke user

### Performance
- Gunakan cache-first approach untuk mengurangi API calls
- Set cache expiration yang reasonable (default: 30 menit untuk cuaca)
- Lazy load data yang tidak diperlukan segera
- Gunakan `WidgetsBinding.instance.addPostFrameCallback` untuk deferred init

### Timeout Configuration
- Semua API requests harus memiliki timeout
- Gunakan timeout 10 detik untuk API calls
- Gunakan timeout 5 detik untuk Geolocator
- Wrap Supabase.initialize() dengan timeout

### Image Loading
- Gunakan `CachedNetworkImage` daripada `Image.network`
- Selalu sediakan `placeholder` dan `errorWidget`
- Fallback ke icon jika gambar gagal dimuat

---

*Dokumentasi ini terakhir diperbarui: 24 Juni 2026*
