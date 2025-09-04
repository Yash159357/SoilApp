part of 'soil_reading_bloc.dart';

@immutable
abstract class SoilReadingState {}

class ReadingInitial extends SoilReadingState {}

class ReadingLoading extends SoilReadingState {}

class ReadingSuccess extends SoilReadingState {
  final SoilReading reading;
  final bool isMockData;

  ReadingSuccess(this.reading, {this.isMockData = true});
}

class ReadingError extends SoilReadingState {
  final String message;

  ReadingError(this.message);
}

class DeviceConnecting extends SoilReadingState {}

class DeviceConnected extends SoilReadingState {
  final SoilDevice device;

  DeviceConnected(this.device);
}

class DeviceDisconnected extends SoilReadingState {}