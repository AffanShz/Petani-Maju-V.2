import 'package:equatable/equatable.dart';

abstract class ScannerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {}

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
  final String label;
  final double confidence;
  final Map<String, dynamic>? pestData;

  ScannerSuccess({
    required this.imagePath,
    required this.label,
    required this.confidence,
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
