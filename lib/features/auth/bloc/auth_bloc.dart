import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:petani_maju/data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      // session null = email confirmation required
      if (response.session == null) {
        emit(const AuthFailure(
          message:
              'Registrasi berhasil! Cek email Anda untuk konfirmasi akun sebelum masuk.',
          isInfo: true,
        ));
      } else {
        emit(AuthSuccess());
      }
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPassword(email: event.email);
      emit(AuthResetPasswordSent());
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: _parseError(e)));
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Periksa kotak masuk Anda.';
    }
    if (msg.contains('User already registered')) {
      return 'Email sudah terdaftar.';
    }
    if (msg.contains('Password should be at least')) {
      return 'Password minimal 6 karakter.';
    }
    if (msg.contains('Unable to validate email address')) {
      return 'Format email tidak valid.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
