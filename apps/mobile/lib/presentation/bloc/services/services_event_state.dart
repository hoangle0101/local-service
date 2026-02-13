import 'package:equatable/equatable.dart';
import '../../../core/entities/entities.dart';

// Events
abstract class ServicesEvent extends Equatable {
  const ServicesEvent();

  @override
  List<Object?> get props => [];
}

class LoadServices extends ServicesEvent {
  final int limit;

  const LoadServices({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadServicesByCategory extends ServicesEvent {
  final int categoryId;
  final int limit;

  const LoadServicesByCategory({required this.categoryId, this.limit = 20});

  @override
  List<Object?> get props => [categoryId, limit];
}

class SearchNearbyProviders extends ServicesEvent {
  final int serviceId;
  final double latitude;
  final double longitude;
  final int limit;

  const SearchNearbyProviders({
    required this.serviceId,
    required this.latitude,
    required this.longitude,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [serviceId, latitude, longitude, limit];
}

class LoadGenericServices extends ServicesEvent {
  final int categoryId;

  const LoadGenericServices({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class LoadServiceDetails extends ServicesEvent {
  final int serviceId;

  const LoadServiceDetails(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

// States
abstract class ServicesState extends Equatable {
  const ServicesState();

  @override
  List<Object?> get props => [];
}

class ServicesInitial extends ServicesState {}

class ServicesLoading extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<ProviderService> services;

  const ServicesLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

class GenericServicesLoaded extends ServicesState {
  final List<Service> services;

  const GenericServicesLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

class ServiceDetailsLoaded extends ServicesState {
  final ProviderService service;

  const ServiceDetailsLoaded(this.service);

  @override
  List<Object?> get props => [service];
}

class ServicesError extends ServicesState {
  final String message;

  const ServicesError(this.message);

  @override
  List<Object?> get props => [message];
}
