import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../data/datasources/favorites_datasource.dart' show FavoriteItem;

// Events
abstract class FavoritesEvent {}

class LoadFavorites extends FavoritesEvent {}

class ToggleFavorite extends FavoritesEvent {
  final int serviceId;
  ToggleFavorite(this.serviceId);
}

class RemoveFavorite extends FavoritesEvent {
  final int serviceId;
  RemoveFavorite(this.serviceId);
}

// States
abstract class FavoritesState {
  final Set<int> favoriteIds;
  const FavoritesState({this.favoriteIds = const {}});
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial() : super();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading({super.favoriteIds});
}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteItem> items;

  const FavoritesLoaded({
    required this.items,
    required Set<int> favoriteIds,
  }) : super(favoriteIds: favoriteIds);
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError({
    required this.message,
    super.favoriteIds,
  });
}

// BLoC
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesBloc({FavoritesRepository? repository})
      : _repository = repository ?? FavoritesRepository(),
        super(const FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<RemoveFavorite>(_onRemoveFavorite);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading(favoriteIds: state.favoriteIds));

    try {
      final items = await _repository.getFavorites();
      final favoriteIds = items.map((item) => item.serviceId).toSet();

      emit(FavoritesLoaded(items: items, favoriteIds: favoriteIds));
    } catch (e) {
      emit(FavoritesError(
        message: e.toString(),
        favoriteIds: state.favoriteIds,
      ));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    final originalFavoriteIds = state.favoriteIds;
    final isFavorite = originalFavoriteIds.contains(event.serviceId);

    // Optimistic update
    final newFavoriteIds = Set<int>.from(originalFavoriteIds);
    if (isFavorite) {
      newFavoriteIds.remove(event.serviceId);
    } else {
      newFavoriteIds.add(event.serviceId);
    }

    // Emit optimistic state
    if (state is FavoritesLoaded) {
      final currentItems = (state as FavoritesLoaded).items;
      emit(FavoritesLoaded(
        items: isFavorite
            ? currentItems.where((i) => i.serviceId != event.serviceId).toList()
            : currentItems,
        favoriteIds: newFavoriteIds,
      ));
    } else {
      emit(FavoritesLoading(favoriteIds: newFavoriteIds));
    }

    // Perform API call
    bool success;
    if (isFavorite) {
      success = await _repository.removeFavorite(event.serviceId);
    } else {
      success = await _repository.addFavorite(event.serviceId);
    }

    // Handle result
    if (!success) {
      // Revert to original state on failure
      if (state is FavoritesLoaded) {
        emit(FavoritesLoaded(
          items: (state as FavoritesLoaded).items,
          favoriteIds: originalFavoriteIds,
        ));
      } else {
        emit(FavoritesLoading(favoriteIds: originalFavoriteIds));
      }
    } else {
      // Refresh to ensure full synchronization with server
      add(LoadFavorites());
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    final originalFavoriteIds = state.favoriteIds;

    // Optimistic update
    final newFavoriteIds = Set<int>.from(originalFavoriteIds)
      ..remove(event.serviceId);

    if (state is FavoritesLoaded) {
      final currentItems = (state as FavoritesLoaded).items;
      emit(FavoritesLoaded(
        items:
            currentItems.where((i) => i.serviceId != event.serviceId).toList(),
        favoriteIds: newFavoriteIds,
      ));
    } else {
      emit(FavoritesLoading(favoriteIds: newFavoriteIds));
    }

    // Perform API call
    final success = await _repository.removeFavorite(event.serviceId);

    // Handle result
    if (!success) {
      // Revert on failure
      if (state is FavoritesLoaded) {
        emit(FavoritesLoaded(
          items: (state as FavoritesLoaded).items,
          favoriteIds: originalFavoriteIds,
        ));
      } else {
        emit(FavoritesLoading(favoriteIds: originalFavoriteIds));
      }
    } else {
      // Refresh to ensure full synchronization
      add(LoadFavorites());
    }
  }

  /// Check if a service is favorited
  bool isFavorite(int serviceId) => state.favoriteIds.contains(serviceId);
}
