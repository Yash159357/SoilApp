part of 'history_bloc.dart';

@immutable
abstract class HistoryEvent {}

class FetchHistory extends HistoryEvent {
  final int? limit;
  final DateTime? startDate;
  final DateTime? endDate;

  FetchHistory({this.limit, this.startDate, this.endDate});
}