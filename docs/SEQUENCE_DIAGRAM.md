# 🔄 Sequence Diagram - Petani Maju

Dokumentasi **interaksi antar komponen** (urutan pesan/waktu) untuk alur-alur utama aplikasi Petani Maju.

---

## 📑 Daftar Isi

- [🔄 Sequence Diagram - Petani Maju](#-sequence-diagram---petani-maju)
  - [📑 Daftar Isi](#-daftar-isi)
  - [1. Scanner Penyakit Tanaman (AI)](#1-scanner-penyakit-tanaman-ai)
  - [2. Chatbot Asisten Tani (Gemini)](#2-chatbot-asisten-tani-gemini)
  - [3. Riwayat Prediksi (Offline-First)](#3-riwayat-prediksi-offline-first)
  - [4. Refresh Cuaca](#4-refresh-cuaca)
  - [5. Startup Aplikasi](#5-startup-aplikasi)

---

## 1. Scanner Penyakit Tanaman (AI)

Alur dari user memilih foto sampai hasil tersimpan ke riwayat.

```mermaid
sequenceDiagram
    actor User
    participant UI as ScannerScreen
    participant Bloc as ScannerBloc
    participant Pest as PestService
    participant Store as Supabase Storage
    participant Model as PestScannerService
    participant API as MODEL_TOMATO API
    participant DB as Supabase DB

    User->>UI: Pilih foto (kamera/galeri)
    UI->>Bloc: PickImage(source)
    Bloc->>Bloc: emit ScannerImagePicked
    Bloc->>Bloc: add RunInference(path)
    Bloc->>Bloc: emit ScannerLoading

    Bloc->>Pest: uploadImage(path)
    Pest->>Store: upload images/history/{ts}.jpg
    Store-->>Pest: public URL
    Pest-->>Bloc: cloudImageUrl

    Bloc->>Model: predict(cloudImageUrl)
    Model->>API: POST /predict {image_url}
    API-->>Model: { label, confidence% }
    Model-->>Bloc: { label, confidence(0-1) }

    Bloc->>Bloc: _mapLabelToSearchName(label)
    alt Bukan "Sehat"/"Tidak Terdeteksi"
        Bloc->>Pest: fetchTomatoDiseaseByName(searchName)
        Pest->>DB: select penyakit_tomat ilike nama_penyakit
        DB-->>Pest: detail (deskripsi, penanganan, obat)
        Pest-->>Bloc: pestData
    end

    Bloc->>Pest: savePredictionHistory({disease, confidence, ...})
    Pest->>DB: insert prediction_history
    DB-->>Pest: ok

    Bloc->>UI: emit ScannerSuccess(label, confidence, pestData)
    UI-->>User: Tampil hasil + rekomendasi obat
```

> ⚠️ Jika upload/predict gagal → `ScannerError`. Penyimpanan history dibungkus try-catch (gagal simpan tidak menggagalkan tampilan hasil).

---

## 2. Chatbot Asisten Tani (Gemini)

Alur pengiriman pesan dengan respons **streaming** dan konteks cuaca.

```mermaid
sequenceDiagram
    actor User
    participant UI as ChatbotScreen
    participant Bloc as ChatbotBloc
    participant Repo as ChatbotRepository
    participant Svc as ChatbotService
    participant Gemini as Gemini API
    participant Cache as CacheService

    User->>UI: Ketik pesan + kirim
    UI->>Bloc: SendMessage(text)
    Bloc->>Repo: sanitizeInput(text)
    alt Input berbahaya / kosong
        Repo-->>Bloc: "" (ditolak)
        Bloc-->>UI: abaikan / pesan error
    else Input valid
        Repo-->>Bloc: text bersih (maks 500 char)
        Bloc->>Repo: sendMessage(text, currentWeather)
        Repo->>Cache: getCachedPests()
        Cache-->>Repo: daftar hama aktif
        Repo->>Repo: _buildContextualPrompt (cuaca + hama)
        Repo->>Svc: sendMessageStream(prompt)
        Svc->>Gemini: POST streamGenerateContent (SSE)
        loop Tiap chunk SSE
            Gemini-->>Svc: data: { ...text }
            Svc-->>Bloc: yield token
            Bloc-->>UI: update StreamingText
        end
        Svc->>Svc: simpan jawaban ke _history
        UI-->>User: Jawaban lengkap
    end
```

---

## 3. Riwayat Prediksi (Offline-First)

Alur memuat riwayat: Supabase dulu, fallback cache.

```mermaid
sequenceDiagram
    actor User
    participant UI as HistoryScreen
    participant Bloc as HistoryBloc
    participant Repo as HistoryRepository
    participant Pest as PestService
    participant DB as Supabase DB
    participant Cache as CacheService

    User->>UI: Buka halaman Riwayat
    UI->>Bloc: LoadHistory
    Bloc->>Repo: getHistory()
    Repo->>Pest: fetchPredictionHistory()
    Pest->>DB: select prediction_history order created_at desc

    alt Sukses (online)
        DB-->>Pest: rows
        Pest-->>Repo: list
        Repo->>Cache: saveRawData(cache, json)
        Repo-->>Bloc: items
    else Gagal (offline/error)
        Repo->>Cache: getRawData(cache)
        Cache-->>Repo: json tersimpan
        Repo-->>Bloc: items (dari cache)
    end

    Bloc-->>UI: emit HistoryLoaded(items)
    UI-->>User: Tampil daftar riwayat
```

---

## 4. Refresh Cuaca

```mermaid
sequenceDiagram
    actor User
    participant UI as HomeScreen
    participant Bloc as HomeBloc
    participant Repo as WeatherRepository
    participant Geo as Geolocator
    participant API as OpenWeatherMap
    participant Cache as CacheService

    User->>UI: Tekan Refresh
    UI->>Bloc: RefreshWeather
    Bloc->>Cache: getOfflineMode()
    alt Offline Mode aktif
        Bloc->>Cache: getCachedCurrentWeather()
        Cache-->>Bloc: data cache
    else Online
        Bloc->>Geo: getCurrentPosition (timeout 5s)
        alt GPS gagal
            Geo-->>Bloc: error → pakai koordinat cache
        else
            Geo-->>Bloc: lat/lon
        end
        Bloc->>Repo: fetchWeather(lat, lon)
        Repo->>API: GET /weather + /forecast (timeout 10s)
        alt Sukses
            API-->>Repo: data cuaca
            Repo->>Cache: saveWeatherData(...)
            Repo-->>Bloc: data baru
        else Gagal
            Repo-->>Bloc: error → tampil pesan
        end
    end
    Bloc-->>UI: update UI
```

---

## 5. Startup Aplikasi

```mermaid
sequenceDiagram
    participant Main as main()
    participant Env as dotenv
    participant Cache as CacheService
    participant Notif as NotificationService
    participant BG as BackgroundService
    participant SB as Supabase

    Main->>Env: load .env
    Main->>Cache: init() (buka Hive box terenkripsi)
    Main->>Notif: init()
    Main->>BG: init() (mobile saja)
    Main->>SB: initialize(url, anonKey) timeout 10s
    alt Timeout / error
        SB-->>Main: TimeoutException
        Main->>Cache: setOfflineMode(true)
        Note over Main: appStartedOffline = true
    else Sukses
        SB-->>Main: ready
    end
    Main->>Main: runApp(MainApp)
```

---
