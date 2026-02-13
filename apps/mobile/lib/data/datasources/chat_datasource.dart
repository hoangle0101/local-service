import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// DataSource for Chat/Conversation APIs
class ChatDataSource {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ChatDataSource() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add auth interceptor
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

  /// Create or get conversation for a booking
  Future<Map<String, dynamic>> getOrCreateConversation(String bookingId) async {
    final response = await _dio.post('/conversations', data: {
      'bookingId': int.tryParse(bookingId) ?? 0,
    });
    final data = response.data is Map && response.data.containsKey('data')
        ? response.data['data']
        : response.data;
    return _parseConversation(data);
  }

  /// Get messages for a conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final response = await _dio.get('/conversations/$conversationId/messages');
    final rawData = response.data is Map && response.data.containsKey('data')
        ? response.data['data']
        : response.data;
    final List<dynamic> list = rawData is List ? rawData : [];
    return list.map((m) => ChatMessage.fromJson(m)).toList();
  }

  /// Send a message
  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    final response =
        await _dio.post('/conversations/$conversationId/messages', data: {
      'content': content,
    });
    final data = response.data is Map && response.data.containsKey('data')
        ? response.data['data']
        : response.data;
    return ChatMessage.fromJson(data);
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    await _dio.patch('/conversations/$conversationId/read');
  }

  Map<String, dynamic> _parseConversation(dynamic data) {
    return {
      'id': data['id']?.toString() ?? '',
      'customerId': data['customerId']?.toString() ??
          data['customer_id']?.toString() ??
          '',
      'providerId': data['providerId']?.toString() ??
          data['provider_id']?.toString() ??
          '',
      'bookingId':
          data['bookingId']?.toString() ?? data['booking_id']?.toString() ?? '',
    };
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ??
          json['conversation_id']?.toString() ??
          '',
      senderId:
          json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '',
      senderName: json['sender']?['profile']?['fullName'] ?? json['senderName'],
      senderAvatar:
          json['sender']?['profile']?['avatarUrl'] ?? json['senderAvatar'],
      body: json['body'] ?? '',
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}
