import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/auth_entities.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/datasources/auth_datasource.dart' show OtpPurpose;
import '../../../data/storage/secure_storage.dart';
import 'auth_event.dart';

export 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LoginWithOtpRequested>(_onLoginWithOtpRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<OtpSendRequested>(_onOtpSendRequested);
    on<OtpVerifyRequested>(_onOtpVerifyRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ProfileFetchRequested>(_onProfileFetchRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isAuth = await SecureStorage.isAuthenticated();
    if (isAuth) {
      final accessToken = await SecureStorage.getAccessToken();
      final refreshToken = await SecureStorage.getRefreshToken();
      if (accessToken != null && refreshToken != null) {
        try {
          // Fetch user profile to get role information
          final user = await _authRepository.getUserProfile(accessToken);
          emit(Authenticated(
            tokens: AuthTokens(
              accessToken: accessToken,
              refreshToken: refreshToken,
            ),
            user: user,
          ));
          return;
        } catch (e) {
          // If profile fetch fails, clear auth and show unauthenticated
          await SecureStorage.clearAuthData();
        }
      }
    }
    emit(Unauthenticated());
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final tokens = await _authRepository.login(
        phone: event.phone,
        password: event.password,
      );

      await SecureStorage.saveAuthData(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userPhone: event.phone,
      );

      // Fetch user profile to determine role
      final user = await _authRepository.getUserProfile(tokens.accessToken);

      emit(Authenticated(tokens: tokens, user: user));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onLoginWithOtpRequested(
    LoginWithOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final tokens = await _authRepository.loginWithOtp(
        phone: event.phone,
        code: event.code,
      );

      await SecureStorage.saveAuthData(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userPhone: event.phone,
      );

      // Fetch user profile to determine role
      final user = await _authRepository.getUserProfile(tokens.accessToken);

      emit(Authenticated(tokens: tokens, user: user));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  // Temporary credentials for auto-login after registration
  String? _tempPhone;
  String? _tempPassword;

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      _tempPhone = event.phone;
      _tempPassword = event.password;

      final result = await _authRepository.register(
        phone: event.phone,
        password: event.password,
        fullName: event.fullName,
        role: event.role,
      );

      emit(RegistrationSuccess(
        message: result['message'] as String? ??
            'Registration successful. Please verify OTP.',
        phone: event.phone,
      ));
    } catch (e) {
      _tempPhone = null;
      _tempPassword = null;
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onOtpSendRequested(
    OtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final purpose = _stringToOtpPurpose(event.purpose);
      final result = await _authRepository.sendOtp(
        phone: event.phone,
        purpose: purpose,
      );

      emit(OtpSent(
        message: result['message'] as String? ?? 'OTP sent successfully',
        phone: event.phone,
        code: result['code'] as String?, // Only in development
      ));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onOtpVerifyRequested(
    OtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final purpose = _stringToOtpPurpose(event.purpose);
      final result = await _authRepository.verifyOtp(
        phone: event.phone,
        code: event.code,
        purpose: purpose,
      );

      // If this was for registration (verify_phone) and we have credentials, auto-login
      if (purpose == OtpPurpose.verifyPhone &&
          _tempPhone == event.phone &&
          _tempPassword != null) {
        try {
          final tokens = await _authRepository.login(
            phone: _tempPhone!,
            password: _tempPassword!,
          );

          await SecureStorage.saveAuthData(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            userPhone: _tempPhone!,
          );

          // Clear temp credentials
          _tempPhone = null;
          _tempPassword = null;
        } catch (e) {
          print('Auto-login failed: $e');
          // Continue even if login fails, user can login manually later
          // But for provider registration, this is critical.
          // However, we still emit OtpVerified so user sees success.
        }
      } else {
        print(
            'Skipping auto-login: purpose=$purpose, tempPhone=$_tempPhone, hasPassword=${_tempPassword != null}');
      }

      emit(OtpVerified(
        result['message'] as String? ?? 'OTP verified successfully',
      ));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _authRepository.logout(refreshToken);
      }
      await SecureStorage.clearAuthData();
      emit(Unauthenticated());
    } catch (e) {
      // Even if logout fails, clear local data
      await SecureStorage.clearAuthData();
      emit(Unauthenticated());
    }
  }

  Future<void> _onProfileFetchRequested(
    ProfileFetchRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final accessToken = await SecureStorage.getAccessToken();
      if (accessToken == null) {
        emit(Unauthenticated());
        return;
      }

      print('[AuthBloc] ProfileFetchRequested - fetching profile...');
      final user = await _authRepository.getUserProfile(accessToken);
      print('[AuthBloc] Profile fetched for user: ${user.profile?.fullName}');
      print('[AuthBloc] Avatar URL: ${user.profile?.avatarUrl}');
      print('[AuthBloc] Provider address: ${user.providerProfile?.address}');

      final refreshToken = await SecureStorage.getRefreshToken();

      if (refreshToken != null) {
        emit(Authenticated(
          tokens: AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
          user: user,
        ));
        print('[AuthBloc] Emitted Authenticated state with updated user');
      }
    } catch (e) {
      print('[AuthBloc] ProfileFetchRequested error: $e');
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  String _extractErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('Exception:')) {
      return errorString.replaceAll('Exception:', '').trim();
    }
    return 'An error occurred. Please try again.';
  }

  OtpPurpose _stringToOtpPurpose(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'login':
        return OtpPurpose.login;
      case 'reset_password':
        return OtpPurpose.resetPassword;
      case 'verify_phone':
        return OtpPurpose.verifyPhone;
      default:
        return OtpPurpose.verifyPhone;
    }
  }
}
