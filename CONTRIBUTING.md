# 🤝 Panduan Kontribusi - AgriNova

Terima kasih telah tertarik untuk berkontribusi ke proyek AgriNova! Panduan ini akan membantu Anda memahami standar kode dan arsitektur baru kami.

---

## 📑 Daftar Isi

- [Getting Started](#getting-started)
- [Architecture Overview](#architecture-overview)
- [Coding Standards (BLoC)](#coding-standards-bloc)
- [Folder Structure](#folder-structure)
- [Git Workflow](#git-workflow)
- [Pull Request Guidelines](#pull-request-guidelines)

---

## 🚀 Getting Started

### Prerequisites

Pastikan Anda sudah menginstall:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.0.0
- [Dart SDK](https://dart.dev/get-dart) >= 3.0.0
- Device Android/iOS atau Emulator

### Setup Dependencies

Aplikasi ini menggunakan banyak package untuk arsitektur BLoC dan background service.

```bash
flutter pub get
```

---

## 🏗️ Architecture Overview

Project ini menggunakan **Feature-First Clean Architecture** dengan **BLoC Pattern**.

### Layer Separation
1. **Presentation (UI)**: Screens, Widgets. Hanya berisi UI Logic.
2. **Business Logic (BLoC)**: Menangani state management dan event handling.
3. **Domain/Data (Repository)**: Menangani pengambilan data (API/Cache) dan error handling.
4. **Data Source**: Melakukan request raw ke API atau Local DB.

---

## 💻 Coding Standards (BLoC)

### BLoC Naming Convention

```dart
// Event
abstract class WeatherEvent {}
class LoadWeather extends WeatherEvent {}

// State
abstract class WeatherState {}
class WeatherInitial extends WeatherState {}
class WeatherLoaded extends WeatherState {
  final WeatherData data;
  WeatherLoaded(this.data);
}

// BLoC
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> { ... }
```

### State Management Guidelines
1. **Event Driven**: UI hanya mengirim Event (`context.read<Bloc>().add(Event)`).
2. **State driven UI**: UI me-rebuild berdasarkan State (`BlocBuilder`).
3. **Side Effects**: Gunakan `BlocListener` untuk navigasi, snackbar, atau dialog.
4. **Dependency Injection**: Gunakan `RepositoryProvider` di root level (`main.dart`).

---

## 📂 Folder Structure

Struktur folder mengikuti pola Feature-First. Setiap fitur memiliki folder sendiri yang mandiri.

```
lib/
├── core/                   # Shared logic (constants, services, theme)
│   ├── services/           # Implementation of external services
│   └── constants/          # App-wide constants (colors, api keys)
├── data/
│   ├── datasources/        # Raw Data Providers (API Client, Hive Box)
│   ├── repositories/       # Abstraction Layer
│   └── models/             # Data Classes (fromJson/toJson)
├── features/               # Feature Modules
│   ├── home/
│   │   ├── bloc/           # HomeBloc, HomeEvent, HomeState
│   │   ├── screens/        # Pages related to Home
│   │   └── widgets/        # Widgets specific to Home
│   ├── calendar/
│   │   └── bloc/
│   └── ...
└── widgets/                # Global Reusable Widgets
```

### Menambah Fitur Baru
Jika Anda membuat fitur baru (misal: `marketplace`), buat folder baru di `features/marketplace` dengan struktur:

```
features/marketplace/
├── bloc/
│   ├── marketplace_bloc.dart
│   ├── marketplace_event.dart
│   └── marketplace_state.dart
├── screens/
│   └── marketplace_screen.dart
└── widgets/
    └── product_card.dart
```

---

## 🔀 Git Workflow

### Branch Strategy
- `main`: Production-ready code.
- `develop`: Development branch utama.
- `feature/nama-fitur`: Branch untuk pengembangan fitur.

### Commit Messages
Gunakan semantic commit messages:
- `feat`: Fitur baru (e.g., `feat: add background service`)
- `fix`: Bug fix (e.g., `fix: calendar notification parsing`)
- `refactor`: Perubahan kode tanpa ubah fitur (e.g., `refactor: migrate home to bloc`)
- `docs`: Update dokumentasi
- `style`: Formatting, missing semi colons, etc

---

## 🧪 Testing

Pastikan untuk menjalankan test sebelum submit PR.

```bash
# Unit Tests
flutter test

# Integration Tests (coming soon)
```

---

## 🐛 Reporting Issues

Gunakan template issue yang tersedia di GitHub untuk melaporkan bug atau request fitur. Sertakan:
- Langkah reproduksi
- Expected behavior
- Screenshot (jika ada)
- Versi OS/Device

---

*Terima kasih telah berkontribusi!* 🚀
