import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:petmatch/features/pets/domain/entities/pet.dart';
import 'package:petmatch/features/pets/domain/pet_repository.dart';
import 'package:petmatch/features/pets/domain/usecases/pet_usecases.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class FakePetRepository implements PetRepository {
  @override
  Stream<List<Pet>> getPets({PetFilter? filter}) {
    return Stream.value(<Pet>[]);
  }

  @override
  Stream<List<Pet>> getPetsPaginated({PetFilter? filter, DocumentSnapshot? startAfter, int limit = 20}) {
    return Stream.value(<Pet>[]);
  }

  @override
  Future<String> publishPet({required Pet pet, required List<String> localImagePaths}) async {
    return 'fake_pet_id';
  }

  @override
  Future<Pet?> getPetById(String id) async {
    return Pet(
      id: id,
      nombre: 'Fake Pet',
      tipo: PetType.perro,
      raza: 'Fake',
      edadMeses: 12,
      sexo: PetSex.macho,
      tamano: PetSize.mediano,
      descripcion: 'Fake desc',
      fotos: [],
      vacunado: true,
      esterilizado: false,
      estadoSalud: PetHealthStatus.saludable,
      situacion: PetSituation.con_dueno,
      latitud: 0.0,
      longitud: 0.0,
      ciudad: 'Fake City',
      publicadorId: 'fake_user',
      estado: PetStatus.disponible,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> addRecaudado(String petId, double monto) async {}

  @override
  Future<void> deletePet(String petId) async {}

  @override
  Future<void> setApoyador(String petId, String? apoyadorId) async {}

  @override
  Future<void> updatePetStatus(String petId, PetStatus status) async {}
}




void main() {
  late FakePetRepository fakeRepo;
  late GetPetsUseCase getPetsUseCase;
  late PublishPetUseCase publishPetUseCase;
  late GetPetByIdUseCase getPetByIdUseCase;

  setUp(() {
    fakeRepo = FakePetRepository();
    getPetsUseCase = GetPetsUseCase(fakeRepo);
    publishPetUseCase = PublishPetUseCase(fakeRepo);
    getPetByIdUseCase = GetPetByIdUseCase(fakeRepo);
  });

group('GetPetsUseCase', () {
    test('returns empty list stream', () async {
      final stream = getPetsUseCase.execute();
      expect(stream, emits(<Pet>[]));
    });

    test('paginated returns empty', () async {
      final stream = getPetsUseCase.executePaginated();
      expect(stream, emits(<Pet>[]));
    });
  });

  group('PublishPetUseCase', () {
    test('returns fake ID', () async {
      final pet = Pet(
        id: '',
        nombre: 'Test',
        tipo: PetType.perro,
        raza: 'Test',
        edadMeses: 12,
        sexo: PetSex.macho,
        tamano: PetSize.mediano,
        descripcion: 'Test',
        fotos: [],
        vacunado: true,
        esterilizado: false,
        estadoSalud: PetHealthStatus.saludable,
        situacion: PetSituation.con_dueno,
        latitud: 0.0,
        longitud: 0.0,
        ciudad: 'Test City',
        publicadorId: 'test_user',
        estado: PetStatus.disponible,
        createdAt: DateTime.now(),
      );
      final result = await publishPetUseCase.execute(pet: pet, images: <String>[]);
      expect(result, 'fake_pet_id');
    });
  });

  group('GetPetByIdUseCase', () {
    test('returns fake Pet', () async {
      final result = await getPetByIdUseCase.execute('test_id');
      expect(result!.nombre, 'Fake Pet');
    });
  });
}



