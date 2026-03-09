import 'package:go_router/go_router.dart';
import 'package:client/state/auth_notifier.dart';
import 'package:client/ui/screens/login_screen.dart';
import 'package:client/ui/screens/register_screen.dart';
import 'package:client/ui/screens/home_screen.dart';
import 'package:client/ui/screens/add_transaction_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: AuthNotifier(),
  redirect: (context, state) {
    final isAuthenticated = AuthNotifier().isAuthenticated;
    final location = state.uri.toString();
    final isAuthRoute = location == '/login' || location == '/register';

    if (!isAuthenticated && !isAuthRoute) return '/login';
    if (isAuthenticated && isAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/add-transaction',
      builder: (context, state) => const AddTransactionScreen(),
    ),
  ],
);
