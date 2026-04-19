import 'package:petmatch/core/di/injection.dart';
import '../entities/pet.dart';
import '../pet_repository.dart';

class PublishPetUseCase {
  final PetRepository repository;
  PublishPetUseCase(this.repository);
  
  Future<String> execute({
    required Pet pet,
    required List<String> localImagePaths,
  }) async {
    return await repository.publishPet(pet: pet, localImagePaths: localImagePaths);
  }
}
