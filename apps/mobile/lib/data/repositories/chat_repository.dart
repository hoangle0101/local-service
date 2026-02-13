import '../datasources/chat_datasource.dart';

// Export ChatMessage model for consumers
export '../datasources/chat_datasource.dart' show ChatMessage;

/// Repository layer for chat operations.
/// Wraps ChatDataSource to provide abstraction.
class ChatRepository {
  final ChatDataSource _dataSource;

  ChatRepository([ChatDataSource? dataSource])
      : _dataSource = dataSource ?? ChatDataSource();

  /// Create or get conversation for a booking
  Future<Map<String, dynamic>> getOrCreateConversation(String bookingId) =>
      _dataSource.getOrCreateConversation(bookingId);

  /// Get messages for a conversation
  Future<List<ChatMessage>> getMessages(String conversationId) =>
      _dataSource.getMessages(conversationId);

  /// Send a message
  Future<ChatMessage> sendMessage(String conversationId, String content) =>
      _dataSource.sendMessage(conversationId, content);

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) =>
      _dataSource.markAsRead(conversationId);
}
