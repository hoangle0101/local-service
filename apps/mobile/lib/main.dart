import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/auth/auth_bloc.dart';
import 'package:mobile/presentation/bloc/categories/categories_bloc.dart';
import 'package:mobile/presentation/bloc/services/services_bloc.dart';
import 'package:mobile/presentation/bloc/bookings/bookings_bloc.dart';
import 'package:mobile/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:mobile/presentation/bloc/notifications/notifications_bloc.dart';
import 'package:mobile/presentation/bloc/notifications/notifications_event.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/theme/app_theme.dart';

import 'core/services/socket_service.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<CategoriesBloc>(
          create: (_) => CategoriesBloc(),
        ),
        BlocProvider<ServicesBloc>(
          create: (_) => ServicesBloc(),
        ),
        BlocProvider<BookingsBloc>(
          create: (_) => BookingsBloc(),
        ),
        BlocProvider<FavoritesBloc>(
          create: (_) => FavoritesBloc()..add(LoadFavorites()),
        ),
        BlocProvider<NotificationsBloc>(
          create: (_) => NotificationsBloc()..add(LoadNotifications()),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            SocketService().connect(state.tokens.accessToken);
          } else if (state is Unauthenticated) {
            SocketService().disconnect();
          }
        },
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Local Service Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
