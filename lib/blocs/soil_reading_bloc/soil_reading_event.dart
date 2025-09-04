part of 'soil_reading_bloc.dart';

@immutable
abstract class SoilReadingEvent {}

class FetchReading extends SoilReadingEvent {
  final bool useMockData;

  FetchReading({this.useMockData = true});
}

class ConnectToDevice extends SoilReadingEvent {
  final SoilDevice device;

  ConnectToDevice(this.device);
}

class UseMockDevice extends SoilReadingEvent {}

class DisconnectDevice extends SoilReadingEvent {}