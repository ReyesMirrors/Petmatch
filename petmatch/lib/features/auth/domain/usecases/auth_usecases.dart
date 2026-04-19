import 'dart:io';
import '../auth_repository.dart';

class LoginUseCase {
  final AuthRepository r;
  LoginUseCase(this.r);
  Future<String> execute({required String email, required String password}) =>
      r.loginWithEmail(email: email, password: password);
  Future<String> withGoogle() => r.loginWithGoogle();
}

class RegisterUseCase {
  final AuthRepository r;
  RegisterUseCase(this.r);
  Future<String> normal({required String nombre, required String email,
      required String password, required String telefono,
      required String ciudad, required String nequi}) =>
      r.registerNormal(nombre: nombre, email: email, password: password,
          telefono: telefono, ciudad: ciudad, nequi: nequi);
  Future<String> vet({required String nombre, required String email,
      required String password, required String telefono, required String ciudad,
      required String nombreVet, required String nequi, required String direccionLocal,
      required File cedula, required File certificado}) =>
      r.registerVeterinaria(nombre: nombre, email: email, password: password,
          telefono: telefono, ciudad: ciudad, nombreVet: nombreVet, nequi: nequi,
          direccionLocal: direccionLocal, cedulaFile: cedula, certificadoFile: certificado);
}

class LogoutUseCase {
  final AuthRepository r;
  LogoutUseCase(this.r);
  Future<void> execute() => r.logout();
}
