import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../di/injection.dart';
import '../theme/app_theme.dart';
import '../router/app_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _idx(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).uri.toString();

    if (loc.startsWith(AppRouter.search)) return 1;
    if (loc.startsWith(AppRouter.map)) return 2;
    if (loc.startsWith(AppRouter.requests)) return 3;

    return 0; // home
  }

  @override
  Widget build(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).uri.toString();
    final showFab = loc != AppRouter.map;
    final authRepo = getIt<AuthRepository>();

    return StreamBuilder(
      stream: authRepo.userStream,
      initialData: authRepo.currentUser,
      builder: (context, snapshot) {
        final isAdmin = snapshot.data?.isAdmin == true;

        return Scaffold(
          body: child,

          // 🧠 APP BAR GLOBAL
          appBar: AppBar(
            title: const Text("PetMatch 🐾"),
            leading: isAdmin
                ? IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onPressed: () => ctx.push(AppRouter.admin),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  ctx.push(AppRouter.notifications);
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  ctx.push(AppRouter.profile);
                },
              )
            ],
          ),

          // ➕ BOTÓN PUBLICAR
          floatingActionButton: showFab
              ? FloatingActionButton(
                  backgroundColor: AppTheme.accent,
                  onPressed: () => ctx.push(AppRouter.publish),
                  tooltip: 'Publicar mascota',
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,

          // 🔽 NAV BAR
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _idx(ctx),
            onTap: (i) {
              switch (i) {
                case 0:
                  ctx.go(AppRouter.home);
                  break;
                case 1:
                  ctx.go(AppRouter.search);
                  break;
                case 2:
                  ctx.go(AppRouter.map);
                  break;
                case 3:
                  ctx.go(AppRouter.requests);
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Buscar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Solicitudes',
              ),
            ],
          ),
        );
      },
    );
  }
}