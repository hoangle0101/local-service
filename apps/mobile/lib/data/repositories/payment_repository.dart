import '../datasources/payment_datasource.dart';

// Export models for consumers
export '../datasources/payment_datasource.dart'
    show
        WalletBalance,
        WalletTransaction,
        Withdrawal,
        BookingPayment,
        PaymentResult;

/// Repository layer for payment operations.
/// Wraps PaymentDataSource to provide abstraction.
class PaymentRepository {
  final PaymentDataSource _dataSource;

  PaymentRepository([PaymentDataSource? dataSource])
      : _dataSource = dataSource ?? PaymentDataSource();

  // ============ WALLET ============

  /// Get wallet balance
  Future<WalletBalance> getBalance() => _dataSource.getBalance();

  /// Get wallet transactions
  Future<List<WalletTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
  }) =>
      _dataSource.getTransactions(page: page, limit: limit);

  // ============ PAYMENT ============

  /// Create payment for booking
  Future<PaymentResult> createPayment({
    required String bookingId,
    required int amount,
    required String paymentMethod,
  }) =>
      _dataSource.createPayment(
        bookingId: bookingId,
        amount: amount,
        paymentMethod: paymentMethod,
      );

  /// Confirm COD payment (provider)
  Future<BookingPayment> confirmCodPayment(String bookingPaymentId) =>
      _dataSource.confirmCodPayment(bookingPaymentId);

  /// Get payment by ID
  Future<BookingPayment> getPayment(String id) => _dataSource.getPayment(id);

  /// Get provider's payments
  Future<List<BookingPayment>> getProviderPayments({String? status}) =>
      _dataSource.getProviderPayments(status: status);

  // ============ WITHDRAWAL ============

  /// Create withdrawal request
  Future<Withdrawal> createWithdrawal({
    required int amount,
    required String method,
    String? bankName,
    String? bankAccount,
    String? bankHolder,
    String? momoPhone,
  }) =>
      _dataSource.createWithdrawal(
        amount: amount,
        method: method,
        bankName: bankName,
        bankAccount: bankAccount,
        bankHolder: bankHolder,
        momoPhone: momoPhone,
      );

  /// Get my withdrawals
  Future<List<Withdrawal>> getMyWithdrawals({String? status}) =>
      _dataSource.getMyWithdrawals(status: status);

  // ============ BOOKING PAYMENT ============

  /// Get invoice for booking
  Future<Map<String, dynamic>> getInvoice(String bookingId) =>
      _dataSource.getInvoice(bookingId);

  /// Provider updates final price
  Future<Map<String, dynamic>> updateFinalPrice({
    required String bookingId,
    required double actualPrice,
    double? additionalCosts,
    String? additionalNotes,
  }) =>
      _dataSource.updateFinalPrice(
        bookingId: bookingId,
        actualPrice: actualPrice,
        additionalCosts: additionalCosts,
        additionalNotes: additionalNotes,
      );

  /// Provider marks service as complete
  Future<Map<String, dynamic>> markServiceComplete(String bookingId) =>
      _dataSource.markServiceComplete(bookingId);

  /// Provider confirms COD payment received for booking
  Future<Map<String, dynamic>> confirmBookingCod(String bookingId) =>
      _dataSource.confirmBookingCod(bookingId);

  /// Customer pays via MoMo
  Future<Map<String, dynamic>> payWithMomo(String bookingId) =>
      _dataSource.payWithMomo(bookingId);
}
