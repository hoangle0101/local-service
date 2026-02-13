import '../datasources/quote_datasource.dart';

/// Repository layer for quote operations.
/// Wraps QuoteDataSource to provide abstraction.
class QuoteRepository {
  final QuoteDataSource _dataSource;

  QuoteRepository([QuoteDataSource? dataSource])
      : _dataSource = dataSource ?? QuoteDataSource();

  /// Provider creates a quote for a booking
  Future<Map<String, dynamic>> createQuote({
    required String bookingId,
    required String diagnosis,
    required List<Map<String, dynamic>> items,
    required int laborCost,
    int? surcharge,
    String? warranty,
    int? estimatedTime,
    List<String>? images,
    String? notes,
    String? providerNotes,
  }) =>
      _dataSource.createQuote(
        bookingId: bookingId,
        diagnosis: diagnosis,
        items: items,
        laborCost: laborCost,
        surcharge: surcharge,
        warranty: warranty,
        estimatedTime: estimatedTime,
        images: images,
        notes: notes,
        providerNotes: providerNotes,
      );

  /// Provider agrees to rejection - cancels booking
  Future<Map<String, dynamic>> providerAgreeReject(String quoteId) =>
      _dataSource.providerAgreeReject(quoteId);

  /// Get quotes for a booking
  Future<List<Map<String, dynamic>>> getQuotesForBooking(String bookingId) =>
      _dataSource.getQuotesForBooking(bookingId);

  /// Get quote by ID
  Future<Map<String, dynamic>> getQuoteById(String quoteId) =>
      _dataSource.getQuoteById(quoteId);

  /// Customer accepts a quote
  Future<Map<String, dynamic>> acceptQuote(
    String quoteId, {
    String? customerNote,
  }) =>
      _dataSource.acceptQuote(quoteId, customerNote: customerNote);

  /// Customer rejects a quote
  Future<Map<String, dynamic>> rejectQuote(
    String quoteId, {
    required String reason,
  }) =>
      _dataSource.rejectQuote(quoteId, reason: reason);
}
