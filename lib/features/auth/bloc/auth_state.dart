part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthResetPasswordSent extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  final bool isInfo;

  const AuthFailure({required this.message, this.isInfo = false});

  @override
  List<Object?> get props => [message, isInfo];
}
