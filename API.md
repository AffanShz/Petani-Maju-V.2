# 🔌 Dokumentasi API - Petani Maju

Dokumentasi lengkap tentang API dan service yang digunakan pada aplikasi Petani Maju.

> ⚠️ **PENTING**: Jangan pernah commit API Key asli ke repository publik. Gunakan file `.env` untuk menyimpan kunci rahasia.

---

## 📑 Daftar Isi

- [Environment Variables](#environment-variables)
- [OpenWeatherMap API](#openweathermap-api)
- [OpenStreetMap Nominatim](#openstreetmap-nominatim)
- [Supabase API](#supabase-api)
- [Background Services](#background-services)

---

## 🔐 Environment Variables

Aplikasi ini memerlukan konfigurasi file `.env` di root project:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
OPENWEATHER_API_KEY=your-openweather-api-key
```

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

Backend as a Service (BaaS) untuk database Tips Pertanian.

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

### Query Example (Dart)

```dart
final response = await supabase
    .from('tips')
    .select()
    .order('created_at', ascending: false);
```

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


## 🔒 Data Privacy

Aplikasi ini menerapkan prinsip **Local First** untuk data pribadi pengguna.
- **Profil Pengguna (Nama & Foto)**: Disimpan **Hanya di Device** (via Hive). Tidak dikirim ke server manapun.
- **Lokasi**: Digunakan hanya untuk mengambil data cuaca, tidak dilacak atau disimpan di server remote.

*Dokumentasi ini terakhir diperbarui: Januari 2026*
