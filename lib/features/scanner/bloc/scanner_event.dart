import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class ScannerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Alur MANUAL: ambil gambar lalu langsung jalankan model penyakit
/// sesuai jenis tanaman yang sedang dipilih user.
class ScanWithSelectedPlant extends ScannerEvent {
  final ImageSource source;
  ScanWithSelectedPlant(this.source);

  @override
  List<Object?> get props => [source];
}

/// Alur AUTO: ambil gambar, deteksi jenis tanaman dulu (MODEL_PLANT),
/// lalu jalankan model penyakit sesuai hasil deteksi.
class ScanWithAutoDetect extends ScannerEvent {
  final ImageSource source;
  ScanWithAutoDetect(this.source);

  @override
  List<Object?> get props => [source];
}

class ResetScanner extends ScannerEvent {}

class SetPlantType extends ScannerEvent {
  final String plantType;
  SetPlantType(this.plantType);

  @override
  List<Object?> get props => [plantType];
}
