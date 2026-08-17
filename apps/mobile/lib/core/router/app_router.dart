import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/welcome_page.dart';
import '../../features/chat/presentation/trip_chat_page.dart';
import '../../features/cargo/presentation/cargo_request_wizard_page.dart';
import '../../features/cargo/presentation/my_requests_page.dart';
import '../../features/company/presentation/company_dashboard_page.dart';
import '../../features/company/presentation/company_detail_page.dart';
import '../../features/company/presentation/create_company_page.dart';
import '../../features/home/presentation/customer_home_page.dart';
import '../../features/home/presentation/driver_home_page.dart';
import '../../features/home/presentation/manager_home_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/offers/presentation/marketplace_page.dart';
import '../../features/offers/presentation/request_offers_page.dart';
import '../../features/onboarding/presentation/onboarding_intent_page.dart';
import '../../features/trips/presentation/my_trips_page.dart';
import '../../features/trips/presentation/trip_detail_page.dart';
import '../../features/vehicles/presentation/availability_page.dart';
import '../../features/vehicles/presentation/driver_profile_page.dart';
import '../../features/vehicles/presentation/vehicle_form_page.dart';
import '../../features/vehicles/presentation/vehicles_list_page.dart';
import '../../shared/enums/onboarding_intent.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const onboardingIntent = '/onboarding/intent';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const driverHome = '/home/driver';
  static const managerHome = '/home/manager';
  static const createCompany = '/company/create';
  static const companyDashboard = '/company/dashboard';
  static const companyDetail = '/company/detail';
  static const vehicles = '/vehicles';
  static const vehicleForm = '/vehicles/new';
  static const driverProfile = '/driver/profile';
  static const availability = '/driver/availability';
  static const requestTruck = '/cargo/request';
  static const myRequests = '/cargo/requests';
  static const marketplace = '/loads';
  static const requestOffers = '/cargo/requests/offers';
  static const myTrips = '/trips';
  static const tripDetail = '/trips/detail';
  static const tripChat = '/trips/chat';
  static const notifications = '/notifications';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      final isSplash = loc == AppRoutes.splash;
      final isAuthRoute =
          loc == AppRoutes.welcome ||
          loc == AppRoutes.login ||
          loc == AppRoutes.signup ||
          loc == AppRoutes.forgotPassword ||
          loc == AppRoutes.onboardingIntent;

      if (auth.status == AuthStatus.unknown) {
        return isSplash ? null : AppRoutes.splash;
      }

      if (auth.status == AuthStatus.unauthenticated) {
        if (isSplash) return AppRoutes.welcome;
        if (isAuthRoute) return null;
        return AppRoutes.welcome;
      }

      if (auth.needsOnboarding) {
        if (loc == AppRoutes.onboardingIntent) return null;
        return AppRoutes.onboardingIntent;
      }

      if (isSplash || isAuthRoute) {
        return _homeFor(auth);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.onboardingIntent,
        builder: (context, state) => const OnboardingIntentPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) {
          final intent = state.extra is OnboardingIntent
              ? state.extra! as OnboardingIntent
              : null;
          return SignupPage(intent: intent);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const CustomerHomePage(),
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        builder: (context, state) => const DriverHomePage(),
      ),
      GoRoute(
        path: AppRoutes.managerHome,
        builder: (context, state) => const ManagerHomePage(),
      ),
      GoRoute(
        path: AppRoutes.createCompany,
        builder: (context, state) => const CreateCompanyPage(),
      ),
      GoRoute(
        path: AppRoutes.companyDashboard,
        builder: (context, state) {
          final id = state.extra is String ? state.extra! as String : null;
          if (id == null || id.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Empresa no encontrada')),
            );
          }
          return CompanyDashboardPage(companyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.companyDetail,
        builder: (context, state) {
          final id = state.extra is String ? state.extra! as String : null;
          if (id == null || id.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Empresa no encontrada')),
            );
          }
          return CompanyDetailPage(companyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.vehicles,
        builder: (context, state) => const VehiclesListPage(),
      ),
      GoRoute(
        path: AppRoutes.vehicleForm,
        builder: (context, state) {
          final companyId = state.extra is String
              ? state.extra! as String
              : null;
          return VehicleFormPage(companyId: companyId);
        },
      ),
      GoRoute(
        path: AppRoutes.driverProfile,
        builder: (context, state) => const DriverProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.availability,
        builder: (context, state) => const AvailabilityPage(),
      ),
      GoRoute(
        path: AppRoutes.requestTruck,
        builder: (context, state) => const CargoRequestWizardPage(),
      ),
      GoRoute(
        path: AppRoutes.myRequests,
        builder: (context, state) => const MyRequestsPage(),
      ),
      GoRoute(
        path: AppRoutes.marketplace,
        builder: (context, state) => const MarketplacePage(),
      ),
      GoRoute(
        path: AppRoutes.requestOffers,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            final id = extra['requestId'] as String?;
            final label = extra['routeLabel'] as String?;
            if (id != null && id.isNotEmpty) {
              return RequestOffersPage(requestId: id, routeLabel: label);
            }
          }
          if (extra is String && extra.isNotEmpty) {
            return RequestOffersPage(requestId: extra);
          }
          return const Scaffold(
            body: Center(child: Text('Solicitud no encontrada')),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myTrips,
        builder: (context, state) => const MyTripsPage(),
      ),
      GoRoute(
        path: AppRoutes.tripDetail,
        builder: (context, state) {
          final id = state.extra is String ? state.extra! as String : null;
          if (id == null || id.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Viaje no encontrado')),
            );
          }
          return TripDetailPage(tripId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.tripChat,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            final id = extra['tripId'] as String?;
            final label = extra['routeLabel'] as String?;
            if (id != null && id.isNotEmpty) {
              return TripChatPage(tripId: id, routeLabel: label);
            }
          }
          if (extra is String && extra.isNotEmpty) {
            return TripChatPage(tripId: extra);
          }
          return const Scaffold(
            body: Center(child: Text('Chat no encontrado')),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Ruta no encontrada: ${state.uri}'))),
  );
});

String _homeFor(AuthSessionState auth) {
  final intent = auth.profile?.onboardingIntent;
  return switch (intent) {
    OnboardingIntent.offerTransport => AppRoutes.driverHome,
    OnboardingIntent.manageTransport => AppRoutes.managerHome,
    _ => AppRoutes.home,
  };
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    _sub = ref.listen<AuthSessionState>(authControllerProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref ref;
  late final ProviderSubscription<AuthSessionState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
