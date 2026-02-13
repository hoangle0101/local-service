import '../datasources/auth_datasource.dart';
import '../../core/entities/auth_entities.dart';

/// Repository layer for authentication operations.
/// Wraps AuthDataSource to provide abstraction.
class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository([AuthDataSource? dataSource])
      : _dataSource = dataSource ?? AuthDataSource();

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String fullName,
    String? role,
  }) =>
      _dataSource.register(
        phone: phone,
        password: password,
        fullName: fullName,
        role: role,
      );

  /// Login with password
  Future<AuthTokens> login({
    required String phone,
    required String password,
  }) =>
      _dataSource.login(phone: phone, password: password);

  /// Login with OTP
  Future<AuthTokens> loginWithOtp({
    required String phone,
    required String code,
  }) =>
      _dataSource.loginWithOtp(phone: phone, code: code);

  /// Send OTP
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) =>
      _dataSource.sendOtp(phone: phone, purpose: purpose);

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    required OtpPurpose purpose,
  }) =>
      _dataSource.verifyOtp(phone: phone, code: code, purpose: purpose);

  /// Refresh access token
  Future<String> refreshToken(String refreshToken) =>
      _dataSource.refreshToken(refreshToken);

  /// Logout
  Future<void> logout(String refreshToken) => _dataSource.logout(refreshToken);

  /// Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) =>
      _dataSource.resetPassword(
          phone: phone, otp: otp, newPassword: newPassword);

  /// Get user profile
  Future<UserEntity> getUserProfile(String accessToken) =>
      _dataSource.getUserProfile(accessToken);
}
