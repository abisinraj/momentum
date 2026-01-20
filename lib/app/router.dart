import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/workout/presentation/workout_screen.dart';
import '../features/workout/presentation/create_workout_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/info/presentation/info_screen.dart';
import '../features/setup/presentation/setup_screen.dart';
import '../features/setup/presentation/split_setup_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/diet/presentation/diet_screen.dart';
import '../core/providers/database_providers.dart';

part 'router.g.dart';

/// Routes enumeration for type-safe navigation
enum AppRoute {
  splash('/'),
  setup('/setup'),
  splitSetup('/split-setup'),
  createWorkout('/create-workout/:index/:total'),
  home('/home'),
  workout('/workout'),
  diet('/diet'),
  progress('/progress'),
  info('/info'),
  settings('/settings');

  const AppRoute(this.path);
  final String path;
}

/// Root navigation shell with bottom navigation bar
class NavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  
  const NavigationShell({
    super.key,
    required this.navigationShell,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Diet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Helper function to handle redirect when setup data is loaded
String? _handleDataRedirect(BuildContext context, GoRouterState state, bool isComplete) {
  final path = state.uri.path;
  final isSetupFlow = path == AppRoute.setup.path || 
                      path == AppRoute.splitSetup.path ||
                      path.startsWith('/create-workout');

  // If setup is NOT complete
  if (!isComplete) {
    // Allow any setup flow screen (but redirect splash to setup)
    if (isSetupFlow) return null;
    // Otherwise redirect to setup start
    return AppRoute.setup.path;
  }

  // If setup IS complete
  if (isSetupFlow || path == AppRoute.splash.path) {
    // Redirect to home if trying to access setup or splash
    return AppRoute.home.path;
  }

  return null; // Allow other routes
}

/// Router provider using go_router
@riverpod
GoRouter router(ref) {
  // Watch the async setup provider
  final isSetupCompleteAsync = ref.watch(isSetupCompleteProvider);
  
  return GoRouter(
    initialLocation: AppRoute.splash.path,
    redirect: (context, state) {
      final path = state.uri.path;
      final isSetupFlow = path == AppRoute.setup.path || 
                          path == AppRoute.splitSetup.path ||
                          path.startsWith('/create-workout');

      // Use pattern matching for the async value
      return switch (isSetupCompleteAsync) {
        // Only redirect to splash if we are NOT in setup flow
        // This prevents kicking the user out of setup when the provider refreshes (e.g. after saving profile)
        AsyncLoading() => (path != AppRoute.splash.path && !isSetupFlow) ? AppRoute.splash.path : null,
        AsyncError() => AppRoute.setup.path,
        AsyncData(:final value) => _handleDataRedirect(context, state, value),
        _ => (path != AppRoute.splash.path && !isSetupFlow) ? AppRoute.splash.path : null,
      };
    },
    routes: [
      // Splash route
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Setup routes
      GoRoute(
        path: AppRoute.setup.path,
        name: AppRoute.setup.name,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: AppRoute.splitSetup.path,
        name: AppRoute.splitSetup.name,
        builder: (context, state) => const SplitSetupScreen(),
      ),
      GoRoute(
        path: AppRoute.createWorkout.path,
        name: 'createWorkout', // manual name as enum path has params
        builder: (context, state) {
          final index = int.parse(state.pathParameters['index']!);
          final total = int.parse(state.pathParameters['total']!);
          return CreateWorkoutScreen(
            index: index,
            totalDays: total,
          );
        },
      ),
      
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Main app shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // Home branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Workout branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.workout.path,
                name: AppRoute.workout.name,
                builder: (context, state) => const WorkoutScreen(),
              ),
            ],
          ),
          // Progress branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.progress.path,
                name: AppRoute.progress.name,
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          // Diet branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.diet.path,
                name: AppRoute.diet.name,
                builder: (context, state) => const DietScreen(),
              ),
            ],
          ),
          // Info branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.info.path,
                name: AppRoute.info.name,
                builder: (context, state) => const InfoScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
