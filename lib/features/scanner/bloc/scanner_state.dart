import 'package:equatable/equatable.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();
  
  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {
  final String selectedPlantType;
  const ScannerInitial({this.selectedPlantType = 'Tomat'});

  @override
  List<Object?> get props => [selectedPlantType];
}

class ScannerLoading extends ScannerState {
  final String message;
  const ScannerLoading({this.message = 'Memproses...'});

  @override
  List<Object?> get props => [message];
}

class ScannerImagePicked extends ScannerState {
  final String imagePath;
  const ScannerImagePicked(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class ScannerSuccess extends ScannerState {
  final String imagePath;
  final String cloudImageUrl;
  final String label;
  final double confidence;
  final String plantType;
  final Map<String, dynamic>? pestData;
  final List<Map<String, dynamic>> recommendedDrugs;

  const ScannerSuccess({
    required this.imagePath,
    required this.cloudImageUrl,
    required this.label,
    required this.confidence,
    required this.plantType,
    this.pestData,
    this.recommendedDrugs = const [],
  });

  @override
  List<Object?> get props => [
        imagePath,
        cloudImageUrl,
        label,
        confidence,
        plantType,
        pestData,
        recommendedDrugs,
      ];
}

class ScannerError extends ScannerState {
  final String message;
  const ScannerError(this.message);

  @override
  List<Object?> get props => [message];
}
