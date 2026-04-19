import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/extensions/enum_extensions.dart';
import 'pet.dart';

class PetModel extends Pet {
  final DocumentSnapshot snapshot;
  
  const PetModel({
    required super.id, required super.nombre, required super.tipo,
    required super.raza, required super.edadMeses, required super.sexo,
    required super.tamano, required super.descripcion, required super.fotos,
    required super.vacunado, required super.esterilizado,
    required super.estadoSalud, super.descripcionSalud,
    super.metaDonacion, super.totalRecaudado, required super.situacion,
    required super.latitud, required super.longitud, required super.ciudad,
    super.apoyadorActivoId, required super.publicadorId,
    required super.estado, required super.createdAt,
    required this.snapshot,
  });

  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    T ev<T>(List<T> vals, String? v, T def) =>
        vals.firstWhere((e) => e.toString().split('.').last == v, orElse: () => def);
    return PetModel(
      id: doc.id, nombre: d['nombre'] ?? '',
      tipo: ev(PetType.values, d['tipo'], PetType.otro),
      raza: d['raza'] ?? '', edadMeses: (d['edadMeses'] ?? 0) as int,
      sexo: ev(PetSex.values, d['sexo'], PetSex.macho),
      tamano: ev(PetSize.values, d['tamano'], PetSize.mediano),
      descripcion: d['descripcion'] ?? '',
      fotos: List<String>.from(d['fotos'] ?? []),
      vacunado: d['vacunado'] ?? false, esterilizado: d['esterilizado'] ?? false,
      estadoSalud: ev(PetHealthStatus.values, d['estadoSalud'], PetHealthStatus.saludable),
      descripcionSalud: d['descripcionSalud'] ?? '',
      metaDonacion: (d['metaDonacion'] ?? 0).toDouble(),
      totalRecaudado: (d['totalRecaudado'] ?? 0).toDouble(),
      situacion: ev(PetSituation.values, d['situacion'], PetSituation.sin_hogar),
      latitud: (d['latitud'] ?? 4.711).toDouble(),
      longitud: (d['longitud'] ?? -74.0721).toDouble(),
      ciudad: d['ciudad'] ?? '',
      apoyadorActivoId: d['apoyadorActivoId'],
      publicadorId: d['publicadorId'] ?? '',
      estado: ev(PetStatus.values, d['estado'], PetStatus.disponible),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      snapshot: doc,
    );
  }
}

