import 'package:bloc/bloc.dart';
import 'package:soil_app/models/user.dart';
import 'package:soil_app/services/firebase_service.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService _firebaseService;

  AuthBloc(this._firebaseService) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Listen to Firebase auth state changes
    _firebaseService.authStateChanges.listen((user) {
      add(AuthStateChanged(user != null ? User.fromFirebaseUser(user) : null));
    });
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await _firebaseService.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignupRequested(
      SignupRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await _firebaseService.createUserWithEmailAndPassword(
        event.email,
        event.password,
        event.displayName,
      );
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('Signup failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await _firebaseService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onAuthStateChanged(
      AuthStateChanged event,
      Emitter<AuthState> emit,
      ) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }
}