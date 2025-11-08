import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/recipes/presentation/recipes_list_screen.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isLoggedIn = user != null;
        final isGoingToLogin = state.matchedLocation == '/login';

        if (!isLoggedIn && !isGoingToLogin) {
          return '/login';
        }
        if (isLoggedIn && isGoingToLogin) {
          return '/recipes';
        }
        return null;
      },
      routes: [ // routes are the pages that the app will navigate to
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/recipes',
          builder: (context, state) => const RecipesListScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Recipe App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
