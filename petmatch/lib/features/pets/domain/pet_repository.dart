import 'entities/pet.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PetRepository {
  Stream<List<Pet>> getPets({PetFilter? filter});
  Stream<List<Pet>> getPetsPaginated({PetFilter? filter, DocumentSnapshot? startAfter, int limit = 20});
  Future<Pet?> getPetById(String id);
  Future<String> publishPet({required Pet pet, required List<String> localImagePaths});
  Future<void> updatePetStatus(String petId, PetStatus status);
  Future<void> setApoyador(String petId, String? apoyadorId);
  Future<void> addRecaudado(String petId, double monto);
  Future<void> deletePet(String petId);
}




class PetFilter {
  final PetType? tipo;
  final PetSex? sexo;
  final PetSize? tamano;
  final String? ciudad;
  final PetHealthStatus? estadoSalud;
  final PetSituation? situacion;
  const PetFilter({this.tipo, this.sexo, this.tamano, this.ciudad, this.estadoSalud, this.situacion});
  bool get isEmpty => tipo == null && sexo == null && tamano == null && ciudad == null && estadoSalud == null && situacion == null;
}
