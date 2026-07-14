import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/datasources/pest_scanner_service.dart';
import '../../../data/datasources/pest_services.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ImagePicker _picker = ImagePicker();
  final PestScannerService _scannerService = PestScannerService();
  final PestService _pestService = PestService();

  /// Hanya 3 jenis tanaman yang didukung model penyakit.
  static const List<String> supportedPlants = ['Tomat', 'Padi', 'Teh'];

  String _currentPlantType = 'Tomat';

  ScannerBloc() : super(const ScannerInitial()) {
    on<ScanWithSelectedPlant>(_onScanWithSelectedPlant);
    on<ScanWithAutoDetect>(_onScanWithAutoDetect);
    on<ResetScanner>(_onResetScanner);
    on<SetPlantType>(_onSetPlantType);
  }

  void _onSetPlantType(SetPlantType event, Emitter<ScannerState> emit) {
    if (!supportedPlants.contains(event.plantType)) return;
    _currentPlantType = event.plantType;
    emit(ScannerInitial(selectedPlantType: _currentPlantType));
  }

  // ─── Alur MANUAL ──────────────────────────────────────────────────────────
  Future<void> _onScanWithSelectedPlant(
      ScanWithSelectedPlant event, Emitter<ScannerState> emit) async {
    final imagePath = await _pickImage(event.source, emit);
    if (imagePath == null) return;

    await _analyzeDisease(
      emit,
      imagePath: imagePath,
      plantType: _currentPlantType,
    );
  }

  // ─── Alur AUTO (deteksi jenis tanaman dulu) ───────────────────────────────
  Future<void> _onScanWithAutoDetect(
      ScanWithAutoDetect event, Emitter<ScannerState> emit) async {
    final imagePath = await _pickImage(event.source, emit);
    if (imagePath == null) return;

    try {
      emit(const ScannerLoading(message: 'Mendeteksi jenis tanaman...'));

      final detection = await _scannerService.detectPlant(File(imagePath));
      final detectedPlant = detection['plant'] as String;
      final accepted = detection['accepted'] == true;

      if (!accepted || !supportedPlants.contains(detectedPlant)) {
        emit(const ScannerError(
            'Jenis tanaman tidak terdeteksi dengan jelas. Pastikan foto fokus pada daun tanaman, lalu coba foto ulang.'));
        return;
      }

      // Sinkronkan pilihan agar konsisten saat foto ulang.
      _currentPlantType = detectedPlant;

      await _analyzeDisease(
        emit,
        imagePath: imagePath,
        plantType: detectedPlant,
      );
    } catch (e) {
      emit(ScannerError('Gagal mendeteksi jenis tanaman: ${e.toString()}'));
    }
  }

  /// Ambil gambar; emit state perantara. Mengembalikan path atau null jika batal/gagal.
  Future<String?> _pickImage(
      ImageSource source, Emitter<ScannerState> emit) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;
      emit(ScannerImagePicked(image.path));
      return image.path;
    } catch (e) {
      emit(ScannerError('Gagal mengambil gambar: $e'));
      return null;
    }
  }

  /// Upload gambar, jalankan model penyakit sesuai [plantType], ambil detail,
  /// simpan histori, dan emit hasil.
  Future<void> _analyzeDisease(
    Emitter<ScannerState> emit, {
    required String imagePath,
    required String plantType,
  }) async {
    emit(const ScannerLoading(message: 'Menganalisis penyakit...'));

    try {
      // 1. Upload gambar ke Supabase Storage (untuk histori + dibutuhkan model Tomat)
      String cloudImageUrl;
      try {
        cloudImageUrl = await _pestService.uploadImage(imagePath);
        debugPrint('PestScanner: Image uploaded to $cloudImageUrl');
      } catch (e) {
        throw Exception('Gagal mengunggah gambar ke cloud storage: $e');
      }

      // 2. Jalankan model penyakit sesuai jenis tanaman
      final Map<String, dynamic> result =
          await _runDiseaseModel(plantType, imagePath, cloudImageUrl);

      final rawLabel = (result['label'] ?? 'Tidak Terdeteksi').toString();
      final confidence = (result['confidence'] ?? 0.0) as double;

      // 3. Map label model -> nama penyakit di DB
      final searchName = _mapLabelToSearchName(plantType, rawLabel);

      // 4. Ambil detail penyakit dari tabel sesuai tanaman
      Map<String, dynamic>? pestData;
      if (searchName != 'Sehat' && searchName != 'Tidak Terdeteksi') {
        pestData = await _pestService.fetchDiseaseDetailByName(
          plantType: plantType,
          name: searchName,
        );
      }

      final finalLabel =
          pestData != null ? pestData['nama_penyakit'] : searchName;

      // 5. Cari obat rekomendasi dari JSON
      List<Map<String, dynamic>> recommendedDrugs = [];
      if (finalLabel != 'Sehat' && finalLabel != 'Tidak Terdeteksi') {
        try {
          final jsonString = await rootBundle.loadString('katalog_obat_tanaman.json');
          final data = jsonDecode(jsonString) as List<dynamic>;
          
          final qPlant = plantType.toLowerCase();
          final qDisease = finalLabel.toLowerCase();
          final qSearchName = searchName.toLowerCase();
          final qRawLabel = rawLabel.toLowerCase();
          
          for (final item in data) {
            final drug = Map<String, dynamic>.from(item as Map<String, dynamic>);
            final sasaranRaw = drug['sasaran'];
            final tanamanRaw = drug['tanaman'];
            
            bool matchPlant = false;
            if (tanamanRaw is List) {
              matchPlant = tanamanRaw.any((t) => t.toString().toLowerCase().contains(qPlant));
            } else if (tanamanRaw != null) {
              matchPlant = tanamanRaw.toString().toLowerCase().contains(qPlant);
            }
            
            bool matchDisease = false;
            final sStr = sasaranRaw is List ? sasaranRaw.join(' ').toLowerCase() : sasaranRaw?.toString().toLowerCase() ?? '';
            
            if (sStr.contains(qDisease) || sStr.contains(qSearchName) || sStr.contains(qRawLabel) || qDisease.contains(sStr) || qSearchName.contains(sStr)) {
              matchDisease = true;
            } else {
              // Fallback: check overlapping words > 4 chars
              final sTokens = sStr.split(RegExp(r'[^a-z0-9]')).where((e) => e.length > 4);
              for (final t in sTokens) {
                if (qDisease.contains(t) || qSearchName.contains(t) || qRawLabel.contains(t)) {
                  matchDisease = true;
                  break;
                }
              }
            }

            if (matchPlant && matchDisease) {
              recommendedDrugs.add(drug);
            }
          }

          // Fallback: jika tidak ada obat yang cocok spesifik penyakit,
          // tampilkan obat yang relevan untuk jenis tanaman ini agar
          // rekomendasi tetap muncul saat penyakit terdeteksi.
          if (recommendedDrugs.isEmpty) {
            for (final item in data) {
              final drug = Map<String, dynamic>.from(item as Map<String, dynamic>);
              final tanamanRaw = drug['tanaman'];
              bool matchPlant = false;
              if (tanamanRaw is List) {
                matchPlant = tanamanRaw.any((t) => t.toString().toLowerCase().contains(qPlant));
              } else if (tanamanRaw != null) {
                matchPlant = tanamanRaw.toString().toLowerCase().contains(qPlant);
              }
              if (matchPlant) recommendedDrugs.add(drug);
            }
          }
        } catch (e) {
          debugPrint('Error loading recommended drugs: $e');
        }
      }

      // 6. Simpan histori
      await _pestService.savePredictionHistory({
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'image_url': cloudImageUrl,
        'plant_type': plantType,
        'disease': finalLabel,
        'confidence': confidence,
        'severity': 'Pending',
        'status': 'Success',
      });

      emit(ScannerSuccess(
        imagePath: imagePath,
        cloudImageUrl: cloudImageUrl,
        label: finalLabel,
        confidence: confidence,
        plantType: plantType,
        pestData: pestData,
        recommendedDrugs: recommendedDrugs,
      ));
    } catch (e) {
      emit(ScannerError('Terjadi kesalahan saat analisis: ${e.toString()}'));
    }
  }

  /// Pilih & jalankan model penyakit yang sesuai.
  /// Tomat memakai cloud URL (JSON); Padi & Teh memakai file lokal (multipart).
  Future<Map<String, dynamic>> _runDiseaseModel(
      String plantType, String imagePath, String cloudImageUrl) {
    switch (plantType) {
      case 'Padi':
        return _scannerService.predictRice(File(imagePath));
      case 'Teh':
        return _scannerService.predictTea(File(imagePath));
      case 'Tomat':
      default:
        return _scannerService.predictTomato(cloudImageUrl);
    }
  }

  // ─── Mapping label model -> nama_penyakit di Supabase ─────────────────────
  String _mapLabelToSearchName(String plantType, String label) {
    final normalized = label.trim().toLowerCase();

    // Healthy untuk semua tanaman
    if (normalized.contains('healthy') || normalized.contains('sehat')) {
      return 'Sehat';
    }

    switch (plantType) {
      case 'Padi':
        return _padiMapping[normalized] ?? label;
      case 'Teh':
        return _tehMapping[normalized] ?? label;
      case 'Tomat':
      default:
        return _tomatoMapping[label] ??
            label.replaceAll('Tomato_', '').replaceAll('_', ' ');
    }
  }

  // Tomat: label model PERSIS (case-sensitive) -> nama_penyakit
  static const Map<String, String> _tomatoMapping = {
    'Tomato_Bacterial_spot': 'Bacterial Spot (Bercak Bakteri)',
    'Tomato_Early_blight': 'Early Blight (Hawar Awal / Alternaria)',
    'Tomato_Late_blight': 'Late Blight (Hawar Lambat / Phytophthora)',
    'Tomato_Leaf_Mold': 'Leaf Mold (Jamur Daun)',
    'Tomato_Septoria_leaf_spot': 'Septoria Leaf Spot (Bercak Daun Septoria)',
    'Tomato_Spider_mites_Two_spotted_spider_mite':
        'Spider Mites (Tungau Laba-laba)',
    'Tomato_Target_Spot': 'Target Spot (Bercak Target)',
    'Tomato_Yellow_Leaf_Curl_Virus':
        'Tomato Yellow Leaf Curl Virus (Virus Kuning Keriting)',
    'Tomato_Mosaic_virus': 'Tomato Mosaic Virus (Virus Mosaik)',
  };

  // Padi: label model (lowercase) -> nama_penyakit
  static const Map<String, String> _padiMapping = {
    'brown spot': 'Brown Spot (Bercak Cokelat)',
    'leaf blast': 'Leaf Blast (Blas Daun)',
    'leaf scald': 'Leaf Scald (Gosong Daun / Hawar Pelepah Daun)',
    'narrow brown leaf spot': 'Narrow Brown Spot (Bercak Cokelat Sempit)',
    'narrow brown spot': 'Narrow Brown Spot (Bercak Cokelat Sempit)',
    'neck_blast': 'Neck Blast (Blas Leher / Patah Leher)',
    'neck blast': 'Neck Blast (Blas Leher / Patah Leher)',
    'rice hispa': 'Hispa (Hama Hispa Daun Padi)',
    'hispa': 'Hispa (Hama Hispa Daun Padi)',
    // 'bacterial leaf blight' & 'sheath blight' tidak punya detail di DB.
  };

  // Teh: label model (lowercase) -> nama_penyakit
  static const Map<String, String> _tehMapping = {
    'anthracnose': 'Anthracnose (Antraknosa)',
    'algal leaf': 'Algal Leaf Spot (Bercak Daun Alga)',
    'algal leaf spot': 'Algal Leaf Spot (Bercak Daun Alga)',
    'bird eye spot': 'Bird Eye Spot (Bercak Mata Burung)',
    'brown blight': 'Brown Blight (Hawar Cokelat)',
    'red leaf spot': 'Red Leaf Spot (Bercak Daun Merah)',
    // 'gray light' & 'white spot' tidak punya detail di DB.
  };

  void _onResetScanner(ResetScanner event, Emitter<ScannerState> emit) {
    emit(ScannerInitial(selectedPlantType: _currentPlantType));
  }
}
