part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});
}

class SignupRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  SignupRequested({
    required this.email,
    required this.password,
    this.displayName,
  });
}

class LogoutRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final User? user;

  AuthStateChanged(this.user);
}