import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

// Services
import '../services/auth_service.dart';
import '../services/notification_service.dart';

// Auth
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Pets
import '../../features/pets/data/pet_repository_impl.dart';
import '../../features/pets/domain/pet_repository.dart';
import '../../features/pets/domain/usecases/pet_usecases.dart';
import '../../features/pets/presentation/bloc/pets_bloc.dart';

// Adoption
import '../../features/adoption/data/adoption_repository_impl.dart';
import '../../features/adoption/domain/adoption_repository.dart';
import '../../features/adoption/domain/usecases/adoption_usecases.dart';
import '../../features/adoption/presentation/bloc/adoption_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // 🔥 Firebase
  getIt.registerLazySingleton(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton(() => FirebaseStorage.instance);
  getIt.registerLazySingleton(() => FirebaseMessaging.instance);

  // ⚙️ Services
  getIt.registerLazySingleton(() => AuthService(getIt()));
  getIt.registerLazySingleton(() => NotificationService(getIt(), getIt(), getIt()));

  // 📦 Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt(), getIt()),
  );

  getIt.registerLazySingleton<PetRepository>(
    () => PetRepositoryImpl(getIt(), getIt()),
  );

  getIt.registerLazySingleton<AdoptionRepository>(
    () => AdoptionRepositoryImpl(getIt()),
  );

  // 🧠 UseCases (Auth)
  getIt.registerFactory(() => LoginUseCase(getIt()));
  getIt.registerFactory(() => RegisterUseCase(getIt()));
  getIt.registerFactory(() => LogoutUseCase(getIt()));

  // 🧠 UseCases (Pets)
  getIt.registerFactory(() => GetPetsUseCase(getIt()));
  getIt.registerFactory(() => PublishPetUseCase(getIt()));
  getIt.registerFactory(() => GetPetByIdUseCase(getIt()));

  // 🧠 UseCases (Adoption)
  getIt.registerFactory(() => RequestAdoptionUseCase(getIt()));
  getIt.registerFactory(() => UpdateAdoptionStatusUseCase(getIt()));

  // 🎭 BLoCs
  getIt.registerFactory(
    () => AuthBloc(getIt(), getIt(), getIt()),
  );

getIt.registerFactory<PetsBloc>(
    () => PetsBloc(getIt<PetRepository>()),
  );

  getIt.registerFactory(
    () => AdoptionBloc(getIt(), getIt(), getIt()),
  );

  // 📲 Notificaciones
  await getIt<NotificationService>().initialize();
}