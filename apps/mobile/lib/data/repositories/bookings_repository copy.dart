import '../datasources/bookings_datasource.dart';
import '../../presentation/bloc/bookings/bookings_event_state.dart';

/// Repository layer for booking-related operations.
/// Wraps BookingsDataSource to provide abstraction and testability.
class BookingsRepository {
  final BookingsDataSource _dataSource;

  BookingsRepository([BookingsDataSource? dataSource])
      : _dataSource = dataSource ?? BookingsDataSource();

  /// Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required int serviceId,
    required DateTime scheduledAt,
    required String addressText,
    required double latitude,
    required double longitude,
    String? notes,
    int? providerId,
    List<Map<String, dynamic>>? selectedItems,
  }) =>
      _dataSource.createBooking(
        serviceId: serviceId,
        scheduledAt: scheduledAt,
        addressText: addressText,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
        providerId: providerId,
        selectedItems: selectedItems,
      );

  /// Get booking offers for a specific booking
  Future<List<BookingOffer>> getBookingOffers(int bookingId) =>
      _dataSource.getBookingOffers(bookingId);

  /// Select a provider for a booking
  Future<Map<String, dynamic>> selectProvider(int bookingId, int providerId) =>
      _dataSource.selectProvider(bookingId, providerId);

  /// Get booking details by ID
  Future<Booking> getBookingById(String bookingId) =>
      _dataSource.getBookingById(bookingId);

  /// Get user bookings (customer role)
  Future<List<Booking>> getUserBookings({String? status}) =>
      _dataSource.getUserBookings(status: status);

  /// Get provider bookings (provider role)
  Future<List<Booking>> getProviderBookings({String? status}) =>
      _dataSource.getProviderBookings(status: status);

  /// Get booking requests assigned to provider
  Future<List<Booking>> getProviderRequests() =>
      _dataSource.getProviderRequests();

  /// Get global booking requests (optionally filtered)
  Future<List<Booking>> getGlobalRequests(
          {int? serviceId, int? categoryId, bool onlyFar = false}) =>
      _dataSource.getGlobalRequests(
          serviceId: serviceId, categoryId: categoryId, onlyFar: onlyFar);

  /// Get active booking (in progress, pending completion, or accepted)
  Future<Booking?> getActiveBooking() => _dataSource.getActiveBooking();

  /// Provider accepts a booking request
  Future<Map<String, dynamic>> acceptBookingRequest(int bookingId) =>
      _dataSource.acceptBookingRequest(bookingId);

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, String? reason) =>
      _dataSource.cancelBooking(bookingId, reason);

  /// Submit a review for a completed booking
  Future<Map<String, dynamic>> reviewBooking(
    String bookingId,
    int rating,
    String comment,
  ) =>
      _dataSource.reviewBooking(bookingId, rating, comment);

  /// Provider accepts booking (legacy method)
  Future<void> acceptBookingLegacy(String bookingId) =>
      _dataSource.acceptBookingLegacy(bookingId);

  /// Provider starts the service
  Future<void> startService(String bookingId) =>
      _dataSource.startService(bookingId);

  /// Provider marks service as complete
  Future<void> completeService(String bookingId) =>
      _dataSource.completeService(bookingId);

  /// Customer confirms service completion
  Future<Map<String, dynamic>> confirmCompletion(String bookingId) =>
      _dataSource.confirmCompletion(bookingId);

  /// Customer disputes service completion
  Future<Map<String, dynamic>> disputeBooking(
    String bookingId,
    String reason,
  ) =>
      _dataSource.disputeBooking(bookingId, reason);
}
