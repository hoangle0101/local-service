# 📋 REVIEW FEATURE - INTEGRATION GUIDE

## 🎯 Các Files đã tạo

### Data Layer
- `lib/data/models/review_model.dart` - ReviewModel, CreateReviewRequest, ReviewListResponse, ReviewStatistics
- `lib/data/datasources/review_datasource.dart` - API calls
- `lib/data/repositories/review_repository.dart` - Business logic

### State Management (Riverpod)
- `lib/presentation/providers/review_provider.dart` - FutureProvider, StateNotifier, form state

### UI Widgets
- `lib/presentation/widgets/star_rating_bar.dart` - Interactive star rating
- `lib/presentation/widgets/review_form_widget.dart` - Full review form
- `lib/presentation/widgets/review_card_widget.dart` - Display reviews
- `lib/presentation/widgets/review_dialog.dart` - Modal dialog for quick review

### Constants
- `lib/core/constants/review_constants.dart` - Constants, enums, extensions

---

## 🚀 Setup Steps

### Step 1: Install Dependencies
```bash
cd apps/mobile
flutter pub get
```

### Step 2: Generate Code (Freezed, JSON)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 3: Wrap App with ProviderScope (if not already)
```dart
// lib/main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

---

## 💻 Usage Examples

### 1️⃣ Show Quick Review Dialog
```dart
import 'package:mobile/presentation/widgets/review_dialog.dart';

// In your booking completion screen
QuickReviewDialog.show(
  context: context,
  bookingId: bookingId,
  revieweeId: providerId,
  onSubmitSuccess: () {
    print('Review submitted!');
    // Refresh booking details or navigate away
  },
);
```

### 2️⃣ Show Full Review Form (Modal)
```dart
ReviewDialog.show(
  context: context,
  bookingId: bookingId,
  revieweeId: providerId,
  serviceTitle: 'Plumbing Service',
  onSubmitSuccess: () {
    // Handle success
  },
);
```

### 3️⃣ Fetch Reviews for Booking
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/presentation/providers/review_provider.dart';

class ReviewsWidget extends ConsumerWidget {
  final int bookingId;

  const ReviewsWidget({required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(fetchReviewsByBookingProvider(bookingId));

    return reviewsAsync.when(
      data: (reviews) => ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) => ReviewCardWidget(
          review: reviews[index],
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### 4️⃣ Get Provider Rating Statistics
```dart
final statsAsync = ref.watch(fetchReviewStatisticsProvider(providerId));

