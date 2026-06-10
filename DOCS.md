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
├── data/
│   ├── datasources/           # Service untuk akses data eksternal
│   │   ├── cache_service.dart     # Local caching dengan Hive
│   │   ├── location_service.dart  # Reverse geocoding
│   │   ├── tips_services.dart     # Supabase tips API
│   │   └── weather_service.dart   # OpenWeatherMap API
│   └── models/                # Data models
├── features/
│   ├── calendar/              # Fitur kalender tanam
│   │   └── screens/
│   ├── home/                  # Fitur home screen
│   │   ├── screens/
│   │   └── widgets/
│   │       ├── home_skeleton.dart # Loading skeleton UI
│   │       └── ...
│   ├── pests/                 # Fitur hama & penyakit
│   │   └── screens/
│   ├── settings/              # Fitur pengaturan
│   │   └── screens/
│   ├── tips/                  # Fitur tips pertanian
│   │   └── screens/
│   └── weather/               # Fitur detail cuaca
│       └── screens/
├── utils/
│   └── weather_utils.dart     # Utility untuk terjemahan cuaca
├── widgets/                   # Widget reusable global
│   ├── custom_app_bar.dart
│   ├── main_weather_card.dart
│   ├── navbaar.dart
│   └── section_header.dart
└── main.dart                  # Entry point aplikasi
```

---

## 📊 Data Layer

### CacheService (`cache_service.dart`)

Service singleton untuk caching data lokal menggunakan Hive.

#### Inisialisasi
```dart
// Di main.dart, sebelum runApp()
await CacheService.init();
```

#### Boxes yang Digunakan
| Box Name | Deskripsi |
|----------|-----------|
| `weatherCache` | Menyimpan data cuaca terkini dan forecast |
| `tipsCache` | Menyimpan daftar tips pertanian |
| `locationCache` | Menyimpan lokasi detail dan koordinat |

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

Service untuk mengambil data hama dari Supabase.

#### Methods

| Method | Return Type | Deskripsi |
|--------|-------------|-----------|
| `fetchPests({String? query})` | `Future<List<Map<String, dynamic>>>` | Ambil semua hama dari database |
| `fetchPestById(int id)` | `Future<Map<String, dynamic>?>` | Ambil hama berdasarkan ID |

---

## 🎯 Features

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
- **URL & Anon Key**: Dikonfigurasi di `main.dart`
- **Tables yang digunakan**:
  - `tips` - Tabel tips pertanian

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

*Dokumentasi ini terakhir diperbarui: 21 Desember 2024*
