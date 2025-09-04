import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/models/soil_device.dart';
import 'package:soil_app/services/bluetooth_service.dart';
import 'package:soil_app/services/firebase_service.dart';

part 'soil_reading_event.dart';
part 'soil_reading_state.dart';

class SoilReadingBloc extends Bloc<SoilReadingEvent, SoilReadingState> {
  final BluetoothService _bluetoothService;
  final FirebaseService _firebaseService;
  StreamSubscription<SoilReading>? _readingSubscription;

  SoilReadingBloc(this._bluetoothService, this._firebaseService)
      : super(ReadingInitial()) {
    on<FetchReading>(_onFetchReading);
    on<ConnectToDevice>(_onConnectToDevice);
    on<UseMockDevice>(_onUseMockDevice);
    on<DisconnectDevice>(_onDisconnectDevice);

    // Listen to Bluetooth reading stream
    _bluetoothService.readingsStream.listen((reading) {
      if (state is! ReadingLoading) {
        add(FetchReading(useMockData: false));
      }
    });
  }


  Future<void> _onFetchReading(
      FetchReading event,
      Emitter<SoilReadingState> emit,
      ) async {
    emit(ReadingLoading());
    try {
      SoilReading reading;
      bool isMockData;

      if (event.useMockData) {
        // Force mock without device
        reading = await _bluetoothService.requestSoilReading(
          _firebaseService.currentUserId ?? 'mock_user',
          forceMock: true,
        );
        isMockData = true;
      } else {
        // Use real device flow
        reading = await _bluetoothService.requestSoilReading(
          _firebaseService.currentUserId ?? 'mock_user',
        );
        isMockData = false;
      }

      // Save to Firebase
      if (_firebaseService.currentUserId != null) {
        await _firebaseService.addSoilReading(reading);
      }

      emit(ReadingSuccess(reading, isMockData: isMockData));
    } catch (e) {
      emit(ReadingError(e.toString()));
    }
  }

  Future<void> _onConnectToDevice(
      ConnectToDevice event,
      Emitter<SoilReadingState> emit,
      ) async {
    emit(DeviceConnecting());
    try {
      final connected = await _bluetoothService.connectToDevice(event.device);
      if (connected) {
        emit(DeviceConnected(event.device));
      } else {
        emit(ReadingError('Failed to connect to device'));
      }
    } catch (e) {
      emit(ReadingError(e.toString()));
    }
  }

  void _onUseMockDevice(
      UseMockDevice event,
      Emitter<SoilReadingState> emit,
      ) {
    _bluetoothService.disconnect();
    emit(DeviceDisconnected());
  }

  Future<void> _onDisconnectDevice(
      DisconnectDevice event,
      Emitter<SoilReadingState> emit,
      ) async {
    await _bluetoothService.disconnect();
    emit(DeviceDisconnected());
  }

  @override
  Future<void> close() {
    _readingSubscription?.cancel();
    return super.close();
  }
}