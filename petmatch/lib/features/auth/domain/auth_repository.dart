import 'dart:io';
import 'entities/app_user.dart';

abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> get userStream;
  Future<String> loginWithEmail({required String email, required String password});
  Future<String> loginWithGoogle();
  Future<String> registerNormal({required String nombre, required String email, required String password, required String telefono, required String ciudad, required String nequi});
  Future<String> registerVeterinaria({required String nombre, required String email, required String password, required String telefono, required String ciudad, required String nombreVet, required String nequi, required String direccionLocal, required File cedulaFile, required File certificadoFile});
  Future<void> logout();
  Future<AppUser?> getUserById(String uid);
  Future<void> updateUser(AppUser user);
}
