import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freecal/features/calendar/presentation/screens/home_screen.dart';
import 'package:freecal/features/events/presentation/screens/add_event_screen.dart';
import 'package:freecal/features/events/presentation/screens/event_details_screen.dart';
import 'package:freecal/features/rules/presentation/screens/rules_screen.dart';
import 'package:freecal/features/conflicts/presentation/screens/conflict_screen.dart';

/// Application route paths.
abstract class AppRoutes {
  static const String home = '/';
  static const String addEvent = '/add-event';
  static const String eventDetails = '/event/:id';
  static const String rules = '/rules';
  static const String conflicts = '/conflicts';
}

/// The GoRouter instance for the application.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.addEvent,
      name: 'addEvent',
      builder: (BuildContext context, GoRouterState state) =>
          const AddEventScreen(),
    ),
    GoRoute(
      path: AppRoutes.eventDetails,
      name: 'eventDetails',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return EventDetailsScreen(eventId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.rules,
      name: 'rules',
      builder: (BuildContext context, GoRouterState state) =>
          const RulesScreen(),
    ),
    GoRoute(
      path: AppRoutes.conflicts,
      name: 'conflicts',
      builder: (BuildContext context, GoRouterState state) =>
          const ConflictScreen(),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
