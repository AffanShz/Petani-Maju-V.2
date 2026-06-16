import 'package:equatable/equatable.dart';
import '../../../data/models/prediction_history.dart';

abstract class HistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<PredictionHistory> items;
  const HistoryLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
