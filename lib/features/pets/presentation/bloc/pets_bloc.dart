import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:petmatch/core/di/injection.dart';
import '../../domain/entities/pet.dart';
import '../../domain/pet_repository.dart';


abstract class PetsEvent extends Equatable {
  const PetsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPetsEvent extends PetsEvent {}
class RefreshPetsEvent extends PetsEvent {}

abstract class PetsState extends Equatable {
  const PetsState();

  @override
  List<Object?> get props => [];
}

class PetsInitial extends PetsState {}
class PetsLoading extends PetsState {}
class PetsLoaded extends PetsState {
  final List<Pet> pets;
  const PetsLoaded(this.pets);

  @override
  List<Object?> get props => [pets];
}

class PetsEmpty extends PetsState {}
class PetsError extends PetsState {
  final String message;
  const PetsError(this.message);

  @override
  List<Object?> get props => [message];
}

class PetPublishing extends PetsState {}
class PetPublished extends PetsState {}

class PublishPetEvent extends PetsEvent {
  final Pet pet;
  final List<String> imagePaths;
  const PublishPetEvent(this.pet, this.imagePaths);

  @override
  List<Object?> get props => [pet, imagePaths];
}

class PetsBloc extends Bloc<PetsEvent, PetsState> {
  final PetRepository _repository;
  StreamSubscription<List<Pet>>? _subscription;

  PetsBloc(this._repository) : super(PetsInitial()) {
    on<LoadPetsEvent>(_onLoadPets);
    on<RefreshPetsEvent>(_onRefresh);
    on<PublishPetEvent>(_onPublishPet);
  }

Future<void> _onPublishPet(PublishPetEvent event, Emitter<PetsState> emit) async {
    emit(PetPublishing());
    try {
      // Use repository directly for now - use case registration pending in DI
      final repo = getIt<PetRepository>();
      await repo.publishPet(pet: event.pet, localImagePaths: event.imagePaths);
      emit(PetPublished());
    } catch (e) {
      emit(PetsError(e.toString()));
    }
  }

  void _onLoadPets(LoadPetsEvent event, Emitter<PetsState> emit) {

    emit(PetsLoading());
    _listenToStream();
  }

  void _onRefresh(RefreshPetsEvent event, Emitter<PetsState> emit) {
    _listenToStream();
  }

_listenToStream() {
    emit(PetsLoading());
    _subscription?.cancel();
    _subscription = _repository.getPets().listen(
      (pets) {
        if (pets.isEmpty) {
          emit(PetsEmpty());
        } else {
          emit(PetsLoaded(pets));
        }
      },
      onError: (error) => emit(PetsError(error.toString())),
      onDone: () => emit(PetsEmpty()),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

