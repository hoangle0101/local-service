import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Payment and Wallet Data Source
class PaymentDataSource {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  PaymentDataSource() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:3000',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  // ============================================
  // WALLET APIs
  // ============================================

  /// Get wallet balance
  Future<WalletBalance> getBalance() async {
    final response = await _dio.get('/wallets/balance');
    final data = response.data;
    // Handle both wrapped and unwrapped response
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data')) {
        return WalletBalance.fromJson(data['data']);
      }
      return WalletBalance.fromJson(data);
    }
    return WalletBalance(balance: 0);
  }

  /// Deposit money to wallet
  Future<Map<String, dynamic>> deposit({
    required int amount,
    required String gateway, // momo
  }) async {
    final response = await _dio.post('/wallets/deposit', data: {
      'amount': amount,
      'gateway': gateway,
    });
    return response.data['data'] ?? response.data;
  }

  /// Get wallet transactions
  Future<List<WalletTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/wallets/transactions', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    List<dynamic> list = [];
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is List) {
        list = data['data'];
      } else if (data.containsKey('transactions') &&
          data['transactions'] is List) {
        list = data['transactions'];
      }
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => WalletTransaction.fromJson(e)).toList();
  }

  // ============================================
  // PAYMENT APIs
  // ============================================

  /// Create payment for booking
  Future<PaymentResult> createPayment({
    required String bookingId,
    required int amount,
    required String paymentMethod, // COD or MOMO
  }) async {
    final response = await _dio.post('/payments/create', data: {
      'bookingId': bookingId,
      'amount': amount,
      'paymentMethod': paymentMethod,
    });
    return PaymentResult.fromJson(response.data['data']);
  }

  /// Confirm COD payment (provider)
  Future<BookingPayment> confirmCodPayment(String bookingPaymentId) async {
    final response = await _dio.post('/payments/cod/confirm', data: {
      'bookingPaymentId': bookingPaymentId,
    });
    return BookingPayment.fromJson(response.data['data']);
  }

  /// Get payment by ID
  Future<BookingPayment> getPayment(String id) async {
    final response = await _dio.get('/payments/$id');
    return BookingPayment.fromJson(response.data['data']);
  }

  /// Get provider's payments
  Future<List<BookingPayment>> getProviderPayments({String? status}) async {
    final response = await _dio.get('/payments/provider/me', queryParameters: {
      if (status != null) 'status': status,
    });
    final list = response.data['data'] as List;
    return list.map((e) => BookingPayment.fromJson(e)).toList();
  }

  // ============================================
  // WITHDRAWAL APIs
  // ============================================

  /// Create withdrawal request
  Future<Withdrawal> createWithdrawal({
    required int amount,
    required String method, // BANK or MOMO
    String? bankName,
    String? bankAccount,
    String? bankHolder,
    String? momoPhone,
  }) async {
    final response = await _dio.post('/withdrawals', data: {
      'amount': amount,
      'method': method,
      if (bankName != null) 'bankName': bankName,
      if (bankAccount != null) 'bankAccount': bankAccount,
      if (bankHolder != null) 'bankHolder': bankHolder,
      if (momoPhone != null) 'momoPhone': momoPhone,
    });
    return Withdrawal.fromJson(response.data['data']);
  }

  /// Get my withdrawals
  Future<List<Withdrawal>> getMyWithdrawals({String? status}) async {
    final response = await _dio.get('/withdrawals/me', queryParameters: {
      if (status != null) 'status': status,
    });
    final data = response.data;
    List<dynamic> list = [];
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is List) {
        list = data['data'];
      }
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => Withdrawal.fromJson(e)).toList();
  }

  // ============================================
  // BOOKING PAYMENT APIs (Post-Completion Flow)
  // ============================================

  /// Get invoice for booking
  Future<Map<String, dynamic>> getInvoice(String bookingId) async {
    final response = await _dio.get('/booking-payments/$bookingId/invoice');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data.containsKey('data') ? data['data'] : data;
    }
    return {};
  }

  /// Provider updates final price
  Future<Map<String, dynamic>> updateFinalPrice({
    required String bookingId,
    required double actualPrice,
    double? additionalCosts,
    String? additionalNotes,
  }) async {
    final response =
        await _dio.post('/booking-payments/$bookingId/update-price', data: {
      'actualPrice': actualPrice,
      if (additionalCosts != null) 'additionalCosts': additionalCosts,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
    });
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data.containsKey('data') ? data['data'] : data;
    }
    return {};
  }

  /// Provider marks service as complete (pending_payment)
  Future<Map<String, dynamic>> markServiceComplete(String bookingId) async {
    final response =
        await _dio.post('/booking-payments/$bookingId/mark-complete');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data.containsKey('data') ? data['data'] : data;
    }
    return {};
  }

  /// Provider confirms COD payment received for booking
  Future<Map<String, dynamic>> confirmBookingCod(String bookingId) async {
    final response =
        await _dio.post('/booking-payments/$bookingId/confirm-cod');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data.containsKey('data') ? data['data'] : data;
    }
    return {};
  }

  /// Customer pays via MoMo
  Future<Map<String, dynamic>> payWithMomo(String bookingId) async {
    final response = await _dio.post('/booking-payments/$bookingId/pay-momo');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data.containsKey('data') ? data['data'] : data;
    }
    return {};
  }

  /// Check deposit payment status (polling fallback)
  Future<Map<String, dynamic>> checkDepositStatus(String orderId) async {
    final response =
        await _dio.get('/wallets/check-deposit-status', queryParameters: {
      'orderId': orderId,
    });
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data.containsKey('data') ? data['data'] : data;
    }
    return {};
  }

  /// Check booking payment status (polling fallback for MoMo)
  Future<Map<String, dynamic>> checkBookingPaymentStatus(String orderId) async {
    final response = await _dio
        .get('/booking-payments/check-payment-status', queryParameters: {
      'orderId': orderId,
    });
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data.containsKey('data') ? data['data'] : data;
    }
    return {};
  }
}

