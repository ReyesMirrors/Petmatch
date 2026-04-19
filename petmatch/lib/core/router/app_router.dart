import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petmatch/features/profile/presentation/profile_screen.dart';
import 'package:petmatch/features/search/presentation/screens/pets_map_screen.dart';

import '../services/auth_service.dart';
import '../di/injection.dart';
import '../widgets/main_scaffold.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';

import '../../features/pets/presentation/screens/home_screen.dart';
import '../../features/pets/presentation/screens/pet_detail_screen.dart';
import '../../features/pets/presentation/screens/publish_pet_screen.dart';

import '../../features/search/presentation/screens/search_screen.dart';

import '../../features/adoption/presentation/screens/requests_screen.dart';
import '../../features/adoption/presentation/screens/adoption_form_screen.dart';
import '../../features/adoption/presentation/screens/chat_screen.dart';
import '../../features/adoption/presentation/screens/donation_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';

class AppRouter {
  static const login = '/login';
  static const register = '/register';

  static const home = '/home';
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const search = '/search';
  static const map = '/map';
  static const requests = '/requests';

  static const profile = '/profile';
  static const userProfile = '/user/:uid';
  static const editProfile = '/profile/edit';
  static const notifications = '/notifications';

  static const petDetail = '/pet/:id';
  static const publish = '/publish';
  static const adoptForm = '/adopt/:petId';
  static const chat = '/chat/:chatId/:otherId';
  static const donation = '/donate/:petId';
  static const admin = '/admin';

  static final _auth = getIt<AuthService>();

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: home,

    redirect: (ctx, state) {
      final loggedIn = _auth.currentUser != null;
      final onAuth =
          state.matchedLocation == login ||
          state.matchedLocation == register;

      if (!loggedIn && !onAuth) return login;
      if (loggedIn && onAuth) return home;
      return null;
    },

    routes: [
      GoRoute(path: login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: register, builder: (_, __) => const RegisterScreen()),

      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: home, builder: (_, __) => const HomeScreen()),
          GoRoute(path: search, builder: (_, __) => const SearchScreen()),

          GoRoute(path: map, builder: (_, __) => const PetsMapScreen()),

          GoRoute(path: requests, builder: (_, __) => const RequestsScreen()),
          GoRoute(path: notifications, builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: profile, builder: (_, __) => const ProfileScreen(key: ValueKey('profile-own'))),
          GoRoute(
            path: userProfile,
            builder: (_, s) {
              final uid = s.pathParameters['uid']!;
              return ProfileScreen(key: ValueKey('profile-user-$uid'), userId: uid);
            },
          ),
          GoRoute(path: editProfile, builder: (_, __) => const EditProfileScreen()),
        ],
      ),

      GoRoute(
        path: petDetail,
        builder: (_, s) =>
            PetDetailScreen(petId: s.pathParameters['id']!),
      ),

      GoRoute(
        path: publish,
        builder: (_, __) => const PublishPetScreen(),
      ),

      GoRoute(
        path: adoptForm,
        builder: (_, s) =>
            AdoptionFormScreen(petId: s.pathParameters['petId']!),
      ),

      GoRoute(
        path: chat,
        builder: (_, s) => ChatScreen(
          chatId: s.pathParameters['chatId']!,
          otherId: s.pathParameters['otherId']!,
        ),
      ),

      GoRoute(
        path: donation,
        builder: (_, s) =>
            DonationScreen(petId: s.pathParameters['petId']!),
      ),

      GoRoute(
        path: admin,
        builder: (_, __) => const AdminScreen(),
      ),
    ],

    errorBuilder: (_, s) => Scaffold(
      body: Center(child: Text('Error: ${s.error}')),
    ),
  );
}