statsAsync.when(
  data: (stats) => Column(
    children: [
      Text('Average Rating: ${stats.averageRating.toStringAsFixed(1)}'),
      Text('Total Reviews: ${stats.totalReviews}'),
    ],
  ),
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

### 5️⃣ Check if User Already Reviewed
```dart
final hasReviewedAsync = ref.watch(
  hasUserReviewedBookingProvider(
    (bookingId: bookingId, userId: currentUserId),
  ),
);

hasReviewedAsync.when(
  data: (hasReviewed) {
    if (hasReviewed) {
      // Show "Already reviewed" message
    } else {
      // Show review button
    }
  },
  loading: () => const SizedBox(),
  error: (err, stack) => const SizedBox(),
);
```

---

## 🎨 Color Scheme

All colors are from `AppColors`:
- **Primary (Green)**: `AppColors.primary` (#14A800)
- **Text**: `AppColors.textPrimary` (#111827)
- **Secondary Text**: `AppColors.textSecondary` (#6B7280)
- **Border**: `AppColors.grey300` (#D1D5DB)
- **Success**: `AppColors.success` (#14A800)
- **Error**: `AppColors.error` (#D93025)

---

## 📱 Integration Points

### 1. Booking Detail Screen
Show "Leave Review" button after booking is completed:

```dart
// In booking_detail_screen.dart (EXISTING - only ADD new logic)
// Add this button after booking status is 'completed'

ElevatedButton(
  onPressed: () {
    ReviewDialog.show(
      context: context,
      bookingId: booking.id,
      revieweeId: booking.providerId,
      serviceTitle: booking.service.name,
    );
  },
  child: const Text('Leave Review'),
),
```

### 2. Provider Profile Screen
Show reviews and rating summary:

```dart
// In provider_profile_screen.dart (EXISTING)
// Add widget to display reviews:

final reviewsAsync = ref.watch(
  fetchUserReceivedReviewsProvider(
    (userId: providerId, page: 1, pageSize: 10),
  ),
);

reviewsAsync.when(
  data: (reviewList) => ReviewListWidget(
    reviews: reviewList.reviews,
    hasMore: reviewList.page < (reviewList.total / reviewList.pageSize).ceil(),
  ),
  loading: () => const LoadingWidget(),
  error: (err, stack) => ErrorWidget(error: err),
);
```

### 3. User Profile - Reviews Given
Show user's own reviews:

```dart
// In user_profile_screen.dart
final givenReviewsAsync = ref.watch(
  fetchUserGivenReviewsProvider(currentUserId),
);
```

---

## 🔄 State Management Flow

### Form State
```
reviewFormNotifierProvider
  ├── rating (0-5)
  ├── title (String)
  ├── comment (String)
  ├── isSubmitting (bool)
  └── errorMessage (String?)
```

### Data Fetching
```
fetchReviewsByBookingProvider(bookingId)
  → List<ReviewModel>

fetchUserReceivedReviewsProvider((userId, page, pageSize))
  → ReviewListResponse

fetchReviewStatisticsProvider(userId)
  → ReviewStatistics (avgRating, totalCount, distribution)
```

### Submission
```
submitReviewProvider(CreateReviewRequest)
  → ReviewModel (created review)
  → Invalidates related providers
```

---

## 🛠️ Customization

### Change Primary Color
Edit all widget colors by changing `AppColors.primary` usage to your preferred color.

### Modify Rating Scale
In `ReviewConstants`:
```dart
static const int maxRating = 5; // Change to 10 for 10-star system
```

### Add Helpful/Unhelpful Votes
The `ReviewCardWidget` already has a placeholder for "Was this review helpful?" action.
Add your implementation in the `onHelpfulTap` callback.

### Add Review Filtering
Use `ReviewFilterOption` enum in `review_constants.dart` to implement filters by rating.

---

## ⚠️ Important Notes

### Dependencies Required
```yaml
riverpod: ^2.4.0
flutter_riverpod: ^2.4.0
freezed_annotation: ^2.4.0
json_annotation: ^4.8.0
```

### API Endpoints Expected
Your backend should provide:
- `POST /api/reviews/bookings/{id}` - Create review
- `GET /api/reviews/bookings/{id}` - Get reviews by booking
- `GET /api/reviews/users/{id}/received` - Get provider's reviews
- `GET /api/reviews/users/{id}/given` - Get user's reviews given
- `GET /api/reviews/users/{id}/statistics` - Get rating statistics
- `DELETE /api/reviews/{id}` - Delete review

### Update Dio Base URL
In `review_provider.dart`:
```dart
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'your-api-url-here', // Update this!
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});
```

---

## 🧪 Testing

### Test Star Rating
```dart
// In test files
testWidgets('StarRatingBar allows rating selection', (tester) async {
  int selectedRating = 0;
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StarRatingBar(
          onRatingChanged: (rating) => selectedRating = rating,
        ),
      ),
    ),
  );

  await tester.tap(find.byIcon(Icons.star_rounded).at(3)); // 4th star
  await tester.pumpWidget(SizedBox());
  
  expect(selectedRating, equals(4));
});
```

### Test Review Form Validation
```dart
// Form should be invalid until rating selected
expect(formState.isValid, isFalse);

// After rating selected
formNotifier.setRating(4);
expect(formState.isValid, isFalse); // Still need title

// After title added
formNotifier.setTitle('Great service');
expect(formState.isValid, isTrue);
```

---

## 📚 Next Steps

1. ✅ Run `flutter pub get` and `build_runner`
2. ✅ Test individual widgets
3. ✅ Integrate into booking detail screen
4. ✅ Add to provider profile
5. ✅ Connect backend API
6. ✅ Test end-to-end flow

---

**All done! Your review feature is ready to integrate.** 🎉
