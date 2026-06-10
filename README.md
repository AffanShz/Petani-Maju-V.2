# 🌾 Petani Maju

Aplikasi mobile pintar untuk membantu petani Indonesia dengan informasi cuaca real-time, tips pertanian, kalender tanam, dan sistem peringatan dini berbasis cuaca.

## 📚 Dokumentasi Utama

| Dokumen | Deskripsi |
|---------|-----------|
| [📖 DOCS.md](./DOCS.md) | Dokumentasi teknis & arsitektur lengkap |
| [🔌 API.md](./API.md) | Dokumentasi integrasi API (Supabase & OpenWeather) |
| [🤝 CONTRIBUTING.md](./CONTRIBUTING.md) | Panduan kontribusi developer |
| [📋 CHANGELOG.md](./CHANGELOG.md) | Riwayat perubahan versi |

> 📂 **Dokumentasi Lengkap**: Untuk dokumentasi lengkap termasuk User Guide, Security (OWASP MASVS), ERD, dan User Flow, silakan kunjungi repository dokumentasi di:
> 
> 🔗 **[Capstone-RPL-Documentation](https://github.com/AffanShz/Capstone-RPL-Documentation.git)**

## 🚀 Fitur Utama

### 🌤️ Sistem Cuaca Cerdas
- **Real-time Weather**: Data akurat dari OpenWeatherMap.
- **Prediksi Per Jam**: Prakiraan cuaca detail untuk 24 jam ke depan.
- **Weather Alerts**: Notifikasi otomatis saat ada potensi **Hujan Deras**, **Angin Kencang**, atau **Badai Petir**.
- **Analisis Risiko Hama**: Deteksi potensi serangan hama berdasarkan suhu dan kelembaban.

### 🔔 Notifikasi Pintar (Background System)
- **Morning Briefing**: Sapaan pagi dengan ringkasan cuaca hari ini (06:00).
- **Smart Calendar**: Pengingat jadwal tanam/pupuk (H-1, H-1 Jam, dan Hari H).
- **Quiet Mode**: Mode "Tenang" otomatis di malam hari (22:00 - 05:00) agar istirahat tidak terganggu.
- **Offline Support**: Notifikasi tetap berjalan meski aplikasi ditutup (menggunakan `Workmanager` & `AlarmManager`).

### 📅 Kalender Tanam Digital
- **Manajemen Jadwal**: Tambah, Edit, Hapus jadwal kegiatan tani.
- **Sinkronisasi Notifikasi**: Jadwal yang diedit otomatis memperbarui alarm notifikasi.
- **Rekomendasi Bulanan**: Saran aktivitas pertanian berdasarkan bulan berjalan.

### 📚 Tips & Edukasi
- **Konten Terkurasi**: Tips budidaya Padi, Jagung, dan Nutrisi Tanaman.
- **Offline Cache**: Artikel tersimpan lokal, baca kapan saja tanpa internet.

### 👤 Manajemen Profil & Support
- **Profil Lokal**: Personalisasi nama dan foto pengguna.
- **Bantuan Pengguna**: Layanan support via email terintegrasi.
- **Transparansi**: Informasi lengkap tentang aplikasi dan versi.

### � Security (OWASP MASVS Compliant)
- **Encrypted Storage**: Data lokal terenkripsi dengan AES-256.
- **Secure Key Management**: Kunci enkripsi tersimpan di Android Keystore/iOS Keychain.
- **Code Protection**: ProGuard obfuscation & R8 minification.
- **No Data Backup**: Mencegah ekstraksi data via backup.

### 🌍 Multi-Language Support
- **Bahasa Indonesia & English**: Switch bahasa melalui Settings.
- **Localized Content**: UI, notifikasi, dan konten tersedia dalam 2 bahasa.

## �🛠️ Tech Stack & Architecture

Aplikasi ini dibangun dengan **Clean Architecture** dan **BLoC Pattern** untuk skalabilitas maksimal.

| Layer | Technology |
|-------|------------|
| **Language** | Dart (Flutter 3.x) |
| **State Management** | **Flutter BLoC** (Business Logic Component) |
| **Architecture** | Feature-First (Data, Domain, Presentation) |
| **Backend** | Supabase (PostgreSQL, Auth, Storage) |
| **Weather API** | OpenWeatherMap |
| **Local Storage** | Hive (NoSQL Database) with AES-256 Encryption |
| **Secure Storage** | Flutter Secure Storage (Keystore/Keychain) |
| **Background Service** | Workmanager & Android Alarm Manager |
| **Notifications** | Flutter Local Notifications |
| **Localization** | Easy Localization (ID/EN) |
| **Security** | ProGuard, R8 Minification, OWASP MASVS Compliant |

## 📋 Riwayat Versi

| Versi | Tanggal | Deskripsi |
|-------|---------|-----------|
| 0.5.0 | 2026-01-11 | Localization (ID/EN) & Skeleton Loading UI |
| 0.4.0 | 2026-01-11 | Profile, Support, & Security (OWASP MASVS) |
| 0.3.0 | 2025-12-31 | BLoC Refactor & Smart Notifications |
| 0.2.0 | 2025-12-21 | Offline Mode & Stability |
| 0.1.0 | 2025-12-17 | Initial Release (Weather & Calendar Core) |

## 📦 Dependencies Utama

```yaml
dependencies:
  flutter_bloc: ^8.1.6
  equatable: ^2.0.7
  supabase_flutter: ^2.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^10.0.0    # Secure key storage
  workmanager: ^0.9.0+3
  flutter_local_notifications: ^17.0.0
  geolocator: ^14.0.2
  http: ^1.6.0
  intl: ^0.20.2
  table_calendar: ^3.1.2
  easy_localization: ^3.0.8          # Multi-language
  shimmer: ^3.0.0                    # Skeleton loading
  cached_network_image: ^3.4.1       # Image caching
```

## 📂 Struktur Project (Feature-First)

```
lib/
├── core/                   # Shared logic & services
│   ├── services/           # Background, Notification, Cache
│   ├── constants/          # Colors, API Keys
│   └── theme/              # App Themes
├── data/                   # Data Layer
│   ├── datasources/        # API calls & Local DB
│   ├── repositories/       # Data mediation logic
│   └── models/             # Data classes
├── features/               # Feature Modules
│   ├── home/               # HomeLogic, BLoC, UI, Skeleton
│   ├── calendar/           # CalendarLogic, BLoC, UI
│   ├── tips/               # TipsLogic, BLoC, UI
│   ├── pests/              # Hama & Penyakit Tanaman
│   ├── weather/            # WeatherUI & Detail
│   ├── settings/           # Profile, Notifikasi, Bahasa
│   ├── onboarding/         # First-time User Guide
│   └── notifications/      # Notification History
├── widgets/                # Reusable global widgets
├── utils/                  # Helper utilities
└── main.dart               # Entry point & DI Setup
```

## 🚀 Cara Menjalankan

### Persyaratan
- Flutter SDK >= 3.0.0
- Device/Emulator Android (Min SDK 21)

### Langkah Instalasi

1. **Clone Repository**
   ```bash
   git clone https://github.com/AffanShz/CapstonePetaniMaju.git
   cd petani_maju
   ```

2. **Setup Environment Variable**
   Buat file `.env` di root folder dan isi kredensial:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   OPENWEATHER_API_KEY=your_openweather_api_key
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

## 🔄 Alur Caching (Offline First)

```
User Membuka Fitur
       │
[Cek Koneksi Internet]
       │
   ┌───▼───┐
   │       │
(Online) (Offline)
   │       │
Load API   Load Hive Cache
   │       │
Simpan ke  Tampilkan Data
 Cache     (Snackbar: "Mode Offline")
   │
Update UI
```

## 🤝 Team
- **Adam Raga - A11.2024.15598**
- **Affan Shahzada - A11.2024.15784**
- **Aiska Zahra Nailani - A11.2024.16014**
- **Nur Alif Maulana - A11.2024.15936**

---
*Dibuat dengan ❤️ untuk kemajuan pertanian Indonesia.*
