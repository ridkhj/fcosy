import 'package:go_router/go_router.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/state/auth_notifier.dart';
import 'package:client/ui/screens/account_detail_screen.dart';
import 'package:client/ui/screens/account_form_screen.dart';
import 'package:client/ui/screens/login_screen.dart';
import 'package:client/ui/screens/register_screen.dart';
import 'package:client/ui/screens/home_screen.dart';
import 'package:client/ui/screens/add_transaction_screen.dart';
import 'package:client/ui/screens/transaction_detail_screen.dart';

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
      path: '/accounts',
      builder: (context, state) => const HomeScreen(initialIndex: 0),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const HomeScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const HomeScreen(initialIndex: 2),
    ),
    GoRoute(
      path: '/accounts/new',
      builder: (context, state) => const AccountFormScreen(),
    ),
    GoRoute(
      path: '/accounts/:id',
      builder: (context, state) => AccountDetailScreen(
        accountId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/accounts/:id/edit',
      builder: (context, state) => AccountFormScreen(
        accountId: int.parse(state.pathParameters['id']!),
        initialAccount: state.extra as AccountSummaryModel?,
      ),
    ),
    GoRoute(
      path: '/transactions/new',
      builder: (context, state) => AddTransactionScreen(
        initialAccount: state.extra as AccountSummaryModel?,
      ),
    ),
    GoRoute(
      path: '/add-transaction',
      redirect: (context, state) => '/transactions/new',
    ),
    GoRoute(
      path: '/transactions/:id',
      builder: (context, state) => TransactionDetailScreen(
        transactionId: int.parse(state.pathParameters['id']!),
        initialTransaction: state.extra as TransactionModel?,
      ),
    ),
    GoRoute(
      path: '/transactions/:id/edit',
      builder: (context, state) => AddTransactionScreen(
        initialTransaction: state.extra as TransactionModel?,
      ),
    ),
  ],
);
