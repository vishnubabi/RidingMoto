import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/create_trip/create_trip_screen.dart';
import '../features/join_trip/join_trip_screen.dart';
import '../features/live_map/live_map_screen.dart';
import '../shared/models/trip_member.dart';

class AppRoutes {
  static const String home = '/';
  static const String createTrip = '/create-trip';
  static const String joinTrip = '/join-trip';
  static const String liveMap = '/live-map';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen());
      case createTrip:
        return _buildRoute(const CreateTripScreen());
      case joinTrip:
        final args = settings.arguments as Map<String, String>?;
        return _buildRoute(JoinTripScreen(initialCode: args?['code']));
      case liveMap:
        final args = settings.arguments as LiveMapArgs;
        return _buildRoute(LiveMapScreen(args: args));
      default:
        return _buildRoute(const HomeScreen());
    }
  }

  static PageRoute _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}

/// Arguments passed when navigating to the live map screen
class LiveMapArgs {
  final String tripCode;
  final TripMember member;

  const LiveMapArgs({required this.tripCode, required this.member});
}