// ============================================
// MODELS
// ============================================

class WalletBalance {
  final double balance;
  final double pendingBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final int totalTransactions;

  WalletBalance({
    required this.balance,
    this.pendingBalance = 0,
    this.totalEarnings = 0,
    this.totalWithdrawn = 0,
    this.totalTransactions = 0,
  });

  factory WalletBalance.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return WalletBalance(balance: 0);
    }
    // Backend returns balance as string, parse it
    double parseBalance(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return WalletBalance(
      balance: parseBalance(json['balance']),
      pendingBalance: parseBalance(json['pendingBalance']),
      totalEarnings: parseBalance(json['totalEarnings']),
      totalWithdrawn: parseBalance(json['totalWithdrawn']),
      totalTransactions: json['totalTransactions'] ?? 0,
    );
  }
}

class WalletTransaction {
  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.status,
    required this.createdAt,
    this.metadata,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'],
    );
  }

  String get typeDisplayName {
    switch (type) {
      case 'earning':
        return 'Thu nhập';
      case 'withdrawal':
        return 'Rút tiền';
      case 'deposit':
        return 'Nạp tiền';
      case 'refund':
        return 'Hoàn tiền';
      default:
        return type;
    }
  }

  bool get isPositive => amount > 0;
}

class BookingPayment {
  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final double amount;
  final double platformFee;
  final double providerAmount;
  final String paymentMethod;
  final String? momoTransId;
  final String status;
  final DateTime? paidAt;
  final DateTime? releasedAt;
  final DateTime createdAt;

  BookingPayment({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.amount,
    required this.platformFee,
    required this.providerAmount,
    required this.paymentMethod,
    this.momoTransId,
    required this.status,
    this.paidAt,
    this.releasedAt,
    required this.createdAt,
  });

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      providerAmount: (json['providerAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      momoTransId: json['momoTransId'],
      status: json['status'] ?? '',
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      releasedAt: json['releasedAt'] != null
          ? DateTime.tryParse(json['releasedAt'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Chờ thanh toán';
      case 'held':
        return 'Đang giữ';
      case 'released':
        return 'Đã chuyển';
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'disputed':
        return 'Tranh chấp';
      default:
        return status;
    }
  }
}

class PaymentResult {
  final BookingPayment bookingPayment;
  final MomoPaymentInfo? momo;
  final String? message;

  PaymentResult({
    required this.bookingPayment,
    this.momo,
    this.message,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      bookingPayment: BookingPayment.fromJson(json['bookingPayment']),
      momo:
          json['momo'] != null ? MomoPaymentInfo.fromJson(json['momo']) : null,
      message: json['message'],
    );
  }
}

class MomoPaymentInfo {
  final String? payUrl;
  final String? qrCodeUrl;
  final String? deeplink;

  MomoPaymentInfo({this.payUrl, this.qrCodeUrl, this.deeplink});

  factory MomoPaymentInfo.fromJson(Map<String, dynamic> json) {
    return MomoPaymentInfo(
      payUrl: json['payUrl'],
      qrCodeUrl: json['qrCodeUrl'],
      deeplink: json['deeplink'],
    );
  }
}

class Withdrawal {
  final String id;
  final String providerId;
  final double amount;
  final double fee;
  final double netAmount;
  final String method;
  final String? bankName;
  final String? bankAccount;
  final String? bankHolder;
  final String? momoPhone;
  final String status;
  final String? note;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  Withdrawal({
    required this.id,
    required this.providerId,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.method,
    this.bankName,
    this.bankAccount,
    this.bankHolder,
    this.momoPhone,
    required this.status,
    this.note,
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      method: json['method'] ?? '',
      bankName: json['bankName'],
      bankAccount: json['bankAccount'],
      bankHolder: json['bankHolder'],
      momoPhone: json['momoPhone'],
      status: json['status'] ?? '',
      note: json['note'],
      adminNote: json['adminNote'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'])
          : null,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'failed':
        return 'Thất bại';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
