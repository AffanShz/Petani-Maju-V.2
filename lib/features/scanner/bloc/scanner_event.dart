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
  final String plantType;
  RunInference(this.imagePath, {this.plantType = 'Tomat'});

  @override
  List<Object?> get props => [imagePath, plantType];
}

class ResetScanner extends ScannerEvent {}

class SetPlantType extends ScannerEvent {
  final String plantType;
  SetPlantType(this.plantType);

  @override
  List<Object?> get props => [plantType];
}
