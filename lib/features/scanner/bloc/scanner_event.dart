import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class ScannerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PickImage extends ScannerEvent {
  final ImageSource source;
  PickImage(this.source);

  @override
  List<Object?> get props => [source];
}

class RunInference extends ScannerEvent {
  final String imagePath;
  RunInference(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class ResetScanner extends ScannerEvent {}
