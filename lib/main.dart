// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soil_app/blocs/auth_bloc/auth_bloc.dart';
import 'package:soil_app/blocs/soil_reading_bloc/soil_reading_bloc.dart';
import 'package:soil_app/blocs/history_bloc/history_bloc.dart';
import 'package:soil_app/const.dart';
import 'package:soil_app/services/bluetooth_service.dart';
import 'package:soil_app/services/firebase_service.dart';
import 'package:soil_app/theme.dart';
import 'package:soil_app/view/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final bluetoothService = BluetoothService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(firebaseService),
        ),
        BlocProvider(
          create: (context) => SoilReadingBloc(bluetoothService, firebaseService),
        ),
        BlocProvider(
          create: (context) => HistoryBloc(firebaseService),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
