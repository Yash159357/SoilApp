import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/services/firebase_service.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final FirebaseService _firebaseService;

  HistoryBloc(this._firebaseService) : super(HistoryInitial()) {
    on<FetchHistory>(_onFetchHistory);
  }

  Future<void> _onFetchHistory(
      FetchHistory event,
      Emitter<HistoryState> emit,
      ) async {
    emit(HistoryLoading());
    try {
      final readings = await _firebaseService.getUserSoilReadings(
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(HistoryLoaded(readings));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}