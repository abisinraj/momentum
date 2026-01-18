import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/workout/presentation/workout_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/info/presentation/info_screen.dart';
import '../features/setup/presentation/setup_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../core/providers/core_providers.dart';
import '../core/providers/database_providers.dart';

part 'router.g.dart';

/// Routes enumeration for type-safe navigation
enum AppRoute {
  splash('/'),
  setup('/setup'),
  home('/home'),
  workout('/workout'),
  progress('/progress'),
  info('/info');

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
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Info',
          ),
        ],
      ),
    );
  }
}

/// Router provider using go_router
@riverpod
GoRouter router(ref) {
  // Watch the async setup provider - it returns AsyncValue<bool>
  final isSetupCompleteAsync = ref.watch(isSetupCompleteProvider);
  
  return GoRouter(
    initialLocation: AppRoute.splash.path,
    redirect: (context, state) {
      final path = state.uri.path;
      
      // Handle async setup check
      return isSetupCompleteAsync.when(
        data: (isComplete) {
          // If on splash, redirect based on setup status
          if (path == AppRoute.splash.path) {
            return isComplete ? AppRoute.home.path : AppRoute.setup.path;
          }
          // If on setup and already complete, go to home
          if (path == AppRoute.setup.path && isComplete) {
            return AppRoute.home.path;
          }
          // If trying to access app routes but not setup, go to setup
          if (path != AppRoute.setup.path && path != AppRoute.splash.path && !isComplete) {
            return AppRoute.setup.path;
          }
          return null; // No redirect needed
        },
        loading: () {
          // Stay on splash while loading
          if (path != AppRoute.splash.path) {
            return AppRoute.splash.path;
          }
          return null;
        },
        error: (_, __) => AppRoute.setup.path, // On error, go to setup
      );
    },
    routes: [
      // Splash route
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Setup route (shown only on first launch)
      GoRoute(
        path: AppRoute.setup.path,
        name: AppRoute.setup.name,
        builder: (context, state) => const SetupScreen(),
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

