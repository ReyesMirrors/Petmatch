// ignore_for_file: constant_identifier_names

import 'package:equatable/equatable.dart';

enum PetType { perro, gato, conejo, otro }

enum PetSex { macho, hembra }

enum PetSize { pequeno, mediano, grande }

enum PetStatus { disponible, en_proceso, adoptado, cancelado }

enum PetSituation { con_dueno, sin_hogar, encontrado, temporal }

enum PetHealthStatus {
  saludable,
  desparasitacion,
  cuidados_basicos,
  tratamiento,
  cirugia
}

class Pet extends Equatable {
  final String id;
  final String nombre;
  final PetType tipo;
  final String raza;
  final int edadMeses;
  final PetSex sexo;
  final PetSize tamano;
  final String descripcion;
  final List<String> fotos;
  final bool vacunado;
  final bool esterilizado;
  final PetHealthStatus estadoSalud;
  final String descripcionSalud;
  final double metaDonacion;
  final double totalRecaudado;
  final PetSituation situacion;
  // Ubicacion — privada, solo se comparte si se solicita y el dueno aprueba
  final double latitud;
  final double longitud;
  final String ciudad;
  // Para mascotas sin cirugia/tratamiento: solo un apoyador activo
  final String? apoyadorActivoId;
  final String publicadorId;
  final PetStatus estado;
  final DateTime createdAt;

  const Pet({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.raza,
    required this.edadMeses,
    required this.sexo,
    required this.tamano,
    required this.descripcion,
    required this.fotos,
    required this.vacunado,
    required this.esterilizado,
    required this.estadoSalud,
    this.descripcionSalud = '',
    this.metaDonacion = 0,
    this.totalRecaudado = 0,
    required this.situacion,
    required this.latitud,
    required this.longitud,
    required this.ciudad,
    this.apoyadorActivoId,
    required this.publicadorId,
    required this.estado,
    required this.createdAt,
  });

  bool get aceptaMultiplesApoyos =>
      estadoSalud == PetHealthStatus.tratamiento ||
      estadoSalud == PetHealthStatus.cirugia;

  bool get estaApoyada => apoyadorActivoId != null;
  bool get metaCumplida => metaDonacion > 0 && totalRecaudado >= metaDonacion;
  double get porcentaje =>
      metaDonacion > 0 ? (totalRecaudado / metaDonacion).clamp(0.0, 1.0) : 0;

  String get edadDisplay {
    if (edadMeses < 12) return '$edadMeses ${edadMeses == 1 ? "mes" : "meses"}';
    final y = (edadMeses / 12).floor();
    return '$y ${y == 1 ? "año" : "años"}';
  }

  String get saludDisplay {
    switch (estadoSalud) {
      case PetHealthStatus.saludable:
        return 'Saludable';
      case PetHealthStatus.desparasitacion:
        return 'Necesita desparasitación';
      case PetHealthStatus.cuidados_basicos:
        return 'Necesita cuidados básicos';
      case PetHealthStatus.tratamiento:
        return 'En tratamiento médico';
      case PetHealthStatus.cirugia:
        return 'Necesita cirugía';
    }
  }

  String get situacionDisplay {
    switch (situacion) {
      case PetSituation.con_dueno:
        return 'Con techo';
      case PetSituation.sin_hogar:
        return 'En la calle';
      case PetSituation.encontrado:
        return 'Encontrado';
      case PetSituation.temporal:
        return 'En cuidado temporal';
    }
  }

  String get estadoPublicacionDisplay {
    switch (estado) {
      case PetStatus.disponible:
        return 'Disponible';
      case PetStatus.en_proceso:
        return 'En proceso';
      case PetStatus.adoptado:
        return 'Adoptada';
      case PetStatus.cancelado:
        return 'Cancelada';
    }
  }

  Pet copyWith({
    String? id,
    String? nombre,
    PetType? tipo,
    String? raza,
    int? edadMeses,
    PetSex? sexo,
    PetSize? tamano,
    String? descripcion,
    List<String>? fotos,
    bool? vacunado,
    bool? esterilizado,
    PetHealthStatus? estadoSalud,
    String? descripcionSalud,
    double? metaDonacion,
    double? totalRecaudado,
    PetSituation? situacion,
    double? latitud,
    double? longitud,
    String? ciudad,
    String? apoyadorActivoId,
    String? publicadorId,
    PetStatus? estado,
    DateTime? createdAt,
  }) =>
      Pet(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        tipo: tipo ?? this.tipo,
        raza: raza ?? this.raza,
        edadMeses: edadMeses ?? this.edadMeses,
        sexo: sexo ?? this.sexo,
        tamano: tamano ?? this.tamano,
        descripcion: descripcion ?? this.descripcion,
        fotos: fotos ?? this.fotos,
        vacunado: vacunado ?? this.vacunado,
        esterilizado: esterilizado ?? this.esterilizado,
        estadoSalud: estadoSalud ?? this.estadoSalud,
        descripcionSalud: descripcionSalud ?? this.descripcionSalud,
        metaDonacion: metaDonacion ?? this.metaDonacion,
        totalRecaudado: totalRecaudado ?? this.totalRecaudado,
        situacion: situacion ?? this.situacion,
        latitud: latitud ?? this.latitud,
        longitud: longitud ?? this.longitud,
        ciudad: ciudad ?? this.ciudad,
        apoyadorActivoId: apoyadorActivoId ?? this.apoyadorActivoId,
        publicadorId: publicadorId ?? this.publicadorId,
        estado: estado ?? this.estado,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, nombre, tipo, estado, estadoSalud, totalRecaudado];
}
