import 'package:equatable/equatable.dart';

enum UserType { normal, veterinaria, admin }
enum VetStatus { pendiente, aprobado, rechazado }

class AppUser extends Equatable {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final String ciudad;
  final double latitud;
  final double longitud;
  final UserType tipo;
  final VetStatus? vetStatus;
  final String? cedulaUrl;
  final String? certificadoUrl;
  final String? nombreVeterinaria;
  final String? direccionLocal;
  final bool verificado;
  final String? fotoUrl;
  final String? nequiTelefono;
  final String? fcmToken;
  final DateTime createdAt;

  const AppUser({
    required this.uid, required this.nombre, required this.email,
    this.telefono = '', this.ciudad = '',
    this.latitud = 4.711, this.longitud = -74.0721,
    required this.tipo, this.vetStatus, this.cedulaUrl,
    this.certificadoUrl, this.nombreVeterinaria, this.direccionLocal,
    this.verificado = false, this.fotoUrl,
    this.nequiTelefono, this.fcmToken, required this.createdAt,
  });

  bool get isVet => tipo == UserType.veterinaria;
  bool get isAdmin => tipo == UserType.admin;
  bool get isVetApproved => tipo == UserType.veterinaria && vetStatus == VetStatus.aprobado;
  bool get canPublish => tipo == UserType.normal || isVetApproved;

  AppUser copyWith({
    String? uid, String? nombre, String? email, String? telefono,
    String? ciudad, double? latitud, double? longitud, UserType? tipo,
    VetStatus? vetStatus, String? cedulaUrl, String? certificadoUrl,
    String? nombreVeterinaria, String? direccionLocal, bool? verificado, String? fotoUrl,
    String? nequiTelefono, String? fcmToken, DateTime? createdAt,
  }) => AppUser(
    uid: uid ?? this.uid, nombre: nombre ?? this.nombre,
    email: email ?? this.email, telefono: telefono ?? this.telefono,
    ciudad: ciudad ?? this.ciudad, latitud: latitud ?? this.latitud,
    longitud: longitud ?? this.longitud, tipo: tipo ?? this.tipo,
    vetStatus: vetStatus ?? this.vetStatus, cedulaUrl: cedulaUrl ?? this.cedulaUrl,
    certificadoUrl: certificadoUrl ?? this.certificadoUrl,
    nombreVeterinaria: nombreVeterinaria ?? this.nombreVeterinaria,
    direccionLocal: direccionLocal ?? this.direccionLocal,
    verificado: verificado ?? this.verificado, fotoUrl: fotoUrl ?? this.fotoUrl,
    nequiTelefono: nequiTelefono ?? this.nequiTelefono,
    fcmToken: fcmToken ?? this.fcmToken, createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [uid, nombre, email, tipo, vetStatus, direccionLocal, verificado];
}
