import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHistory extends HistoryEvent {}

class DeleteHistoryItem extends HistoryEvent {
  final String id;
  DeleteHistoryItem(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteAllHistory extends HistoryEvent {}
