# Activity Diagram - Petani Maju

Dokumentasi **alur aktivitas / logika keputusan** (langkah-langkah & percabangan) untuk fitur utama Petani Maju.

---

## Daftar Isi

- [1. App Startup & Inisialisasi](#1-app-startup--inisialisasi)
- [2. Autentikasi (Login / Register / Reset Password)](#2-autentikasi-login--register--reset-password)
- [3. Scanner Penyakit Tanaman](#3-scanner-penyakit-tanaman)
- [4. Chatbot Asisten Tani](#4-chatbot-asisten-tani)
- [5. Riwayat Prediksi (Offline-First)](#5-riwayat-prediksi-offline-first)
- [6. Refresh Cuaca](#6-refresh-cuaca)
- [7. Pencarian Katalog Obat](#7-pencarian-katalog-obat)
- [8. Home Screen](#8-home-screen)
- [9. Katalog Hama (Pencarian & Filter)](#9-katalog-hama-pencarian--filter)
- [10. Kalender & Jadwal Tanam](#10-kalender--jadwal-tanam)
- [11. Settings & Profil](#11-settings--profil)

---

## 1. App Startup & Inisialisasi

```mermaid
flowchart TD
    A([Buka App]) --> B[EasyLocalization init]
    B --> C[dotenv.load .env]
    C --> D[CacheService.init + NotificationService.init]
    D --> E{Platform mobile?}
    E -- Ya --> F[BackgroundService.init]
    E -- Tidak --> G[Skip BackgroundService]
    F --> H[ConnectivityService.init async]
    G --> H
    H --> I[initializeDateFormatting id_ID]
    I --> J[Supabase.initialize timeout 10s]
    J --> K{Berhasil?}
    K -- Ya --> L[appStartedOffline = false]
    K -- Timeout / Error --> M[appStartedOffline = true\nCacheService.setOfflineMode true]
    L --> N{Supabase session ada?}
    M --> N
    N -- Ya --> O[Tampilkan MainNavBar]
    N -- Tidak --> P{Onboarding sudah dilihat?}
    P -- Tidak --> Q[Tampilkan OnboardingScreen]
    P -- Ya --> R[Tampilkan LoginScreen]
    Q --> R
    O --> Z([Selesai])
    R --> Z
```

---

## 2. Autentikasi (Login / Register / Reset Password)

```mermaid
flowchart TD
    A([Buka halaman Auth]) --> B{Aksi user?}

    B -- Login --> C[AuthSignInRequested\nemail + password]
    C --> D[emit AuthLoading]
    D --> E[authRepository.signIn via Supabase]
    E --> F{Berhasil?}
    F -- Ya --> G[emit AuthSuccess]
    F -- Tidak --> H[parseError]
    H --> I[emit AuthFailure message]
    G --> NAV[Navigasi ke MainNavBar]

    B -- Register --> J[AuthSignUpRequested\nemail + password + fullName]
    J --> K[emit AuthLoading]
    K --> L[authRepository.signUp via Supabase]
    L --> M{session null?\nperlu konfirmasi email}
    M -- Ya --> N[emit AuthFailure isInfo=true\nInfo cek email]
    M -- Tidak --> G

    B -- Reset Password --> O[AuthResetPasswordRequested email]
    O --> P[emit AuthLoading]
    P --> Q[authRepository.resetPassword]
    Q --> R{Berhasil?}
    R -- Ya --> S[emit AuthResetPasswordSent]
    R -- Tidak --> H

    B -- Logout --> T[AuthSignOutRequested]
    T --> U[emit AuthLoading]
    U --> V[authRepository.signOut]
    V --> W[emit AuthInitial]
    W --> X[Kembali ke LoginScreen]

    NAV --> Z([Selesai])
    I --> Z
    N --> Z
    S --> Z
    X --> Z
```

---

## 3. Scanner Penyakit Tanaman

```mermaid
flowchart TD
    A([Buka Scanner]) --> B{Mode scan?}

    B -- Manual\nPilih tanaman --> C[ScanWithSelectedPlant\nplantType = pilihan user]
    B -- Auto-detect --> D[ScanWithAutoDetect]

    C --> PICK[Ambil gambar kamera / galeri]
    D --> PICK

    PICK --> E{Gambar dipilih?}
    E -- Tidak --> Z([Batal])
    E -- Ya --> F[emit ScannerImagePicked]

    F --> G{Mode Auto?}
    G -- Ya --> H[emit Loading: Mendeteksi jenis tanaman]
    H --> I[scannerService.detectPlant]
    I --> J{Tanaman terdeteksi\n& didukung?}
    J -- Tidak --> ERR[emit ScannerError]
    J -- Ya --> K[Gunakan plantType hasil deteksi]

    G -- Tidak --> K

    K --> L[emit Loading: Menganalisis penyakit]
    L --> M[Upload gambar ke Supabase Storage]
    M --> N{Upload sukses?}
    N -- Tidak --> ERR

    N -- Ya --> O{plantType?}
    O -- Tomat --> P[predictTomato cloudImageUrl]
    O -- Padi --> Q[predictRice File lokal]
    O -- Teh --> R[predictTea File lokal]

    P --> S[Terima rawLabel + confidence]
    Q --> S
    R --> S

    S --> T[mapLabelToSearchName]
    T --> U{Label = Sehat /\nTidak Terdeteksi?}
    U -- Ya --> V[Lewati fetch detail DB]
    U -- Tidak --> W[fetchDiseaseDetailByName\nsesuai tabel tanaman]
    W --> V

    V --> X[Cari obat dari katalog_obat_tanaman.json\nmatch plant + penyakit]
    X --> Y{Obat spesifik\nditemukan?}
    Y -- Tidak --> Y2[Fallback: obat untuk jenis\ntanaman saja]
    Y -- Ya --> AA
    Y2 --> AA

    AA[savePredictionHistory ke Supabase] --> BB[emit ScannerSuccess\nlabel, confidence, plantType,\npestData, recommendedDrugs]
    BB --> CC([Selesai])
    ERR --> CC
```

---

## 4. Chatbot Asisten Tani

```mermaid
flowchart TD
    A([User kirim pesan]) --> B[sanitizeInput]
    B --> C{Kosong / pola\nberbahaya?}
    C -- Ya --> R[Tolak / abaikan input]
    R --> Z([Selesai])
    C -- Tidak --> D[Potong maks 500 char]
    D --> E{Ada konteks\ncuaca?}
    E -- Ya --> F[Inject cuaca + hama aktif\nke prompt]
    E -- Tidak --> G[Pakai teks user apa adanya]
    F --> H[Kirim ke Gemini streaming SSE]
    G --> H
    H --> I[Terima token bertahap]
    I --> J{Masih ada\ntoken?}
    J -- Ya --> K[Render ke StreamingText] --> I
    J -- Tidak --> L[Simpan jawaban ke histori]
    L --> Z
```

---

## 5. Riwayat Prediksi (Offline-First)

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

## 6. Refresh Cuaca

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

## 7. Pencarian Katalog Obat

```mermaid
flowchart TD
    A([Buka Katalog Obat]) --> B[Load katalog_obat_tanaman.json]
    B --> C{File valid?}
    C -- Tidak --> ERR[Tampilkan pesan error]
    C -- Ya --> D[Tampilkan semua obat]
    D --> E{User cari /\nfilter kategori?}
    E -- Tidak --> F[Tampilkan daftar penuh]
    E -- Ya --> G[Filter: nama / bahan aktif /\nsasaran / kategori]
    G --> H{Ada hasil?}
    H -- Ya --> I[Tampilkan hasil filter]
    H -- Tidak --> J[Tampilkan 'tidak ditemukan']
    F --> K{Pilih obat?}
    I --> K
    K -- Ya --> L[Buka detail:\ndosis, bahan aktif, cara pakai]
    K -- Tidak --> M([Selesai])
    L --> M
    J --> M
    ERR --> M
```

---

## 8. Home Screen

```mermaid
flowchart TD
    A([Buka HomeScreen]) --> B[Request notification permissions]
    B --> C[dispatch LoadHomeData]
    C --> D[emit HomeLoading]
    D --> E[Fetch cuaca + tips dari API]
    E --> F{Fetch sukses?}
    F -- Ya --> G[emit HomeLoaded]
    F -- Tidak --> H{Cache ada?}
    H -- Ya --> I[Tampilkan data cache + snackbar offline]
    H -- Tidak --> J[emit HomeError]
    I --> G
    G --> K[Tampilkan weather card + forecast + tips + quick access]
    K --> L{Aksi user?}
    L -- Tap weather card --> M[Navigasi ke WeatherDetailScreen]
    L -- Tap FAB chatbot --> N[Buka ChatbotScreen]
    L -- Pull to refresh --> O[dispatch RefreshHomeData]
    O --> D
    L -- Tap tip item --> P[Navigasi ke TipsDetailScreen]
    L -- Tap quick access --> Q[Navigasi ke fitur terkait]
    J --> R[Tampilkan error + tombol Coba Lagi]
    R --> S[User tap retry]
    S --> C
    M --> Z([Selesai])
    N --> Z
    P --> Z
    Q --> Z
```

---

## 9. Katalog Hama (Pencarian & Filter)

```mermaid
flowchart TD
    A([Buka PestScreen]) --> B[dispatch LoadPests]
    B --> C[emit PestLoading]
    C --> D[PestService.fetchPests dari Supabase]
    D --> E{Fetch sukses?}
    E -- Ya --> F[emit PestLoaded + filteredPests]
    E -- Tidak --> G[emit PestError]
    F --> H[Tampilkan list kartu hama + search bar + chip kategori]
    H --> I{Aksi user?}
    I -- Ketik search --> J[Debounce 500ms\ndispatch SearchPests query]
    J --> K[Filter: ilike nama hama]
    K --> L{Ada hasil?}
    L -- Ya --> M[Update filteredPests]
    L -- Tidak --> N[Tampilkan tidak ditemukan]
    I -- Pilih kategori chip --> O[dispatch FilterPestsByCategory]
    O --> M
    I -- Pull to refresh --> P[dispatch RefreshPests]
    P --> C
    I -- Tap kartu hama --> Q[Navigasi ke PestDetailScreen]
    Q --> R[Tampilkan: gambar hero, badge kategori,\nnama, deskripsi, ciri-ciri, dampak]
    R --> S[User tap tombol Cara Mengatasi]
    S --> T[Tampilkan bottom sheet\nsolusi pengendalian]
    G --> U[Tampilkan error + tombol Coba Lagi]
    U --> V[User tap retry]
    V --> B
    T --> Z([Selesai])
    N --> Z
```

---

## 10. Kalender & Jadwal Tanam

```mermaid
flowchart TD
    A([Buka CalendarScreen]) --> B[dispatch LoadSchedules]
    B --> C[emit CalendarLoading]
    C --> D[Fetch jadwal dari Supabase]
    D --> E{Fetch sukses?}
    E -- Ya --> F[emit CalendarLoaded\nReschedule notifikasi untuk jadwal masa depan]
    E -- Tidak --> G[emit CalendarError]
    F --> H[Tampilkan kalender + daftar acara hari ini\n+ rekomendasi aktivitas bulanan]
    H --> I{Aksi user?}
    I -- Tap tanggal --> J[dispatch SelectDate]
    J --> K[Update daftar acara di bawah kalender]
    I -- Navigasi bulan --> L[dispatch PageChanged]
    L --> M[Update kartu rekomendasi bulanan]
    I -- Tap FAB / edit --> N[Tampilkan bottom sheet dialog\nnama tanaman, catatan, waktu tanam]
    N --> O{Tambah baru?}
    O -- Ya --> P[dispatch AddSchedule]
    O -- Tidak --> Q[dispatch UpdateSchedule]
    P --> R[Jadwalkan 3 notifikasi lokal:\nwaktu tanam, 1 jam sebelum, 1 hari sebelum]
    Q --> R
    R --> S[emit CalendarScheduleAdded/Updated\n+ SnackBar sukses]
    I -- Tap hapus --> T[Dialog konfirmasi hapus]
    T --> U[dispatch DeleteSchedule]
    U --> V[Batalkan 3 notifikasi terkait]
    V --> W[emit CalendarOperationSuccess]
    G --> X[Tampilkan error + tombol Coba Lagi]
    X --> Y[User tap retry]
    Y --> B
    K --> Z([Selesai])
    M --> Z
    S --> Z
    W --> Z
```

---

## 11. Settings & Profil

```mermaid
flowchart TD
    A([Buka SettingsScreen]) --> B[Load profil dari CacheService]
    B --> C[Tampilkan menu settings]
    C --> D{Aksi user?}

    D -- Tap Profil --> E[Navigasi ke ProfileScreen]
    E --> F[Load profil: nama + foto]
    F --> G{Aksi user?}
    G -- Tap avatar --> H[ImagePicker: pilih dari galeri]
    G -- Edit nama --> I[Input nama baru]
    G -- Tap Simpan --> J[CacheService.saveUserProfile]
    J --> K[Pop dengan result true]
    K --> L[Refresh profil di SettingsScreen]

    D -- Tap Notifikasi --> M[Buka NotificationSettingsScreen]
    D -- Tap Bahasa --> N[Modal pilih bahasa\nid / en via easy_localization]
    N --> O[Set locale + restart app]
    D -- Toggle Offline Mode --> P[_toggleOfflineMode]
    P --> Q[CacheService.setOfflineMode value]
    Q --> R[Update UI toggle]

    D -- Tap Bantuan --> S[Buka HelpSupportScreen]
    D -- Tap Tentang --> T[Buka AboutAppScreen]

    D -- Tap Logout --> U[Dialog konfirmasi]
    U --> V[Supabase.auth.signOut]
    V --> W[dispatch AppLoggedOut ke AppBloc]
    W --> X[Navigasi ke LoginScreen]

    L --> Z([Selesai])
    M --> Z
    O --> Z
    R --> Z
    S --> Z
    T --> Z
    X --> Z
```

---
