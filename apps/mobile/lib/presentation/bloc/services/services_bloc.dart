import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/marketplace_repository.dart';
import 'services_event_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final MarketplaceRepository _repository;

  ServicesBloc([MarketplaceRepository? repository])
      : _repository = repository ?? MarketplaceRepository(),
        super(ServicesInitial()) {
    on<LoadServices>(_onLoadServices);
    on<LoadServicesByCategory>(_onLoadServicesByCategory);
    on<LoadGenericServices>(_onLoadGenericServices);
    on<SearchNearbyProviders>(_onSearchNearbyProviders);
    on<LoadServiceDetails>(_onLoadServiceDetails);
  }

  Future<void> _onLoadServices(
    LoadServices event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      print('[ServicesBloc] Loading services...');
      final services = await _repository.searchServices(limit: event.limit);
      print('[ServicesBloc] Loaded ${services.length} services');
      emit(ServicesLoaded(services));
    } catch (e, stackTrace) {
      print('[ServicesBloc] ERROR: $e');
      print('[ServicesBloc] Stack: $stackTrace');
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onLoadServicesByCategory(
    LoadServicesByCategory event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      final services = await _repository.searchServices(
        limit: event.limit,
        categoryId: event.categoryId,
      );
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onSearchNearbyProviders(
    SearchNearbyProviders event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      final services = await _repository.searchServices(
        serviceId: event.serviceId,
        latitude: event.latitude,
        longitude: event.longitude,
        limit: event.limit,
      );
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onLoadGenericServices(
    LoadGenericServices event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      final services = await _repository.getGenericServices(event.categoryId);
      emit(GenericServicesLoaded(services));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onLoadServiceDetails(
    LoadServiceDetails event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      final service = await _repository.getServiceById(event.serviceId);
      emit(ServiceDetailsLoaded(service));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }
}
