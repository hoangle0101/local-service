import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/marketplace_repository.dart';
import 'categories_event_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final MarketplaceRepository _repository;

  CategoriesBloc([MarketplaceRepository? repository])
      : _repository = repository ?? MarketplaceRepository(),
        super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      print('[CategoriesBloc] Loading categories...');
      final categories = await _repository.getCategories();
      print('[CategoriesBloc] Loaded ${categories.length} categories');
      emit(CategoriesLoaded(categories));
    } catch (e, stackTrace) {
      print('[CategoriesBloc] ERROR: $e');
      print('[CategoriesBloc] Stack: $stackTrace');
      emit(CategoriesError(e.toString()));
    }
  }
}
