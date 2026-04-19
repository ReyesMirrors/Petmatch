import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/extensions/enum_extensions.dart';
import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid, required super.nombre, required super.email,
    super.telefono, super.ciudad, super.latitud, super.longitud,
    required super.tipo, super.vetStatus, super.cedulaUrl,
    super.certificadoUrl, super.nombreVeterinaria, super.direccionLocal, super.verificado,
    super.fotoUrl, super.nequiTelefono, super.fcmToken, required super.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    T ev<T>(List<T> vals, String? v, T def) =>
        vals.firstWhere((e) => e.toString().split('.').last == v, orElse: () => def);
    return UserModel(
      uid: doc.id, nombre: d['nombre'] ?? '', email: d['email'] ?? '',
      telefono: d['telefono'] ?? '', ciudad: d['ciudad'] ?? '',
      latitud: (d['latitud'] ?? 4.711).toDouble(),
      longitud: (d['longitud'] ?? -74.0721).toDouble(),
      tipo: ev(UserType.values, d['tipo'], UserType.normal),
      vetStatus: d['vetStatus'] != null ? ev(VetStatus.values, d['vetStatus'], VetStatus.pendiente) : null,
      cedulaUrl: d['cedulaUrl'], certificadoUrl: d['certificadoUrl'],
      nombreVeterinaria: d['nombreVeterinaria'], direccionLocal: d['direccionLocal'],
      verificado: d['verificado'] ?? false, fotoUrl: d['fotoUrl'],
      nequiTelefono: d['nequiTelefono'], fcmToken: d['fcmToken'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nombre': nombre, 'email': email, 'telefono': telefono,
    'ciudad': ciudad, 'latitud': latitud, 'longitud': longitud,
    'tipo': tipo.enumName, 'vetStatus': vetStatus?.enumName,
    'cedulaUrl': cedulaUrl, 'certificadoUrl': certificadoUrl,
    'nombreVeterinaria': nombreVeterinaria, 'direccionLocal': direccionLocal, 'verificado': verificado,
    'fotoUrl': fotoUrl, 'nequiTelefono': nequiTelefono, 'fcmToken': fcmToken,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory UserModel.fromEntity(AppUser u) => UserModel(
    uid: u.uid, nombre: u.nombre, email: u.email, telefono: u.telefono,
    ciudad: u.ciudad, latitud: u.latitud, longitud: u.longitud, tipo: u.tipo,
    vetStatus: u.vetStatus, cedulaUrl: u.cedulaUrl, certificadoUrl: u.certificadoUrl,
    nombreVeterinaria: u.nombreVeterinaria, direccionLocal: u.direccionLocal, verificado: u.verificado,
    fotoUrl: u.fotoUrl, nequiTelefono: u.nequiTelefono, fcmToken: u.fcmToken,
    createdAt: u.createdAt,
  );
}
