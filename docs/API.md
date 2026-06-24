# 🔌 Dokumentasi API - Petani Maju

Dokumentasi lengkap tentang API dan service yang digunakan pada aplikasi Petani Maju.

---

## 📑 Daftar Isi

- [Environment Variables](#environment-variables)
- [OpenWeatherMap API](#openweathermap-api)
- [OpenStreetMap Nominatim](#openstreetmap-nominatim)
- [Supabase API](#supabase-api)
- [Disease Detection Model API](#disease-detection-model-api)
- [Google Gemini API (Chatbot)](#google-gemini-api-chatbot)
- [Background Services](#background-services)

---

## 🔐 Environment Variables

Aplikasi ini memerlukan konfigurasi file `.env` di root project:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
OPENWEATHER_API_KEY=your-openweather-api-key
MODEL_TOMATO=https://your-model-host/         # Scanner penyakit (POST /predict)
GEMINI_API_KEY=your-gemini-api-key            # Chatbot Asisten Tani
```

> Semua variabel diakses lewat helper `EnvConfig` (`lib/core/constants/env_config.dart`). `MODEL_TOMATO` punya fallback ke endpoint demo jika kosong.

### ⚙️ Setup Guide - Langkah Demi Langkah

#### **Langkah 1: Buat File `.env`**

1. Buka root folder project (sejajar dengan `pubspec.yaml`)
2. Buat file baru bernama `.env` (tanpa nama lain)
3. Copy isi dari `.env.example` sebagai template

**Struktur folder:**
```
petani_maju/
├── .env              ← Buat file ini (baru)
├── .env.example      ← Template reference
├── pubspec.yaml
├── lib/
└── ...
```

#### **Langkah 2: Setup Supabase**

**A. Daftar di Supabase**
- Kunjungi [supabase.com](https://supabase.com)
- Click "Start your project"
- Sign up dengan GitHub atau email
- Pilih region terdekat (Asia/Singapore)

**B. Buat Project Baru**
- Klik "New project"
- Isi nama project (contoh: `petani-maju-dev`)
- Buat password database kuat
- Tunggu hingga project selesai dibuat (~2 menit)

**C. Copy Credential**
- Masuk ke project dashboard
- Klik **Settings** (gear icon) di sidebar kiri
- Pilih tab **API**
- Scroll ke **Project URL** → Copy URL ini
- Scroll ke **Project API keys** → Copy `anon public` key

**D. Isi ke `.env`**
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**✅ Verifikasi:**
- URL format: `https://xxxxx.supabase.co` (dengan `.co` di akhir)
- Anon Key: panjang ~200+ karakter, dimulai dengan `eyJ`

#### **Langkah 3: Setup OpenWeather API**

**A. Daftar di OpenWeatherMap**
- Kunjungi [openweathermap.org](https://openweathermap.org)
- Click "Sign Up" di top right
- Isi email dan password
- Verify email Anda (cek inbox)

**B. Dapatkan API Key**
- Login ke dashboard OpenWeatherMap
- Di sidebar kiri, klik **API Keys**
- Copy API key default (atau buat baru)
- Paste ke `.env`

**D. Isi ke `.env`**
```env
OPENWEATHER_API_KEY=abc123def456ghi789jkl012mno34567pqr
```

**✅ Verifikasi:**
- API Key panjang: 32 karakter
- Format: kombinasi huruf dan angka

#### **Langkah 3b: Setup AI (Scanner & Chatbot)**

**A. Gemini API Key (Chatbot)**
- Buka [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
- Login Google → **Create API Key** → copy
- Paste ke `GEMINI_API_KEY`

**B. Model Tomato URL (Scanner)**
- Base URL service model yang mengekspos `POST /predict`
- Paste ke `MODEL_TOMATO` (mis. `https://xxxx.hf.space`)

```env
GEMINI_API_KEY=AIzaSy...
MODEL_TOMATO=https://your-model-host
```

#### **Langkah 4: Jalankan Aplikasi**

```bash
# Clean & refresh dependencies
flutter clean
flutter pub get

# Run dengan .env
flutter run --dart-define-from-file=.env
```

---

## 🔐 Environment Variables Security Checklist

| ✅ Harus | ❌ Jangan | Alasan |
|---------|---------|--------|
| Simpan di `.env` | Hardcode di kode | Lebih aman, bisa di-rotate |
| `.env` di `.gitignore` | Commit `.env` | Jangan expose credentials |
| Gunakan credential dev | Gunakan credential prod | Hindari kerusakan data produksi |
| Update berkala | Reuse credential lama | Security best practice |
| Catat di password manager | Catat di sticky notes | Hindari kehilangan |

---

## 🌤️ OpenWeatherMap API

API untuk mendapatkan data cuaca real-time dan forecast.

### Konfigurasi Service

| Property | Value |
|----------|-------|
| Base URL | `https://api.openweathermap.org/data/2.5` |
| Auth | Via Query Param `appid` |
| Helper | `lib/data/datasources/weather_service.dart` |

### 1. Current Weather
Mengambil data cuaca saat ini.

**Endpoint:** `GET /weather`

**Parameters:**
- `lat`, `lon`: Koordinat lokasi
- `appid`: API Key (dari .env)
- `units`: `metric`
- `lang`: `id`

**Example Implementation:**
```dart
final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id';
```

### 2. Forecast (5 Hari / 3 Jam)
Mengambil prediksi cuaca ke depan.

**Endpoint:** `GET /forecast`

**Response Structure (Simpliied):**
```json
{
  "list": [
    {
      "dt": 1702803600,
      "main": { "temp": 28.5 },
      "weather": [{ "description": "hujan ringan" }],
      "dt_txt": "2024-12-31 12:00:00"
    }
  ]
}
```

---

## 🗺️ OpenStreetMap Nominatim

API untuk reverse geocoding (koordinat ke alamat desa/kecamatan).

**Base URL:** `https://nominatim.openstreetmap.org`

### Reverse Geocoding
**Endpoint:** `GET /reverse`

**Parameters:**
- `format`: `json`
- `lat`, `lon`: Koordinat
- `addressdetails`: `1`

**Rate Limit:** Maksimal 1 request per detik. Harap gunakan caching.

---

## 🔷 Supabase API

Backend as a Service (BaaS) untuk Tips, Hama, Penyakit, Riwayat Prediksi, dan Storage gambar.

**Client Library:** `supabase_flutter`

### Tabel: `tips`

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary Key |
| `title` | text | Judul Artikel |
| `category` | text | Kategori (Padi, Jagung, dll) |
| `content` | text | Isi Tips |
| `image_url` | text | Link Gambar |
| `created_at` | timestamp | Waktu dibuat |

### Tabel: `hama`
Data hama (kolom utama `nama`). Query mendukung filter `ilike` pada `nama`.

### Tabel: `penyakit_tomat`
Detail penyakit hasil deteksi scanner. Field yang dipakai UI: `nama_penyakit`, `deskripsi_penyakit`, `penanganan`, `obat`.

### Tabel: `prediction_history`

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary Key |
| `user_id` | uuid? | Pemilik (opsional) |
| `image_url` | text | URL gambar di Storage |
| `plant_type` | text | Jenis tanaman (mis. Tomat) |
| `disease` | text | Penyakit terdeteksi |
| `confidence` | float | Tingkat keyakinan (0–1) |
| `severity` | text | Tingkat keparahan |
| `status` | text | Status |
| `created_at` | timestamp | Waktu prediksi |

### Storage Bucket: `images`
Foto scan diunggah ke folder `history/` dengan nama `{timestamp}.{ext}`, lalu di-`getPublicUrl()`.

### Query Example (Dart)

```dart
final response = await supabase
    .from('prediction_history')
    .select()
    .order('created_at', ascending: false);
```

---

## 🧠 Disease Detection Model API

API model deteksi penyakit tanaman (Scanner). Service: `pest_scanner_service.dart`.

| Property | Value |
|----------|-------|
| Base URL | `MODEL_TOMATO` (`.env`) |
| Endpoint | `POST /predict` |
| Timeout | 45 detik |

**Request:**
```json
{ "image_url": "https://.../history/1699999999.jpg" }
```

**Response (200):**
```json
{ "label": "Early Blight", "confidence": 98.45 }
```
> `confidence` dari backend dalam persen; service membaginya 100 → `0.9845`.

**Error Codes:** `404` (URL salah), `500` (server error), `503` (model warming up/sibuk).

---

## 💬 Google Gemini API (Chatbot)

Chatbot Asisten Tani. Service: `chatbot_service.dart`.

| Property | Value |
|----------|-------|
| Model | `gemini-2.5-flash` |
| Base URL | `https://generativelanguage.googleapis.com/v1` |
| Endpoint | `POST /models/gemini-2.5-flash:streamGenerateContent?alt=sse&key={GEMINI_API_KEY}` |
| Mode | Streaming (Server-Sent Events) |

**Request Body:** `{ "contents": [ {role, parts:[{text}]} , ... ] }` (histori percakapan).

**Response:** stream baris `data: {...}`; teks diambil dari `candidates[0].content.parts[0].text`.

> **Keamanan**: input user disanitasi di `ChatbotRepository.sanitizeInput()` (maks 500 char + blokir pola prompt-injection) sebelum dikirim.

---

## ⚙️ Background Services

Aplikasi ini menggunakan service background untuk otomasi.

### Workmanager
Digunakan untuk fetch data cuaca secara periodik (setiap 1-4 jam) di background.

- **Task Name:** `weatherCheckTask`
- **Output:** Local Notifications (Jika ada cuaca ekstrem)

### Alarm Manager (via Local Notifications)
Digunakan untuk penjadwalan presisi.

- **Morning Briefing:** Pukul 06:00 WIB
- **Calendar Reminders:** Sesuai input user

---

## 📊 Rate Limits & Quotas

| API | Limit | Strategy |
|-----|-------|----------|
| **OpenWeather** | 60 calls/min | Cache 30 mins |
| **Nominatim** | 1 call/sec | Cache di Hive (Persistent) |
| **Supabase** | Bandwidth dependent | Cache Text Content |
| **Gemini** | Per tier API key | Sesi per percakapan, jawaban singkat |
| **Model Tomato** | Per host | Timeout 45s, 1 request per scan |


## 🔒 Data Privacy

Aplikasi ini menerapkan prinsip **Local First** untuk data pribadi pengguna.
- **Profil Pengguna (Nama & Foto)**: Disimpan **Hanya di Device** (via Hive). Tidak dikirim ke server manapun.
- **Lokasi**: Digunakan hanya untuk mengambil data cuaca, tidak dilacak atau disimpan di server remote.

*Dokumentasi ini terakhir diperbarui: Juni 2026*
