# 🏃 Activity Diagram - Petani Maju

Dokumentasi **alur aktivitas / logika keputusan** (langkah-langkah & percabangan) untuk fitur utama Petani Maju.

---

## 📑 Daftar Isi

- [🏃 Activity Diagram - Petani Maju](#-activity-diagram---petani-maju)
  - [📑 Daftar Isi](#-daftar-isi)
  - [1. Scanner Penyakit Tanaman](#1-scanner-penyakit-tanaman)
  - [2. Chatbot Asisten Tani](#2-chatbot-asisten-tani)
  - [3. Riwayat Prediksi (Offline-First)](#3-riwayat-prediksi-offline-first)
  - [4. Refresh Cuaca](#4-refresh-cuaca)
  - [5. Pencarian Katalog Obat](#5-pencarian-katalog-obat)

---

## 1. Scanner Penyakit Tanaman

```mermaid
flowchart TD
    A([Mulai]) --> B[Pilih sumber gambar]
    B --> C{Gambar dipilih?}
    C -- Tidak --> Z([Batal])
    C -- Ya --> D[Upload ke Supabase Storage]
    D --> E{Upload sukses?}
    E -- Tidak --> ERR[Tampilkan error]
    E -- Ya --> F[POST ke MODEL_TOMATO/predict]
    F --> G{Prediksi sukses?}
    G -- Tidak --> ERR
    G -- Ya --> H[Map label ke nama penyakit]
    H --> I{Label = Sehat /<br/>Tidak Terdeteksi?}
    I -- Ya --> K[Lewati ambil detail]
    I -- Tidak --> J[Ambil detail dari penyakit_tomat]
    J --> K
    K --> L[Simpan ke prediction_history]
    L --> M[Tampilkan hasil:<br/>label, confidence, obat]
    M --> N([Selesai])
    ERR --> N
```

---

## 2. Chatbot Asisten Tani

```mermaid
flowchart TD
    A([User kirim pesan]) --> B[sanitizeInput]
    B --> C{Kosong / pola<br/>berbahaya?}
    C -- Ya --> R[Tolak / abaikan input]
    R --> Z([Selesai])
    C -- Tidak --> D[Potong maks 500 char]
    D --> E{Ada konteks<br/>cuaca?}
    E -- Ya --> F[Inject cuaca + hama aktif<br/>ke prompt]
    E -- Tidak --> G[Pakai teks user apa adanya]
    F --> H[Kirim ke Gemini streaming SSE]
    G --> H
    H --> I[Terima token bertahap]
    I --> J{Masih ada<br/>token?}
    J -- Ya --> K[Render ke StreamingText] --> I
    J -- Tidak --> L[Simpan jawaban ke histori]
    L --> Z
```

---

## 3. Riwayat Prediksi (Offline-First)

```mermaid
flowchart TD
    A([Buka Riwayat]) --> B[Panggil getHistory]
    B --> C[Fetch dari Supabase]
    C --> D{Sukses?}
    D -- Ya --> E[Simpan ke cache lokal]
    E --> F[Tampilkan data Supabase]
    D -- Tidak --> G[Baca cache lokal]
    G --> H{Cache ada?}
    H -- Ya --> I[Tampilkan data cache]
    H -- Tidak --> J[Tampilkan list kosong]
    F --> K([Selesai])
    I --> K
    J --> K
```

---

## 4. Refresh Cuaca

```mermaid
flowchart TD
    A([Tekan Refresh]) --> B{Offline Mode?}
    B -- Ya --> C[Tampilkan data cache] --> Z([Selesai])
    B -- Tidak --> D[Ambil GPS timeout 5s]
    D --> E{GPS dapat?}
    E -- Tidak --> F[Pakai koordinat cache]
    E -- Ya --> G[Pakai koordinat baru]
    F --> H[Fetch API cuaca timeout 10s]
    G --> H
    H --> I{Fetch sukses?}
    I -- Ya --> J[Update cache + UI]
    I -- Tidak --> K[Tampilkan pesan error]
    J --> Z
    K --> Z
```

---

## 5. Pencarian Katalog Obat

```mermaid
flowchart TD
    A([Buka Katalog Obat]) --> B[Load katalog_obat_tanaman.json]
    B --> C{File valid?}
    C -- Tidak --> ERR[Tampilkan pesan error]
    C -- Ya --> D[Tampilkan semua obat]
    D --> E{User cari /<br/>filter kategori?}
    E -- Tidak --> F[Tampilkan daftar penuh]
    E -- Ya --> G[Filter: nama / bahan aktif /<br/>sasaran / kategori]
    G --> H{Ada hasil?}
    H -- Ya --> I[Tampilkan hasil filter]
    H -- Tidak --> J[Tampilkan 'tidak ditemukan']
    F --> K{Pilih obat?}
    I --> K
    K -- Ya --> L[Buka detail:<br/>dosis, bahan aktif, cara pakai]
    K -- Tidak --> M([Selesai])
    L --> M
    J --> M
    ERR --> M
```

---
