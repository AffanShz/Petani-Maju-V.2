import 'package:equatable/equatable.dart';

abstract class ScannerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {
  final String selectedPlantType;
  ScannerInitial({this.selectedPlantType = 'Tomat'});

  @override
  List<Object?> get props => [selectedPlantType];
}

class ScannerLoading extends ScannerState {
  final String message;
  ScannerLoading({this.message = 'Memproses...'});

  @override
  List<Object?> get props => [message];
}

class ScannerImagePicked extends ScannerState {
  final String imagePath;
  ScannerImagePicked(this.imagePath);

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

  ScannerSuccess({
    required this.imagePath,
    required this.cloudImageUrl,
    required this.label,
    required this.confidence,
    required this.plantType,
  });

  @override
  List<Object?> get props => [imagePath, cloudImageUrl, label, confidence, plantType];
    this.pestData,
  });

  @override
  List<Object?> get props => [imagePath, label, confidence, pestData];
}

class ScannerError extends ScannerState {
  final String message;
  ScannerError(this.message);

  @override
  List<Object?> get props => [message];
}
