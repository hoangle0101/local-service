import 'package:equatable/equatable.dart';

// ========== EVENTS ==========

abstract class BookingsEvent extends Equatable {
  const BookingsEvent();

  @override
  List<Object?> get props => [];
}

// User Events
class LoadUserBookingsEvent extends BookingsEvent {
  final String? status;

  const LoadUserBookingsEvent({this.status});

  @override
  List<Object?> get props => [status];
}

// Alias for backward compatibility
class LoadBookings extends BookingsEvent {
  const LoadBookings();
}

class CreateBookingEvent extends BookingsEvent {
  final int serviceId;
  final DateTime scheduledAt;
  final String addressText;
  final double latitude;
  final double longitude;
  final String? notes;
  final int? providerId; // For direct booking
  final List<Map<String, dynamic>>? selectedItems; // Pre-selected service items

  const CreateBookingEvent({
    required this.serviceId,
    required this.scheduledAt,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.providerId,
    this.selectedItems,
  });

  @override
  List<Object?> get props => [
        serviceId,
        scheduledAt,
        addressText,
        latitude,
        longitude,
        notes,
        providerId,
        selectedItems,
      ];
}

class LoadBookingOffersEvent extends BookingsEvent {
  final int bookingId;

  const LoadBookingOffersEvent(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class SelectProviderEvent extends BookingsEvent {
  final int bookingId;
  final int providerId;

  const SelectProviderEvent(this.bookingId, this.providerId);

  @override
  List<Object?> get props => [bookingId, providerId];
}

class CancelBooking extends BookingsEvent {
  final String bookingId;
  final String? reason;

  const CancelBooking(this.bookingId, [this.reason]);

  @override
  List<Object?> get props => [bookingId, reason];
}

class ReviewBooking extends BookingsEvent {
  final String bookingId;
  final int rating;
  final String comment;

  const ReviewBooking(this.bookingId, this.rating, this.comment);

  @override
  List<Object?> get props => [bookingId, rating, comment];
}

// Provider Events
class LoadProviderBookings extends BookingsEvent {
  const LoadProviderBookings();
}

class LoadProviderRequestsEvent extends BookingsEvent {
  const LoadProviderRequestsEvent();
}

class AcceptBookingRequestEvent extends BookingsEvent {
  final int bookingId;

  const AcceptBookingRequestEvent(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

// Alias for backward compatibility
class AcceptBooking extends BookingsEvent {
  final String bookingId;

  const AcceptBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class StartService extends BookingsEvent {
  final String bookingId;

  const StartService(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class CompleteService extends BookingsEvent {
  final String bookingId;

  const CompleteService(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

// ========== STATES ==========

abstract class BookingsState extends Equatable {
  const BookingsState();

  @override
  List<Object?> get props => [];
}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

// Main loaded state for list of bookings
class BookingsLoaded extends BookingsState {
  final List<Booking> bookings;

  const BookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class BookingCreated extends BookingsState {
  final String bookingId;
  final String bookingCode;
  final List<String> nearbyProviderIds;
  final bool isDirectBooking;
  final String? providerId;

  const BookingCreated({
    required this.bookingId,
    required this.bookingCode,
    required this.nearbyProviderIds,
    this.isDirectBooking = false,
    this.providerId,
  });

  @override
  List<Object?> get props =>
      [bookingId, bookingCode, nearbyProviderIds, isDirectBooking, providerId];
}

class BookingOffersLoaded extends BookingsState {
  final List<BookingOffer> offers;

  const BookingOffersLoaded(this.offers);

  @override
  List<Object?> get props => [offers];
}

class ProviderSelected extends BookingsState {
  final String bookingId;
  final String providerId;

  const ProviderSelected(this.bookingId, this.providerId);

  @override
  List<Object?> get props => [bookingId, providerId];
}

class UserBookingsLoaded extends BookingsState {
  final List<Booking> bookings;

  const UserBookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class ProviderRequestsLoaded extends BookingsState {
  final List<Booking> requests;

  const ProviderRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class BookingOfferSent extends BookingsState {
  final String offerId;

  const BookingOfferSent(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

class BookingActionSuccess extends BookingsState {
  final String message;

  const BookingActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingsError extends BookingsState {
  final String message;

  const BookingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ========== HELPER MODELS ==========

class BookingOffer {
  final int id;
  final int bookingId;
  final int providerId;
  final String providerName;
  final String? providerAddress;
  final double? rating;
  final double price;
  final String status;
  final int? distance; // Distance in meters from booking location
  final double? latitude;
  final double? longitude;

  BookingOffer({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    this.providerAddress,
    this.rating,
    required this.price,
    required this.status,
    this.distance,
    this.latitude,
    this.longitude,
  });

  /// Get formatted distance string (e.g., "1.5 km" or "500 m")
  String? get formattedDistance {
    if (distance == null) return null;
    if (distance! < 1000) {
      return '$distance m';
    } else {
      return '${(distance! / 1000).toStringAsFixed(1)} km';
    }
  }

  factory BookingOffer.fromJson(Map<String, dynamic> json) {
    return BookingOffer(
      id: int.parse(json['id'].toString()),
      bookingId: int.parse(json['bookingId'].toString()),
      providerId: int.parse(json['providerId'].toString()),
      providerName: json['providerName'] ?? 'Unknown',
      providerAddress: json['providerAddress'],
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      price: double.parse(json['price'].toString()),
      status: json['status'],
      distance: json['distance'] != null
          ? int.tryParse(json['distance'].toString())
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }
}

class Booking {
  final String id;
  final String code;
  final String status;
  final DateTime? scheduledAt;
  final String? addressText;
  final String? notes; // Customer instructions
  final String? estimatedPrice;
  final String? actualPrice; // Price after provider marks complete
  final String? serviceName;
  final String? categoryName;
  final String? providerName;
  final String? providerAddress; // Provider's work address
  final String? customerName;
  final int? distance; // Distance in meters from provider
  final double? latitude;
  final double? longitude;
  final String? bookingType; // 'DIRECT' or 'GENERAL'
  final bool isDirectBooking;
  final bool hasReview;
  final BookingReview? review;
  final int offersCount;
  final int? serviceId;
  final int? providerId;
  final List<Map<String, dynamic>>?
      selectedItems; // Items pre-selected by customer
  final String? paymentStatus;
  final String? paymentMethod;
  final String? bookingPaymentId;
  final DateTime? autoReleaseAt;

  Booking({
    required this.id,
    required this.code,
    required this.status,
    this.scheduledAt,
    this.addressText,
    this.notes,
    this.estimatedPrice,
    this.actualPrice,
    this.serviceName,
    this.categoryName,
    this.providerName,
    this.providerAddress,
    this.customerName,
    this.distance,
    this.latitude,
    this.longitude,
    this.bookingType,
    this.isDirectBooking = false,
    this.hasReview = false,
    this.review,
    this.offersCount = 0,
    this.serviceId,
    this.providerId,
    this.selectedItems,
    this.paymentStatus,
    this.paymentMethod,
    this.bookingPaymentId,
    this.autoReleaseAt,
  });

  /// Get the final price (actualPrice takes precedence over estimatedPrice)
  String? get finalPrice => actualPrice ?? estimatedPrice;

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Parse selectedItems if present
    List<Map<String, dynamic>>? selectedItems;
    if (json['selectedItems'] != null && json['selectedItems'] is List) {
      selectedItems = (json['selectedItems'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return Booking(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      status: json['status'] ?? 'pending',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString())
          : null,
      addressText: json['addressText'] as String?,
      notes: json['notes'] as String?,
      estimatedPrice: json['estimatedPrice']?.toString(),
      actualPrice: json['actualPrice']?.toString(),
      serviceName: json['service']?['name'] ?? json['serviceName'] ?? 'Dịch vụ',
      categoryName: json['categoryName'] as String?,
      providerName: json['provider']?['fullName'] ?? json['providerName'],
      providerAddress: json['provider']?['address'] as String?,
      customerName: json['customer']?['fullName'] ?? json['customerName'],
      distance:
          json['distance'] != null ? (json['distance'] as num).toInt() : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      bookingType: json['bookingType'] as String?,
      isDirectBooking: json['isDirectBooking'] == true,
      hasReview: json['hasReview'] == true,
      review: json['review'] != null
          ? BookingReview.fromJson(json['review'])
          : null,
      offersCount: json['offersCount'] ?? 0,
      serviceId: _parseIntSafe(json['serviceId'] ?? json['service']?['id']),
      providerId: _parseIntSafe(json['providerId'] ?? json['provider']?['id']),
      selectedItems: selectedItems,
      paymentStatus: json['paymentStatus'],
      paymentMethod: json['paymentMethod'],
      bookingPaymentId: json['bookingPaymentId']?.toString(),
      autoReleaseAt: json['autoReleaseAt'] != null
          ? DateTime.tryParse(json['autoReleaseAt'].toString())
          : null,
    );
  }

  static int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Review info attached to a booking
class BookingReview {
  final String id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  BookingReview({
    required this.id,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory BookingReview.fromJson(Map<String, dynamic> json) {
    return BookingReview(
      id: json['id']?.toString() ?? '',
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating'].toString()) ?? 5,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
