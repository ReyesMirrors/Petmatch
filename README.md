# PetMatch 🐾

[![Flutter](https://flutter.dev/images/flutter-logo-sharing.png)](https://flutter.dev) [![Firebase](https://img.shields.io/badge/Firebase-FFCB91?style=flat&logo=firebase&logoColor=white)](https://firebase.google.com)

**PetMatch** es una aplicación móvil multiplataforma para **adopción responsable de mascotas**. Conecta dueños de mascotas, adoptantes y refugios mediante un sistema completo de perfiles, búsqueda geolocalizada, solicitudes de adopción, chats, donaciones y notificaciones en tiempo real.

## 📋 Índice
- [✨ Características](#caractersticas)
- [🛠️ Tecnologías](#tecnologas)
- [🏗️ Arquitectura](#arquitectura)
- [🚀 Instalación Rápida](#instalacin-rpida)
- [⚙️ Configuración Detallada](#configuracin-detallada)
- [📱 Plataformas Soportadas](#plataformas-soportadas)
- [🧪 Testing](#testing)
- [🚀 Despliegue](#despliegue)
- [📁 Estructura de Archivos](#estructura-de-archivos)
- [📸 Screenshots](#screenshots)
- [🤝 Contribuir](#contribuir)
- [📄 Licencia](#licencia)

## ✨ Características
| Feature | Descripción | Rutas |
|---------|-------------|-------|
| **Autenticación** | Login/registro con email y Google Sign-In. | `/login`, `/register` |
| **Home/Pets** | Lista de mascotas disponibles, detalle, publicar nueva mascota. | `/home`, `/pet/:id`, `/publish` |
| **Búsqueda** | Lista y mapa con Google Maps + Geolocator. | `/search`, `/map` |
| **Adopción** | Solicitudes, formulario, chat en tiempo real, donaciones. | `/requests`, `/adopt/:petId`, `/chat/:chatId/:otherId`, `/donate/:petId` |
| **Perfil** | Perfil propio/editar, ver perfil usuario. | `/profile`, `/user/:uid`, `/profile/edit` |
| **Notificaciones** | Push notifications via FCM + Cloud Functions. | `/notifications` |
| **Admin** | Panel administrativo. | `/admin` |

## 🛠️ Tecnologías
| Categoría | Tecnologías |
|-----------|-------------|
| **Frontend** | Flutter 3.x, Material Design, BLoC + Equatable, GoRouter |
| **Backend** | Firebase (Auth, Firestore, Storage, Messaging, Functions) |
| **Maps/Location** | Google Maps Flutter, Geolocator |
| **Media** | Image Picker, Compress, Cached Network Image |
| **Utils** | GetIt (DI), Shimmer, Timeago, Intl, UUID, Shared Prefs |
| **Notifications** | Flutter Local Notifications + FCM |

Ver [pubspec.yaml](pubspec.yaml) para versiones exactas.

## 🏗️ Arquitectura
**Clean Architecture** con capas:
- **Presentation**: Screens, BLoCs/Cubits, Widgets (`lib/features/*/presentation/`).
- **Domain**: Entities, UseCases, Repositories abstract (`lib/features/*/domain/`).
- **Data**: Datasources (Firebase), Models, Repos impl (`lib/features/*/data/`).
- **Core**: DI (`injection.dart`), Router (`app_router.dart`), Services (Auth/Notifications), Theme, Extensions, Widgets reutilizables (`main_scaffold.dart`).

```
lib/
├── core/                 # Shared core
│   ├── di/              # Dependency Injection (GetIt)
│   ├── router/          # GoRouter config
│   ├── services/        # AuthService, NotificationService
│   └── theme/           # AppTheme (light/dark)
├── features/            # Feature modules (Clean Arch)
│   └── pets/            # Ejemplo: data/domain/presentation
└── main.dart            # Firebase init + App
```

**Navegación**: GoRouter con `ShellRoute` (bottom nav: home/search/requests/notifs/profile) y auth guard.

**DI**: `configureDependencies()` en main.dart registra todos los servicios/repos/use cases.

**Firestore Structure** (inferido de código/rutas):
- `users/{uid}`: Perfiles, fcmTokens.
- `pets/{id}`: Mascotas (images en Storage).
- `requests/{id}`: Solicitudes adopción.
- `chats/{chatId}`: Mensajes.
- `notifications/{id}`: Trigger Functions.

Ver [firestore.rules](firestore.rules) para seguridad.

## 🚀 Instalación Rápida
1. `flutter pub get`
2. Configurar Firebase (ver abajo).
3. `flutter run`

## ⚙️ Configuración Detallada
### 1. Firebase
```
dart pub global activate flutterfire_cli
flutterfire configure --project=petmatch
```
Activa: Auth (Email/Google), Firestore, Storage, Messaging.

### 2. Google Maps
`android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data android:name="com.google.android.geo.API_KEY" android:value="TU_API_KEY"/>
```

### 3. Admin UID
`lib/features/admin/presentation/screens/admin_screen.dart`:
```dart
const String kAdminUid = 'tu-uid';
```

### 4. Firestore Rules
```
firebase deploy --only firestore:rules
```

### 5. Cloud Functions
```
cd functions && npm install && firebase deploy --only functions
```

## 📱 Plataformas Soportadas
- Android, iOS, Web, Linux, macOS, Windows (full setup).

## 🧪 Testing
```
flutter test
```
Ej: `test/widget_test.dart`. Agrega más tests en `test/`.

## 🚀 Despliegue
```
flutter build apk --release  # Android
flutter build ios           # iOS
flutter build web           # Web: firebase hosting
```

Functions: `firebase deploy --only functions`.

## 📁 Estructura de Archivos
```
.
├── lib/                  # App source (Clean Arch)
├── android/              # Android native
├── ios/                  # iOS native
├── functions/            # Firebase Cloud Functions (TS)
├── assets/               # Images/icons
├── firebase.json         # Hosting/Functions config
├── firestore.rules       # Security rules
└── pubspec.yaml          # Dependencies
```
**Por qué esta estructura?** Modular (features independientes), escalable, testable (unit tests por capa), mantenible (separación concerns).

**Cómo se construyó:**
- Flutter skeleton → Agregado Firebase via flutterfire.
- Features modulares via BLoC + Repos.
- Router central para nav fluida.
- Functions para notifs push server-side.

## 📸 Screenshots
*(Agregar imágenes aquí)*
- ![Home](screenshots/home.png)
- ![Map](screenshots/map.png)
- etc.

## 🤝 Contribuir
1. Fork → Clone.
2. `flutter pub get`.
3. Crea branch `feature/xxx`.
4. Commit → PR.

Estándares: Dart analysis (`flutter analyze`), tests pasan.

## 📄 Licencia
MIT License. Ver LICENSE.

