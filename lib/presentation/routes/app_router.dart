import 'package:go_router/go_router.dart';

import '../screens/auth/business_selection_screen.dart';
import '../screens/auth/game_intro_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/cash_session/cash_session_screen.dart';
import '../screens/clients/clients_list_screen.dart';
import '../screens/clients/new_client_screen.dart';
import '../screens/collections/client_visit_screen.dart';
import '../screens/collections/new_collection_screen.dart';
import '../screens/credits/credit_list_screen.dart';
import '../screens/credits/my_wallet_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/statistics_dashboard_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/game-intro',
    routes: [
      GoRoute(
        path: '/game-intro',
        name: 'game-intro',
        builder: (context, state) => const GameIntroScreen(),
      ),
      GoRoute(
        path: '/business-selection',
        name: 'business-selection',
        builder: (context, state) => const BusinessSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsDashboardScreen(),
      ),
      GoRoute(
        path: '/credits',
        name: 'credits',
        builder: (context, state) => const CreditListScreen(),
      ),
      GoRoute(
        path: '/my-wallet',
        name: 'my-wallet',
        builder: (context, state) => const MyWalletScreen(),
      ),
      GoRoute(
        path: '/client-visit/:clientId',
        name: 'client-visit',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId'] ?? '';
          return ClientVisitScreen(clientId: clientId);
        },
      ),
      GoRoute(
        path: '/new-client',
        name: 'new-client',
        builder: (context, state) => const NewClientScreen(),
      ),
      GoRoute(
        path: '/clients',
        name: 'clients',
        builder: (context, state) => const ClientsListScreen(),
      ),
      GoRoute(
        path: '/new-collection',
        name: 'new-collection',
        builder: (context, state) => const NewCollectionScreen(),
      ),
      GoRoute(
        path: '/cash-session/:sessionId',
        name: 'cash-session',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return CashSessionScreen(sessionId: sessionId);
        },
      ),
    ],
  );
}
