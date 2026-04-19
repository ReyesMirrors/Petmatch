import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/usecases/auth_usecases.dart';

// Events
abstract class AuthEvent extends Equatable { @override List<Object?> get props => []; }
class LoginEmailEvent extends AuthEvent { final String email, password; LoginEmailEvent(this.email, this.password); @override List<Object?> get props => [email]; }
class LoginGoogleEvent extends AuthEvent {}
class RegisterNormalEvent extends AuthEvent {
  final String nombre, email, password, telefono, ciudad, nequi;
  RegisterNormalEvent(this.nombre, this.email, this.password, this.telefono, this.ciudad, this.nequi);
  @override List<Object?> get props => [email];
}
class RegisterVetEvent extends AuthEvent {
  final String nombre, email, password, telefono, ciudad, nombreVet, nequi, direccionLocal;
  final File cedula, certificado;
  RegisterVetEvent(this.nombre, this.email, this.password, this.telefono, this.ciudad, this.nombreVet, this.nequi, this.direccionLocal, this.cedula, this.certificado);
  @override List<Object?> get props => [email];
}
class LogoutEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable { @override List<Object?> get props => []; }
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState { final String uid; AuthAuthenticated(this.uid); @override List<Object?> get props => [uid]; }
class AuthUnauthenticated extends AuthState {}
class AuthVetPending extends AuthState {}
class AuthError extends AuthState { final String msg; AuthError(this.msg); @override List<Object?> get props => [msg]; }

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;

  AuthBloc(this._login, this._register, this._logout) : super(AuthInitial()) {
    on<LoginEmailEvent>(_onEmail);
    on<LoginGoogleEvent>(_onGoogle);
    on<RegisterNormalEvent>(_onNormal);
    on<RegisterVetEvent>(_onVet);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onEmail(LoginEmailEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final uid = await _login.execute(email: e.email, password: e.password);
      await getIt<NotificationService>().saveTokenForCurrentUser();
      emit(AuthAuthenticated(uid));
    } catch (ex) {
      emit(AuthError(_map(ex.toString())));
    }
  }

  Future<void> _onGoogle(LoginGoogleEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final uid = await _login.withGoogle();
      await getIt<NotificationService>().saveTokenForCurrentUser();
      emit(AuthAuthenticated(uid));
    } catch (ex) {
      emit(AuthError(_map(ex.toString())));
    }
  }

  Future<void> _onNormal(RegisterNormalEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final uid = await _register.normal(nombre: e.nombre, email: e.email, password: e.password, telefono: e.telefono, ciudad: e.ciudad, nequi: e.nequi);
      await getIt<NotificationService>().saveTokenForCurrentUser();
      emit(AuthAuthenticated(uid));
    } catch (ex) {
      emit(AuthError(_map(ex.toString())));
    }
  }

  Future<void> _onVet(RegisterVetEvent e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _register.vet(nombre: e.nombre, email: e.email, password: e.password, telefono: e.telefono, ciudad: e.ciudad, nombreVet: e.nombreVet, nequi: e.nequi, direccionLocal: e.direccionLocal, cedula: e.cedula, certificado: e.certificado);
      await getIt<NotificationService>().saveTokenForCurrentUser();
      emit(AuthVetPending());
    } catch (ex) {
      emit(AuthError(_map(ex.toString())));
    }
  }

  Future<void> _onLogout(LogoutEvent e, Emitter<AuthState> emit) async {
    await _logout.execute();
    emit(AuthUnauthenticated());
  }

  String _map(String e) {
    if (e.contains('email-already-in-use')) return 'Este correo ya esta registrado.';
    if (e.contains('wrong-password') || e.contains('invalid-credential')) return 'Correo o contrasena incorrectos.';
    if (e.contains('user-not-found')) return 'No existe una cuenta con este correo.';
    if (e.contains('weak-password')) return 'La contrasena debe tener minimo 8 caracteres.';
    if (e.contains('network-request-failed')) return 'Sin conexion a internet.';
    return 'Error inesperado. Intenta de nuevo.';
  }
}
