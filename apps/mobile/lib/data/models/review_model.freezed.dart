// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Review _$ReviewFromJson(Map<String, dynamic> json) {
  return _Review.fromJson(json);
}

/// @nodoc
mixin _$Review {
  int get id => throw _privateConstructorUsedError;
  int get bookingId => throw _privateConstructorUsedError;
  int get reviewerId => throw _privateConstructorUsedError;
  int get revieweeId => throw _privateConstructorUsedError;
  int get rating => throw _privateConstructorUsedError; // 1-5 stars
  String? get title => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Review to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReviewCopyWith<Review> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReviewCopyWith<$Res> {
  factory $ReviewCopyWith(Review value, $Res Function(Review) then) =
      _$ReviewCopyWithImpl<$Res, Review>;
  @useResult
  $Res call(
      {int id,
      int bookingId,
      int reviewerId,
      int revieweeId,
      int rating,
      String? title,
      String? comment,
      DateTime createdAt});
}

/// @nodoc
class _$ReviewCopyWithImpl<$Res, $Val extends Review>
    implements $ReviewCopyWith<$Res> {
  _$ReviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookingId = null,
    Object? reviewerId = null,
    Object? revieweeId = null,
    Object? rating = null,
    Object? title = freezed,
    Object? comment = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      bookingId: null == bookingId
          ? _value.bookingId
          : bookingId // ignore: cast_nullable_to_non_nullable
              as int,
      reviewerId: null == reviewerId
          ? _value.reviewerId
          : reviewerId // ignore: cast_nullable_to_non_nullable
              as int,
      revieweeId: null == revieweeId
          ? _value.revieweeId
          : revieweeId // ignore: cast_nullable_to_non_nullable
              as int,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReviewImplCopyWith<$Res> implements $ReviewCopyWith<$Res> {
  factory _$$ReviewImplCopyWith(
          _$ReviewImpl value, $Res Function(_$ReviewImpl) then) =
      __$$ReviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int bookingId,
      int reviewerId,
      int revieweeId,
      int rating,
      String? title,
      String? comment,
      DateTime createdAt});
}

/// @nodoc
class __$$ReviewImplCopyWithImpl<$Res>
    extends _$ReviewCopyWithImpl<$Res, _$ReviewImpl>
    implements _$$ReviewImplCopyWith<$Res> {
  __$$ReviewImplCopyWithImpl(
      _$ReviewImpl _value, $Res Function(_$ReviewImpl) _then)
      : super(_value, _then);

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookingId = null,
    Object? reviewerId = null,
    Object? revieweeId = null,
    Object? rating = null,
    Object? title = freezed,
    Object? comment = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$ReviewImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      bookingId: null == bookingId
          ? _value.bookingId
          : bookingId // ignore: cast_nullable_to_non_nullable
              as int,
      reviewerId: null == reviewerId
          ? _value.reviewerId
          : reviewerId // ignore: cast_nullable_to_non_nullable
              as int,
      revieweeId: null == revieweeId
          ? _value.revieweeId
          : revieweeId // ignore: cast_nullable_to_non_nullable
              as int,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReviewImpl with DiagnosticableTreeMixin implements _Review {
  const _$ReviewImpl(
      {required this.id,
      required this.bookingId,
      required this.reviewerId,
      required this.revieweeId,
      required this.rating,
      this.title,
      this.comment,
      required this.createdAt});

  factory _$ReviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReviewImplFromJson(json);

  @override
  final int id;
  @override
  final int bookingId;
  @override
  final int reviewerId;
  @override
  final int revieweeId;
  @override
  final int rating;
// 1-5 stars
  @override
  final String? title;
  @override
  final String? comment;
  @override
  final DateTime createdAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Review(id: $id, bookingId: $bookingId, reviewerId: $reviewerId, revieweeId: $revieweeId, rating: $rating, title: $title, comment: $comment, createdAt: $createdAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Review'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('bookingId', bookingId))
      ..add(DiagnosticsProperty('reviewerId', reviewerId))
      ..add(DiagnosticsProperty('revieweeId', revieweeId))
      ..add(DiagnosticsProperty('rating', rating))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('comment', comment))
      ..add(DiagnosticsProperty('createdAt', createdAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReviewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.reviewerId, reviewerId) ||
                other.reviewerId == reviewerId) &&
            (identical(other.revieweeId, revieweeId) ||
                other.revieweeId == revieweeId) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, bookingId, reviewerId,
      revieweeId, rating, title, comment, createdAt);

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReviewImplCopyWith<_$ReviewImpl> get copyWith =>
      __$$ReviewImplCopyWithImpl<_$ReviewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReviewImplToJson(
      this,
    );
  }
}

