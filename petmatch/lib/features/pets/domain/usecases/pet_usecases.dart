import '../entities/pet.dart';
import '../pet_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class GetPetsUseCase {
  final PetRepository r;
  GetPetsUseCase(this.r);
  Stream<List<Pet>> execute({PetFilter? filter}) => r.getPets(filter: filter);
  Stream<List<Pet>> executePaginated({PetFilter? filter, DocumentSnapshot? startAfter, int limit = 20}) => r.getPetsPaginated(filter: filter, startAfter: startAfter, limit: limit);
}

// class PetModelWrapper {
  //   static DocumentSnapshot? fromPet(Pet pet) => null; // placeholder for bloc if needed
// }




class PublishPetUseCase {
  final PetRepository r;
  PublishPetUseCase(this.r);
  Future<String> execute({required Pet pet, required List<String> images}) =>
      r.publishPet(pet: pet, localImagePaths: images);
}

class GetPetByIdUseCase {
  final PetRepository r;
  GetPetByIdUseCase(this.r);
  Future<Pet?> execute(String id) => r.getPetById(id);
}
