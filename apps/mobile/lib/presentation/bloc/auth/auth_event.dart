import 'package:equatable/equatable.dart';
import '../../../core/entities/auth_entities.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String phone;
  final String password;

  const LoginRequested({
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [phone, password];
}

class LoginWithOtpRequested extends AuthEvent {
  final String phone;
  final String code;

  const LoginWithOtpRequested({
    required this.phone,
    required this.code,
  });

  @override
  List<Object?> get props => [phone, code];
}

class RegisterRequested extends AuthEvent {
  final String phone;
  final String password;
  final String fullName;
  final String? role; // Optional: 'customer' or 'provider'

  const RegisterRequested({
    required this.phone,
    required this.password,
    required this.fullName,
    this.role,
  });

  @override
  List<Object?> get props => [phone, password, fullName, role];
}

class OtpSendRequested extends AuthEvent {
  final String phone;
  final String purpose;

  const OtpSendRequested({
    required this.phone,
    required this.purpose,
  });

  @override
  List<Object?> get props => [phone, purpose];
}

class OtpVerifyRequested extends AuthEvent {
  final String phone;
  final String code;
  final String purpose;

  const OtpVerifyRequested({
    required this.phone,
    required this.code,
    required this.purpose,
  });

  @override
  List<Object?> get props => [phone, code, purpose];
}

class LogoutRequested extends AuthEvent {}

class ProfileFetchRequested extends AuthEvent {
  const ProfileFetchRequested();
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AuthTokens tokens;
  final UserEntity? user;

  const Authenticated({
    required this.tokens,
    this.user,
  });

  @override
  List<Object?> get props => [tokens, user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class RegistrationSuccess extends AuthState {
  final String message;
  final String phone;

  const RegistrationSuccess({
    required this.message,
    required this.phone,
  });

  @override
  List<Object?> get props => [message, phone];
}

class OtpSent extends AuthState {
  final String message;
  final String phone;
  final String? code; // Only in development

  const OtpSent({
    required this.message,
    required this.phone,
    this.code,
  });

  @override
  List<Object?> get props => [message, phone, code];
}

class OtpVerified extends AuthState {
  final String message;

  const OtpVerified(this.message);

  @override
  List<Object?> get props => [message];
}
