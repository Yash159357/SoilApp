part of 'history_bloc.dart';

@immutable
abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<SoilReading> readings;

  HistoryLoaded(this.readings);
}

class HistoryError extends HistoryState {
  final String message;

  HistoryError(this.message);
}