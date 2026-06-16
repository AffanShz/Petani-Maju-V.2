import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/datasources/pest_scanner_service.dart';
import '../../../data/datasources/pest_services.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ImagePicker _picker = ImagePicker();
  final PestScannerService _scannerService = PestScannerService();
  final PestService _pestService = PestService();

  String _currentPlantType = 'Tomat';

  ScannerBloc() : super(ScannerInitial()) {
    on<PickImage>(_onPickImage);
    on<RunInference>(_onRunInference);
    on<ResetScanner>(_onResetScanner);
    on<SetPlantType>(_onSetPlantType);
  }

  void _onSetPlantType(SetPlantType event, Emitter<ScannerState> emit) {
    _currentPlantType = event.plantType;
    emit(ScannerInitial(selectedPlantType: _currentPlantType));
  }

  Future<void> _onPickImage(PickImage event, Emitter<ScannerState> emit) async {
    try {
      final XFile? image = await _picker.pickImage(source: event.source);
      if (image != null) {
        emit(ScannerImagePicked(image.path));
        // Secara otomatis jalankan inferensi setelah gambar dipilih
        add(RunInference(image.path, plantType: _currentPlantType));
      }
    } catch (e) {
      emit(ScannerError('Gagal mengambil gambar: $e'));
    }
  }

  Future<void> _onRunInference(
      RunInference event, Emitter<ScannerState> emit) async {
    emit(ScannerLoading(message: 'Menganalisis gambar dengan AI...'));

    try {
      // 1. Upload gambar ke Supabase Storage (Bucket: images/history)
      String cloudImageUrl;
      try {
        cloudImageUrl = await _pestService.uploadImage(event.imagePath);
        debugPrint('PestScanner: Image uploaded successfully to $cloudImageUrl');
      } catch (e) {
        throw Exception('Gagal mengunggah gambar ke cloud storage: $e');
      }

      // 2. Jalankan prediksi AI menggunakan URL cloud
      final result = await _scannerService.predict(cloudImageUrl);

      final label = result['label'] ?? 'Tidak Terdeteksi';
      final confidence = (result['confidence'] ?? 0.0) as double;
      final plantType = event.plantType;

      // 3. Simpan histori ke Supabase (Tabel: prediction_history)
      await _pestService.savePredictionHistory({
        'user_id': null,
        'image_url': cloudImageUrl,
        'plant_type': plantType,
        'disease': label,
        'confidence': confidence,
        'severity': 'Pending',
        'status': 'Success',
      });

      emit(ScannerSuccess(
        imagePath: event.imagePath,
        cloudImageUrl: cloudImageUrl,
        label: label,
        confidence: confidence,
        plantType: plantType,
      ));
    } catch (e) {
      emit(ScannerError('Terjadi kesalahan saat analisis: ${e.toString()}'));
    }
  }

  void _onResetScanner(ResetScanner event, Emitter<ScannerState> emit) {
    emit(ScannerInitial(selectedPlantType: _currentPlantType));
  }
}
