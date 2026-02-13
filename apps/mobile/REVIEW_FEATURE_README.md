# ⭐ Review & Rating Feature

Complete implementation of user review and rating system for the Local Service Platform mobile app.

## 📦 What's Included

### Data Layer
- **ReviewModel** - Freezed model with JSON serialization
- **ReviewDataSource** - Dio-based API client
- **ReviewRepository** - Business logic with validation

### State Management
- **Riverpod Providers** - FutureProvider for data fetching, StateNotifier for form state
- **ReviewFormState** - Immutable form state management
- **ReviewFormNotifier** - Stateful form mutations

### UI Components
1. **StarRatingBar** - Interactive star rating (1-5 stars)
2. **ReviewFormWidget** - Full form with title, rating, comment
3. **ReviewCardWidget** - Display individual reviews
4. **ReviewDialog** - Modal dialog for quick review submission
5. **QuickReviewDialog** - Simplified rating-only dialog

### Features
✅ Interactive 5-star rating system  
✅ Review title and detailed comments  
✅ Real-time form validation  
✅ Loading and error states  
✅ Success notifications  
✅ Async data management with Riverpod  
✅ JSON serialization with Freezed  
✅ Responsive UI design  
✅ Upwork-inspired color scheme  

## 🎨 Design System

All colors follow the app's existing color palette:
- **Primary**: Green #14A800 (active stars, buttons)
- **Text**: Dark grey #111827
- **Secondary Text**: Medium grey #6B7280
- **Borders**: Light grey #E5E7EB
- **Background**: White #FFFFFF

## 📂 File Structure

```
lib/
├── data/
│   ├── models/
│   │   └── review_model.dart
│   ├── datasources/
│   │   └── review_datasource.dart
│   └── repositories/
│       └── review_repository.dart
├── presentation/
│   ├── providers/
│   │   └── review_provider.dart
│   └── widgets/
│       ├── star_rating_bar.dart
│       ├── review_form_widget.dart
│       ├── review_card_widget.dart
│       └── review_dialog.dart
└── core/
    └── constants/
        └── review_constants.dart
```

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd apps/mobile
flutter pub get
```

### 2. Generate Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Use in Your Screen
```dart
// Show review dialog after booking completion
QuickReviewDialog.show(
  context: context,
  bookingId: bookingId,
  revieweeId: providerId,
  onSubmitSuccess: () {
    // Handle success
  },
);
```

## 📋 API Integration

Expected backend endpoints:
- `POST /api/reviews/bookings/{id}` - Create review
- `GET /api/reviews/bookings/{id}` - Get reviews
- `GET /api/reviews/users/{id}/received` - Provider's reviews
- `GET /api/reviews/users/{id}/statistics` - Rating stats
- `DELETE /api/reviews/{id}` - Delete review

## 🔧 Configuration

Update API base URL in `review_provider.dart`:
```dart
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'http://your-api-url:3000',
    ),
  );
});
```

## 📊 Form Validation

- **Rating**: Required (1-5 stars)
- **Title**: Required, max 100 chars
- **Comment**: Optional, max 500 chars

## 🎯 State Management Details

### Providers

```dart
// Fetch reviews for a booking
fetchReviewsByBookingProvider(bookingId)

// Fetch provider's received reviews (paginated)
fetchUserReceivedReviewsProvider((userId, page, pageSize))

// Fetch user's given reviews
fetchUserGivenReviewsProvider(userId)

// Get rating statistics
fetchReviewStatisticsProvider(userId)

// Check if already reviewed
hasUserReviewedBookingProvider((bookingId, userId))

// Submit review
submitReviewProvider(request)
```

### Form State

```dart
ReviewFormState {
  int rating;           // 0-5
  String title;         // Review title
  String comment;       // Detailed comment
  bool isSubmitting;    // Loading state
  String? errorMessage; // Error message
}
```

## 💡 Usage Examples

### Fetch and Display Reviews
```dart
final reviewsAsync = ref.watch(fetchReviewsByBookingProvider(bookingId));

reviewsAsync.when(
  data: (reviews) => ReviewListWidget(reviews: reviews),
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => ErrorWidget(error: err),
);
```

### Get Provider Rating
```dart
final statsAsync = ref.watch(fetchReviewStatisticsProvider(providerId));

statsAsync.when(
  data: (stats) => Text('Rating: ${stats.averageRating.toStringAsFixed(1)}'),
  loading: () => const SizedBox(),
  error: (_, __) => const SizedBox(),
);
```

## 🎨 Customization

### Change Star Color
```dart
StarRatingBar(
  activeColor: Colors.orange,
  inactiveColor: Colors.grey,
)
```

### Modify Max Comment Length
```dart
// In review_constants.dart
static const int maxCommentLength = 1000;
```

## 🧪 Testing

All widgets are compatible with Flutter testing:
- StarRatingBar supports manual rating selection testing
- ReviewFormWidget validates form state changes
- Riverpod providers can be overridden for testing

## 📝 Notes

- All models use Freezed for immutability and code generation
- JSON serialization is automatic via json_serializable
- Riverpod handles all async operations and caching
- Form state is auto-disposed to prevent memory leaks
- All API errors are converted to readable exception messages

## 🔗 Related Files

See `REVIEW_FEATURE_INTEGRATION.md` for detailed integration guide.

## ✅ Status

- ✅ Data Layer (Models, DataSource, Repository)
- ✅ State Management (Riverpod Providers)
- ✅ UI Components (Widgets, Dialogs)
- ✅ Constants & Enums
- ⏳ Backend API Integration (needs endpoint verification)
- ⏳ Unit Tests
- ⏳ Integration Tests

---

**Ready to integrate! Check REVIEW_FEATURE_INTEGRATION.md for detailed steps.** 🚀