abstract class _Review implements Review {
  const factory _Review(
      {required final int id,
      required final int bookingId,
      required final int reviewerId,
      required final int revieweeId,
      required final int rating,
      final String? title,
      final String? comment,
      required final DateTime createdAt}) = _$ReviewImpl;

  factory _Review.fromJson(Map<String, dynamic> json) = _$ReviewImpl.fromJson;

  @override
  int get id;
  @override
  int get bookingId;
  @override
  int get reviewerId;
  @override
  int get revieweeId;
  @override
  int get rating; // 1-5 stars
  @override
  String? get title;
  @override
  String? get comment;
  @override
  DateTime get createdAt;

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReviewImplCopyWith<_$ReviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateReviewRequest _$CreateReviewRequestFromJson(Map<String, dynamic> json) {
  return _CreateReviewRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateReviewRequest {
  int get bookingId => throw _privateConstructorUsedError;
  int get revieweeId => throw _privateConstructorUsedError;
  int get rating => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;

  /// Serializes this CreateReviewRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateReviewRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateReviewRequestCopyWith<CreateReviewRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateReviewRequestCopyWith<$Res> {
  factory $CreateReviewRequestCopyWith(
          CreateReviewRequest value, $Res Function(CreateReviewRequest) then) =
      _$CreateReviewRequestCopyWithImpl<$Res, CreateReviewRequest>;
  @useResult
  $Res call(
      {int bookingId,
      int revieweeId,
      int rating,
      String? title,
      String? comment});
}

/// @nodoc
class _$CreateReviewRequestCopyWithImpl<$Res, $Val extends CreateReviewRequest>
    implements $CreateReviewRequestCopyWith<$Res> {
  _$CreateReviewRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateReviewRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookingId = null,
    Object? revieweeId = null,
    Object? rating = null,
    Object? title = freezed,
    Object? comment = freezed,
  }) {
    return _then(_value.copyWith(
      bookingId: null == bookingId
          ? _value.bookingId
          : bookingId // ignore: cast_nullable_to_non_nullable
              as int,
      revieweeId: null == revieweeId
          ? _value.revieweeId
          : revieweeId // ignore: cast_nullable_to_non_nullable
              as int,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CreateReviewRequestImplCopyWith<$Res>
    implements $CreateReviewRequestCopyWith<$Res> {
  factory _$$CreateReviewRequestImplCopyWith(_$CreateReviewRequestImpl value,
          $Res Function(_$CreateReviewRequestImpl) then) =
      __$$CreateReviewRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int bookingId,
      int revieweeId,
      int rating,
      String? title,
      String? comment});
}

/// @nodoc
class __$$CreateReviewRequestImplCopyWithImpl<$Res>
    extends _$CreateReviewRequestCopyWithImpl<$Res, _$CreateReviewRequestImpl>
    implements _$$CreateReviewRequestImplCopyWith<$Res> {
  __$$CreateReviewRequestImplCopyWithImpl(_$CreateReviewRequestImpl _value,
      $Res Function(_$CreateReviewRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of CreateReviewRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookingId = null,
    Object? revieweeId = null,
    Object? rating = null,
    Object? title = freezed,
    Object? comment = freezed,
  }) {
    return _then(_$CreateReviewRequestImpl(
      bookingId: null == bookingId
          ? _value.bookingId
          : bookingId // ignore: cast_nullable_to_non_nullable
              as int,
      revieweeId: null == revieweeId
          ? _value.revieweeId
          : revieweeId // ignore: cast_nullable_to_non_nullable
              as int,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateReviewRequestImpl
    with DiagnosticableTreeMixin
    implements _CreateReviewRequest {
  const _$CreateReviewRequestImpl(
      {required this.bookingId,
      required this.revieweeId,
      required this.rating,
      this.title,
      this.comment});

  factory _$CreateReviewRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateReviewRequestImplFromJson(json);

  @override
  final int bookingId;
  @override
  final int revieweeId;
  @override
  final int rating;
  @override
  final String? title;
  @override
  final String? comment;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CreateReviewRequest(bookingId: $bookingId, revieweeId: $revieweeId, rating: $rating, title: $title, comment: $comment)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CreateReviewRequest'))
      ..add(DiagnosticsProperty('bookingId', bookingId))
      ..add(DiagnosticsProperty('revieweeId', revieweeId))
      ..add(DiagnosticsProperty('rating', rating))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('comment', comment));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateReviewRequestImpl &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.revieweeId, revieweeId) ||
                other.revieweeId == revieweeId) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.comment, comment) || other.comment == comment));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, bookingId, revieweeId, rating, title, comment);

  /// Create a copy of CreateReviewRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateReviewRequestImplCopyWith<_$CreateReviewRequestImpl> get copyWith =>
      __$$CreateReviewRequestImplCopyWithImpl<_$CreateReviewRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateReviewRequestImplToJson(
      this,
    );
  }
}

