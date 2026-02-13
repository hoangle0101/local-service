class BookingEntity {
  final String id;
  final String userId;
  final String providerUserId;
  final int serviceId;
  final String status;
  final DateTime? scheduledAt;
  final String? address;
  final Map<String, dynamic>? location;
  final double? estimatedPrice;
  final double? finalPrice;
  final String? currency;
  final String? notes;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingEntity({
    required this.id,
    required this.userId,
    required this.providerUserId,
    required this.serviceId,
    required this.status,
    this.scheduledAt,
    this.address,
    this.location,
    this.estimatedPrice,
    this.finalPrice,
    this.currency,
    this.notes,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingEntity.fromJson(Map<String, dynamic> json) {
    return BookingEntity(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      providerUserId: json['providerUserId'].toString(),
      serviceId: json['serviceId'] as int,
      status: json['status'] as String,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      address: json['address'] as String?,
      location: json['location'] as Map<String, dynamic>?,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      notes: json['notes'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
