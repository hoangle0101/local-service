import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ========================
// Socket Event Models
// ========================

/// Booking status change event from server
class BookingStatusUpdate {
  final String bookingId;
  final String status;
  final String? previousStatus;
  final String? providerId;
  final String? providerName;
  final String? serviceName;
  final String? scheduledAt;
  final String? addressText;
  final String? message;
  final String? customerName;
  final String? estimatedPrice;
  final double? latitude;
  final double? longitude;
  final String? actorId;
  final DateTime timestamp;

  BookingStatusUpdate({
    required this.bookingId,
    required this.status,
    this.previousStatus,
    this.providerId,
    this.providerName,
    this.serviceName,
    this.scheduledAt,
    this.addressText,
    this.message,
    this.customerName,
    this.estimatedPrice,
    this.latitude,
    this.longitude,
    this.actorId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory BookingStatusUpdate.fromJson(Map<String, dynamic> json) {
    return BookingStatusUpdate(
      bookingId: json['bookingId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      previousStatus: json['previousStatus']?.toString(),
      providerId: json['providerId']?.toString(),
      providerName: json['providerName']?.toString(),
      serviceName: json['serviceName']?.toString(),
      scheduledAt: json['scheduledAt']?.toString(),
      addressText: json['addressText']?.toString(),
      message: json['message']?.toString(),
      customerName: json['customerName']?.toString(),
      estimatedPrice: json['estimatedPrice']?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      actorId: json['actorId']?.toString(),
    );
  }
}

/// Provider location update event
class ProviderLocationUpdate {
  final String bookingId;
  final String providerId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  ProviderLocationUpdate({
    required this.bookingId,
    required this.providerId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ProviderLocationUpdate.fromJson(Map<String, dynamic> json) {
    return ProviderLocationUpdate(
      bookingId: json['bookingId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
    );
  }
}

/// New job available event for providers
class NewJobEvent {
  final String bookingId;
  final int serviceId;
  final String serviceName;
  final int categoryId;
  final String categoryName;
  final String? customerName;
  final String addressText;
  final double latitude;
  final double longitude;
  final String scheduledAt;
  final double? estimatedPrice;
  final double? distance;
  final DateTime timestamp;

  NewJobEvent({
    required this.bookingId,
    required this.serviceId,
    required this.serviceName,
    required this.categoryId,
    required this.categoryName,
    this.customerName,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    this.estimatedPrice,
    this.distance,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NewJobEvent.fromJson(Map<String, dynamic> json) {
    return NewJobEvent(
      bookingId: json['bookingId']?.toString() ?? '',
      serviceId: (json['serviceId'] as num?)?.toInt() ?? 0,
      serviceName: json['serviceName']?.toString() ?? '',
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      customerName: json['customerName']?.toString(),
      addressText: json['addressText']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      scheduledAt: json['scheduledAt']?.toString() ?? '',
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }
}

/// Job taken event (for providers to remove from their list)
class JobTakenEvent {
  final String bookingId;
  final String takenByProviderId;
  final DateTime timestamp;

  JobTakenEvent({
    required this.bookingId,
    required this.takenByProviderId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory JobTakenEvent.fromJson(Map<String, dynamic> json) {
    return JobTakenEvent(
      bookingId: json['bookingId']?.toString() ?? '',
      takenByProviderId: json['takenByProviderId']?.toString() ?? '',
    );
  }
}

/// Notification event
class NotificationEvent {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  NotificationEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}

/// Typing indicator event
class TypingEvent {
  final String conversationId;
  final String userId;
  final bool isTyping;

  TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      conversationId: json['conversationId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      isTyping: json['isTyping'] == true,
    );
  }
}

// ========================
// Socket Events Constants
// ========================
class SocketEvents {
  // Booking Events
  static const String bookingCreated = 'booking_created';
  static const String bookingAccepted = 'booking_accepted';
  static const String bookingStarted = 'booking_started';
  static const String bookingAwaitingConfirmation =
      'booking_awaiting_confirmation';
  static const String bookingCompleted = 'booking_completed';
  static const String bookingCancelled = 'booking_cancelled';
  static const String bookingDisputed = 'booking_disputed';
  static const String bookingStatusChanged = 'booking_status_changed';

  // Location Events
  static const String providerLocationUpdate = 'provider_location_update';
  static const String providerArriving = 'provider_arriving';
  static const String providerArrived = 'provider_arrived';
  static const String subscribeLocation = 'subscribe_location';
  static const String unsubscribeLocation = 'unsubscribe_location';
  static const String sendLocation = 'send_location';

  // Job Market Events
  static const String newJobAvailable = 'new_job_available';
  static const String jobTaken = 'job_taken';
  static const String subscribeJobMarket = 'subscribe_job_market';
  static const String unsubscribeJobMarket = 'unsubscribe_job_market';

  // Provider Status
  static const String providerOnline = 'provider_online';
  static const String providerOffline = 'provider_offline';
  static const String toggleAvailability = 'toggle_availability';

  // Notifications
  static const String newNotification = 'new_notification';

  // Payment Events
  static const String paymentMethodSelected = 'payment_method_selected';

  // Chat Events
  static const String joinConversation = 'join_conversation';
  static const String leaveConversation = 'leave_conversation';
  static const String sendMessage = 'send_message';
  static const String newMessage = 'new_message';
  static const String userTyping = 'user_typing';
  static const String messageRead = 'message_read';
  static const String walletUpdated = 'wallet_updated';
}

// ========================
// SocketService Singleton
// ========================

/// Singleton service for managing WebSocket connections
/// Provides streams for real-time events across the app
class SocketService {
  // Singleton instance
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Socket instance
  IO.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // Base URL (can be configured)
  String _baseUrl = 'http://10.0.2.2:3000'; // Default for Android emulator

  // Stream controllers for events
  final _connectionController = StreamController<bool>.broadcast();
  final _bookingStatusController =
      StreamController<BookingStatusUpdate>.broadcast();
  final _locationUpdateController =
      StreamController<ProviderLocationUpdate>.broadcast();
  final _newJobController = StreamController<NewJobEvent>.broadcast();
  final _jobTakenController = StreamController<JobTakenEvent>.broadcast();
  final _notificationController =
      StreamController<NotificationEvent>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<BookingStatusUpdate> get bookingStatusStream =>
      _bookingStatusController.stream;
  Stream<ProviderLocationUpdate> get locationStream =>
      _locationUpdateController.stream;
  Stream<NewJobEvent> get newJobStream => _newJobController.stream;
  Stream<JobTakenEvent> get jobTakenStream => _jobTakenController.stream;
  Stream<NotificationEvent> get notificationStream =>
      _notificationController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  final _walletUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get walletUpdateStream =>
      _walletUpdateController.stream;

  final _paymentMethodController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get paymentMethodStream =>
      _paymentMethodController.stream;

  // Legacy getters for compatibility
  IO.Socket? get socket => _socket;

  /// Configure the base URL for socket connection
  void configure({String? baseUrl}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
  }

  /// Connect to the socket server (legacy method for compatibility)
  void connect(String token) {
    _connectWithToken(token);
  }

  /// Connect to the socket server
  Future<void> connectAsync() async {
    if (_socket != null && _isConnected) {
      debugPrint('[SocketService] Already connected');
      return;
    }

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint('[SocketService] No token found, cannot connect');
      return;
    }

    _connectWithToken(token);
  }

  void _connectWithToken(String token) {
    // Decode user ID from token
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final resp = utf8.decode(base64Url.decode(normalized));
        final payloadMap = json.decode(resp);
        _currentUserId =
            payloadMap['sub']?.toString() ?? payloadMap['userId']?.toString();
        debugPrint('[SocketService] User ID: $_currentUserId');
      }
    } catch (e) {
      debugPrint('[SocketService] Error decoding token: $e');
    }

    debugPrint('[SocketService] Connecting to $_baseUrl');

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );

    _setupListeners();
    _socket!.connect();
  }

  /// Setup all event listeners
  void _setupListeners() {
    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected: ${_socket?.id}');
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.onConnectError((error) {
      debugPrint('[SocketService] Connect error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onError((error) {
      debugPrint('[SocketService] Error: $error');
    });

    // Booking status events
    _socket!.on(SocketEvents.bookingStatusChanged, (data) {
      debugPrint('[SocketService] Booking status changed: $data');
      if (data != null) {
        _bookingStatusController.add(BookingStatusUpdate.fromJson(data));
      }
    });

    // Location events
    _socket!.on(SocketEvents.providerLocationUpdate, (data) {
      debugPrint('[SocketService] Provider location update: $data');
      if (data != null) {
        _locationUpdateController.add(ProviderLocationUpdate.fromJson(data));
      }
    });

    _socket!.on(SocketEvents.providerArriving, (data) {
      debugPrint('[SocketService] Provider arriving: $data');
    });

    _socket!.on(SocketEvents.providerArrived, (data) {
      debugPrint('[SocketService] Provider arrived: $data');
    });

    // Job market events
    _socket!.on(SocketEvents.newJobAvailable, (data) {
      debugPrint('[SocketService] New job available: $data');
      if (data != null) {
        _newJobController.add(NewJobEvent.fromJson(data));
      }
    });

    _socket!.on(SocketEvents.jobTaken, (data) {
      debugPrint('[SocketService] Job taken: $data');
      if (data != null) {
        _jobTakenController.add(JobTakenEvent.fromJson(data));
      }
    });

    // Notification events
    _socket!.on(SocketEvents.newNotification, (data) {
      debugPrint('[SocketService] New notification: $data');
      if (data != null) {
        _notificationController.add(NotificationEvent.fromJson(data));
      }
    });

    // Chat events
    _socket!.on(SocketEvents.newMessage, (data) {
      debugPrint('[SocketService] New message: $data');
      if (data != null) {
        _messageController.add(data as Map<String, dynamic>);
      }
    });

    _socket!.on(SocketEvents.userTyping, (data) {
      debugPrint('[SocketService] User typing: $data');
      if (data != null) {
        _typingController.add(TypingEvent.fromJson(data));
      }
    });

    _socket!.on(SocketEvents.walletUpdated, (data) {
      debugPrint('[SocketService] Wallet updated: $data');
      if (data != null) {
        _walletUpdateController.add(data as Map<String, dynamic>);
      }
    });

    // Payment method selected (for provider to see COD confirmation button)
    _socket!.on(SocketEvents.paymentMethodSelected, (data) {
      debugPrint('[SocketService] Payment method selected: $data');
      if (data != null) {
        _paymentMethodController.add(data as Map<String, dynamic>);
      }
    });
  }

  /// Disconnect from socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// Dispose all resources - MUST be called when the app is closing
  /// This prevents memory leaks from StreamControllers
  void dispose() {
    disconnect();

    // Close all StreamControllers to prevent memory leaks
    _connectionController.close();
    _bookingStatusController.close();
    _locationUpdateController.close();
    _newJobController.close();
    _jobTakenController.close();
    _notificationController.close();
    _typingController.close();
    _messageController.close();

    debugPrint('[SocketService] All resources disposed');
  }

  /// Generic event listener for compatibility
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remove event listener
  void off(String event) {
    _socket?.off(event);
  }

  // ========================
  // Location Tracking Methods
  // ========================

  /// Subscribe to location updates for a booking (as customer)
  void subscribeToLocation(String bookingId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.subscribeLocation, {'bookingId': bookingId});
    debugPrint('[SocketService] Subscribed to location for booking $bookingId');
  }

  /// Unsubscribe from location updates
  void unsubscribeFromLocation(String bookingId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.unsubscribeLocation, {'bookingId': bookingId});
    debugPrint(
        '[SocketService] Unsubscribed from location for booking $bookingId');
  }

  /// Send location update (as provider)
  void sendLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.sendLocation, {
      'bookingId': bookingId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
    });
  }

  // ========================
  // Job Market Methods
  // ========================

  /// Subscribe to job market updates (as provider)
  void subscribeToJobMarket({List<int>? categoryIds}) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.subscribeJobMarket, {
      'categoryIds': categoryIds ?? <dynamic>['all'],
    });
    debugPrint(
        '[SocketService] Subscribed to job market: ${categoryIds ?? 'all'}');
  }

  /// Unsubscribe from job market
  void unsubscribeFromJobMarket({List<int>? categoryIds}) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.unsubscribeJobMarket, {
      'categoryIds': categoryIds ?? <dynamic>['all'],
    });
  }

  // ========================
  // Provider Availability
  // ========================

  /// Toggle provider availability status
  void toggleAvailability(bool isAvailable) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.toggleAvailability, {
      'isAvailable': isAvailable,
    });
    debugPrint('[SocketService] Toggled availability: $isAvailable');
  }

  // ========================
  // Chat Methods
  // ========================

  /// Join a conversation room
  void joinConversation(String conversationId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(
        SocketEvents.joinConversation, {'conversationId': conversationId});
    debugPrint('[SocketService] Joined conversation $conversationId');
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(
        SocketEvents.leaveConversation, {'conversationId': conversationId});
  }

  /// Send a chat message
  void sendMessage(String conversationId, String content) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.sendMessage, {
      'conversationId': conversationId,
      'content': content,
    });
  }

  /// Send typing indicator
  void sendTypingIndicator(String conversationId, bool isTyping) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.userTyping, {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  /// Mark message as read
  void markMessageRead(String conversationId, String messageId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(SocketEvents.messageRead, {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  /// Legacy method for compatibility
  void joinRoom(String room) {
    // Implement if needed for specific rooms
  }
}