abstract class _CreateReviewRequest implements CreateReviewRequest {
  const factory _CreateReviewRequest(
      {required final int bookingId,
      required final int revieweeId,
      required final int rating,
      final String? title,
      final String? comment}) = _$CreateReviewRequestImpl;

  factory _CreateReviewRequest.fromJson(Map<String, dynamic> json) =
      _$CreateReviewRequestImpl.fromJson;

  @override
  int get bookingId;
  @override
  int get revieweeId;
  @override
  int get rating;
  @override
  String? get title;
  @override
  String? get comment;

  /// Create a copy of CreateReviewRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateReviewRequestImplCopyWith<_$CreateReviewRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReviewListResponse _$ReviewListResponseFromJson(Map<String, dynamic> json) {
  return _ReviewListResponse.fromJson(json);
}

/// @nodoc
mixin _$ReviewListResponse {
  List<Review> get reviews => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;

  /// Serializes this ReviewListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReviewListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReviewListResponseCopyWith<ReviewListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReviewListResponseCopyWith<$Res> {
  factory $ReviewListResponseCopyWith(
          ReviewListResponse value, $Res Function(ReviewListResponse) then) =
      _$ReviewListResponseCopyWithImpl<$Res, ReviewListResponse>;
  @useResult
  $Res call({List<Review> reviews, int total, int page, int pageSize});
}

