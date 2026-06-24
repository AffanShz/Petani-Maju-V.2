# 📋 Changelog - Petani Maju

Semua perubahan penting pada proyek ini akan didokumentasikan di file ini.

Format berdasarkan [Keep a Changelog](https://keepachangelog.com/id-ID/1.0.0/),
dan proyek ini mengikuti [Semantic Versioning](https://semver.org/lang/id/).

---

## [Unreleased]

### Planned
- **Deep-link Scanner → Katalog Obat**: dari hasil scan langsung buka detail obat yang cocok (sedang dikerjakan).
- Dukungan tanaman selain Tomat untuk Scanner.
- Marketplace hasil tani.

---

## [0.6.0] - 2026-06-24

### 🤖 AI Suite: Deteksi Penyakit, Katalog Obat, Riwayat & Chatbot

Rilis besar yang menambahkan kemampuan AI: deteksi penyakit tanaman berbasis foto, katalog obat, riwayat prediksi, dan chatbot percakapan.

### Added

#### 🔬 Scanner Penyakit Tanaman (AI)
- **Deteksi via Foto**: ambil gambar dari kamera/galeri (`image_picker`), inferensi otomatis.
- **Cloud Inference**: upload ke Supabase Storage (`images/history`) → `PestScannerService` POST ke endpoint `MODEL_TOMATO/predict` → label + confidence.
- **Detail Penyakit**: deskripsi, langkah penanganan, dan rekomendasi obat dari tabel `penyakit_tomat`.
- **Scanner UI/BLoC**: state lengkap (pick → loading → result/error), pemilihan jenis tanaman.

#### 💊 Katalog Obat Tanaman
- **Database Lokal** dari aset `katalog_obat_tanaman.json` (offline).
- **Pencarian & Filter** (nama, bahan aktif, sasaran, kategori/Organik), layout grid/list, dan halaman detail.

#### 📜 Riwayat Prediksi
- **`prediction_history`** di Supabase + model `PredictionHistory`.
- **Offline-First** via `HistoryRepository` (Supabase → fallback cache Hive).
- Hapus per item & hapus semua.

#### 🤖 Chatbot Asisten Tani (Gemini)
- **Streaming** jawaban via Google Gemini (`gemini-2.5-flash`, SSE).
- **Context-aware**: inject cuaca terkini + hama aktif ke prompt.
- **Domain-locked** + **prompt-injection guard** (sanitasi input 500 char, blokir pola berbahaya).
- Diakses via FAB di Home Screen.

#### 🔔 Riwayat Notifikasi
- Notifikasi tersimpan di Hive box terenkripsi (`notificationHistory`), dengan sorting & hapus.

### Changed
- **CacheService**: tambah box `settingsCache`, `plantingSchedule`, `notificationHistory`; method `saveRawData`/`getRawData`, profil & notification settings; enkripsi AES via `flutter_secure_storage`.
- **PestService**: tambah `fetchTomatoDiseaseByName`, `uploadImage`, dan CRUD `prediction_history`.
- **Environment**: variabel baru `MODEL_TOMATO` & `GEMINI_API_KEY` (diakses via `EnvConfig`); load `.env` dengan `flutter_dotenv`.
- **DI** (`main.dart`): tambah `HistoryRepository` & `ChatbotRepository` ke `MultiRepositoryProvider`.

### Dependencies
- Tambah `google_generative_ai`, `flutter_dotenv`, `image_picker`, `flutter_cache_manager`.

---

## [0.5.0] - 2026-01-11

### 🌍 Localization & UI Polish

Rilis ini menghadirkan dukungan multi-bahasa (Indonesia & Inggris) dan peningkatan pengalaman pengguna saat loading data.

### Added
- **Multi-language Support**: Implementasi `easy_localization` untuk dukungan Bahasa Indonesia dan Inggris.
- **Skeleton Loading**: Animasi loading shimmer pada Home Screen untuk pengalaman visual yang lebih halus.
- **Skeleton Components**: Widget reusable `SkeletonContainer` dan `HomeSkeleton`.
- **Weather Localization**: Penyesuaian terjemahan hari ("Hari Ini", "Today") pada widget cuaca.

### Changed
- **Home Screen Loading**: Mengganti `CircularProgressIndicator` dengan Skeleton UI.
- **Custom App Bar**: Menyesuaikan teks header dan status sinkronisasi agar mendukung multi-bahasa.
- **Header Section**: Perbaikan bug konstanta pada widget `SectionHeader`.

---

## [0.4.0] - 2026-01-11

### 🎉 User Experience & Profile Management

Rilis ini berfokus pada manajemen profil pengguna, dukungan teknis, dan perbaikan stabilitas startup.

### Added
- **Profil Pengguna Lokal**: Edit nama dan foto profil (tersimpan di Hive).
- **Reactive Updates**: Perubahan profil langsung terupdate di seluruh aplikasi (Home & Settings) tanpa refresh.
- **Bantuan & Dukungan**: Halaman kontak support via email langsung.
- **Tentang Aplikasi**: Informasi versi dan credit pengembang.
- **Automated Offline Mode**: Deteksi koneksi otomatis di background.

### Fixed
- **Startup Freeze**: Perbaikan aplikasi macet di splash screen (optimasi `ConnectivityService`).
- **Calendar Crash**: Perbaikan error "Bad State" saat menambah jadwal.
- **UI Glitches**: Perbaikan `use_build_context_synchronously` warnings.

---

## [0.3.0] - 2025-12-31

### 🎉 Major Architecture Refactor & Smart Features

Rilis besar yang mengubah arsitektur aplikasi menjadi lebih scalable menggunakan BLoC pattern, serta penambahan fitur cerdas berbasis background service.

### Added

#### 🏗️ Architecture & State Management
- **Flutter BLoC Implementation**: Migrasi penuh dari `StatefulWidget` biasa ke `flutter_bloc`.
- **Feature-First Structure**: Restrukturisasi folder menjadi `features/`, `core/`, dan `data/`.
- **Repository Pattern**: Abstraksi data layer yang lebih bersih untuk Weather, Calendar, dan Tips.

#### 🔔 Smart Notifications & Background Service
- **Background Service**: Menggunakan `workmanager` untuk cek cuaca secara periodik di background.
- **Weather Alerts**: Notifikasi otomatis jika ada potensi badai, hujan deras, atau hama.
- **Morning Briefing**: Notifikasi ringkasan cuaca harian setiap jam 06:00 pagi.
- **Quiet Mode**: Fitur "Jangan Ganggu" otomatis pada jam 22:00 - 05:00.
- **Notification Settings**: Halaman pengaturan lengkap untuk mengontrol jenis notifikasi yang ingin diterima.

#### 📅 Smart Calendar
- **Event Scheduling**: Tambah, Edit, dan Hapus jadwal kegiatan tani.
- **Automatic Reminders**: Alarm otomatis untuk setiap jadwal (H-1 dan Hari H).
- **Custom Time Picker**: Widget pemilih waktu yang lebih intuitif.

#### 🧭 Navigation Improvements
- **"Lihat Semua" Navigation**: Tombol di Home Screen kini berfungsi penuh mengarahkan ke halaman detail atau tab terkait.
- **Tab Switching**: Navigasi antar tab bottom bar secara programatik dari Home Screen.

### Changed

#### 🛠️ Codebase Improvements
- **Global Provider**: Setup `MultiRepositoryProvider` dan `MultiBlocProvider` di `main.dart`.
- **Clean Architecture**: Pemisahan tegas antara Business Logic, UI, dan Data.
- **Dependency Updates**: Update `flutter_local_notifications` dan `workmanager`.

### Fixed

#### 🐛 Bug Fixes
- Fix navigasi "Lihat Semua" yang sebelumnya tidak responsif.
- Fix notifikasi yang tidak muncul saat aplikasi ditutup (killed state).
- Fix issue state management yang menyebabkan UI tidak update saat data berubah.

---

## [0.2.0] - 2025-12-21

### 🎉 Offline Mode & Stability Update

Rilis yang berfokus pada stabilitas dan dukungan offline untuk pengalaman pengguna yang lebih baik.

### Added
- **Fitur Offline Mode**: Cache data local first menggunakan Hive.
- **Timeout Management**: Timeout handling untuk semua API calls (10 detik).
- **Pest Data Caching**: Simpan data hama lokal.

### Changed
- **Improved Image Loading**: Menggunakan `CachedNetworkImage` dengan placeholder.
- **Performance**: Optimasi startup time dengan deferred initialization.

---

## [0.1.0] - 2025-12-17

### 🎉 Initial Release

Rilis pertama aplikasi Petani Maju dengan fitur dasar:
- Cuaca Real-time & Forecast
- Tips Pertanian
- Kalender Tanam
- Info Hama & Penyakit

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 0.6.0 | 2026-06-24 | AI Suite: Scanner, Katalog Obat, Riwayat, Chatbot |
| 0.5.0 | 2026-01-11 | Localization & UI Polish |
| 0.4.0 | 2026-01-11 | UX & Profile Management |
| 0.3.0 | 2025-12-31 | BLoC Refactor & Smart Notifications |
| 0.2.0 | 2025-12-21 | Offline Mode & Stability |
| 0.1.0 | 2025-12-17 | Initial Release |
