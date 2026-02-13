/// Constants for review feature
class ReviewConstants {
  ReviewConstants._();

  // Rating constraints
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int defaultRating = 0; // Not rated

  // Text field limits
  static const int maxTitleLength = 100;
  static const int maxCommentLength = 500;

  // Validation messages
  static const String ratingRequiredMsg = 'Please select a rating';
  static const String titleRequiredMsg = 'Please enter a review title';
  static const String titleTooLongMsg =
      'Title cannot exceed $maxTitleLength characters';
  static const String commentTooLongMsg =
      'Comment cannot exceed $maxCommentLength characters';

  // Rating descriptions
  static const Map<int, String> ratingDescriptions = {
    1: 'Poor - Needs improvement',
    2: 'Fair - Could be better',
    3: 'Good - Satisfied',
    4: 'Very Good - Impressed',
    5: 'Excellent - Highly recommended',
  };

  // API endpoints
  static const String baseReviewPath = '/api/reviews';
  static const String bookingReviewsPath = '/api/reviews/bookings';
  static const String userReviewsPath = '/api/reviews/users';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration retryDelay = Duration(seconds: 2);
}

/// Enum for review sorting options
enum ReviewSortOption {
  newest,
  oldest,
  highestRating,
  lowestRating,
}

/// Enum for review filter options
enum ReviewFilterOption {
  all,
  fiveStar,
  fourStar,
  threeStar,
  twoStar,
  oneStar,
}

/// Extension for ReviewFilterOption to map to rating
extension ReviewFilterOptionExt on ReviewFilterOption {
  int? get rating {
    switch (this) {
      case ReviewFilterOption.fiveStar:
        return 5;
      case ReviewFilterOption.fourStar:
        return 4;
      case ReviewFilterOption.threeStar:
        return 3;
      case ReviewFilterOption.twoStar:
        return 2;
      case ReviewFilterOption.oneStar:
        return 1;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case ReviewFilterOption.all:
        return 'All';
      case ReviewFilterOption.fiveStar:
        return '⭐ 5 Stars';
      case ReviewFilterOption.fourStar:
        return '⭐ 4 Stars';
      case ReviewFilterOption.threeStar:
        return '⭐ 3 Stars';
      case ReviewFilterOption.twoStar:
        return '⭐ 2 Stars';
      case ReviewFilterOption.oneStar:
        return '⭐ 1 Star';
    }
  }
}