/// @nodoc
class _$ReviewListResponseCopyWithImpl<$Res, $Val extends ReviewListResponse>
    implements $ReviewListResponseCopyWith<$Res> {
  _$ReviewListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReviewListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reviews = null,
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
  }) {
    return _then(_value.copyWith(
      reviews: null == reviews
          ? _value.reviews
          : reviews // ignore: cast_nullable_to_non_nullable
              as List<Review>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReviewListResponseImplCopyWith<$Res>
    implements $ReviewListResponseCopyWith<$Res> {
  factory _$$ReviewListResponseImplCopyWith(_$ReviewListResponseImpl value,
          $Res Function(_$ReviewListResponseImpl) then) =
      __$$ReviewListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Review> reviews, int total, int page, int pageSize});
}

/// @nodoc
class __$$ReviewListResponseImplCopyWithImpl<$Res>
    extends _$ReviewListResponseCopyWithImpl<$Res, _$ReviewListResponseImpl>
    implements _$$ReviewListResponseImplCopyWith<$Res> {
  __$$ReviewListResponseImplCopyWithImpl(_$ReviewListResponseImpl _value,
      $Res Function(_$ReviewListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReviewListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reviews = null,
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
  }) {
    return _then(_$ReviewListResponseImpl(
      reviews: null == reviews
          ? _value._reviews
          : reviews // ignore: cast_nullable_to_non_nullable
              as List<Review>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReviewListResponseImpl
    with DiagnosticableTreeMixin
    implements _ReviewListResponse {
  const _$ReviewListResponseImpl(
      {required final List<Review> reviews,
      required this.total,
      required this.page,
      required this.pageSize})
      : _reviews = reviews;

  factory _$ReviewListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReviewListResponseImplFromJson(json);

  final List<Review> _reviews;
  @override
  List<Review> get reviews {
    if (_reviews is EqualUnmodifiableListView) return _reviews;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reviews);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int pageSize;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ReviewListResponse(reviews: $reviews, total: $total, page: $page, pageSize: $pageSize)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ReviewListResponse'))
      ..add(DiagnosticsProperty('reviews', reviews))
      ..add(DiagnosticsProperty('total', total))
      ..add(DiagnosticsProperty('page', page))
      ..add(DiagnosticsProperty('pageSize', pageSize));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReviewListResponseImpl &&
            const DeepCollectionEquality().equals(other._reviews, _reviews) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_reviews), total, page, pageSize);

  /// Create a copy of ReviewListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReviewListResponseImplCopyWith<_$ReviewListResponseImpl> get copyWith =>
      __$$ReviewListResponseImplCopyWithImpl<_$ReviewListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReviewListResponseImplToJson(
      this,
    );
  }
}

abstract class _ReviewListResponse implements ReviewListResponse {
  const factory _ReviewListResponse(
      {required final List<Review> reviews,
      required final int total,
      required final int page,
      required final int pageSize}) = _$ReviewListResponseImpl;

  factory _ReviewListResponse.fromJson(Map<String, dynamic> json) =
      _$ReviewListResponseImpl.fromJson;

  @override
  List<Review> get reviews;
  @override
  int get total;
  @override
  int get page;
  @override
  int get pageSize;

  /// Create a copy of ReviewListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReviewListResponseImplCopyWith<_$ReviewListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReviewStatistics _$ReviewStatisticsFromJson(Map<String, dynamic> json) {
  return _ReviewStatistics.fromJson(json);
}

/// @nodoc
mixin _$ReviewStatistics {
  double get averageRating => throw _privateConstructorUsedError;
  int get totalReviews => throw _privateConstructorUsedError;
  Map<int, int> get ratingDistribution => throw _privateConstructorUsedError;

  /// Serializes this ReviewStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReviewStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReviewStatisticsCopyWith<ReviewStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReviewStatisticsCopyWith<$Res> {
  factory $ReviewStatisticsCopyWith(
          ReviewStatistics value, $Res Function(ReviewStatistics) then) =
      _$ReviewStatisticsCopyWithImpl<$Res, ReviewStatistics>;
  @useResult
  $Res call(
      {double averageRating,
      int totalReviews,
      Map<int, int> ratingDistribution});
}

/// @nodoc
class _$ReviewStatisticsCopyWithImpl<$Res, $Val extends ReviewStatistics>
    implements $ReviewStatisticsCopyWith<$Res> {
  _$ReviewStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReviewStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? averageRating = null,
    Object? totalReviews = null,
    Object? ratingDistribution = null,
  }) {
    return _then(_value.copyWith(
      averageRating: null == averageRating
          ? _value.averageRating
          : averageRating // ignore: cast_nullable_to_non_nullable
              as double,
      totalReviews: null == totalReviews
          ? _value.totalReviews
          : totalReviews // ignore: cast_nullable_to_non_nullable
              as int,
      ratingDistribution: null == ratingDistribution
          ? _value.ratingDistribution
          : ratingDistribution // ignore: cast_nullable_to_non_nullable
              as Map<int, int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReviewStatisticsImplCopyWith<$Res>
    implements $ReviewStatisticsCopyWith<$Res> {
  factory _$$ReviewStatisticsImplCopyWith(_$ReviewStatisticsImpl value,
          $Res Function(_$ReviewStatisticsImpl) then) =
      __$$ReviewStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double averageRating,
      int totalReviews,
      Map<int, int> ratingDistribution});
}

/// @nodoc
class __$$ReviewStatisticsImplCopyWithImpl<$Res>
    extends _$ReviewStatisticsCopyWithImpl<$Res, _$ReviewStatisticsImpl>
    implements _$$ReviewStatisticsImplCopyWith<$Res> {
  __$$ReviewStatisticsImplCopyWithImpl(_$ReviewStatisticsImpl _value,
      $Res Function(_$ReviewStatisticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReviewStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? averageRating = null,
    Object? totalReviews = null,
    Object? ratingDistribution = null,
  }) {
    return _then(_$ReviewStatisticsImpl(
      averageRating: null == averageRating
          ? _value.averageRating
          : averageRating // ignore: cast_nullable_to_non_nullable
              as double,
      totalReviews: null == totalReviews
          ? _value.totalReviews
          : totalReviews // ignore: cast_nullable_to_non_nullable
              as int,
      ratingDistribution: null == ratingDistribution
          ? _value._ratingDistribution
          : ratingDistribution // ignore: cast_nullable_to_non_nullable
              as Map<int, int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReviewStatisticsImpl
    with DiagnosticableTreeMixin
    implements _ReviewStatistics {
  const _$ReviewStatisticsImpl(
      {required this.averageRating,
      required this.totalReviews,
      required final Map<int, int> ratingDistribution})
      : _ratingDistribution = ratingDistribution;

  factory _$ReviewStatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReviewStatisticsImplFromJson(json);

  @override
  final double averageRating;
  @override
  final int totalReviews;
  final Map<int, int> _ratingDistribution;
  @override
  Map<int, int> get ratingDistribution {
    if (_ratingDistribution is EqualUnmodifiableMapView)
      return _ratingDistribution;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_ratingDistribution);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ReviewStatistics(averageRating: $averageRating, totalReviews: $totalReviews, ratingDistribution: $ratingDistribution)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ReviewStatistics'))
      ..add(DiagnosticsProperty('averageRating', averageRating))
      ..add(DiagnosticsProperty('totalReviews', totalReviews))
      ..add(DiagnosticsProperty('ratingDistribution', ratingDistribution));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReviewStatisticsImpl &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            (identical(other.totalReviews, totalReviews) ||
                other.totalReviews == totalReviews) &&
            const DeepCollectionEquality()
                .equals(other._ratingDistribution, _ratingDistribution));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, averageRating, totalReviews,
      const DeepCollectionEquality().hash(_ratingDistribution));

  /// Create a copy of ReviewStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReviewStatisticsImplCopyWith<_$ReviewStatisticsImpl> get copyWith =>
      __$$ReviewStatisticsImplCopyWithImpl<_$ReviewStatisticsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReviewStatisticsImplToJson(
      this,
    );
  }
}

abstract class _ReviewStatistics implements ReviewStatistics {
  const factory _ReviewStatistics(
          {required final double averageRating,
          required final int totalReviews,
          required final Map<int, int> ratingDistribution}) =
      _$ReviewStatisticsImpl;

  factory _ReviewStatistics.fromJson(Map<String, dynamic> json) =
      _$ReviewStatisticsImpl.fromJson;

  @override
  double get averageRating;
  @override
  int get totalReviews;
  @override
  Map<int, int> get ratingDistribution;

  /// Create a copy of ReviewStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReviewStatisticsImplCopyWith<_$ReviewStatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
