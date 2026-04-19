import '../adoption_repository.dart';
import '../entities/entities.dart';

class RequestAdoptionUseCase {
  final AdoptionRepository r;
  RequestAdoptionUseCase(this.r);
  Future<void> execute({required String petId, required String petNombre,
      required String adoptanteId, required String publicadorId, required String mensaje,
      required String motivo, required String experiencia, required String hogar, required String otrosDetalles}) =>
      r.requestAdoption(
        petId: petId,
        petNombre: petNombre,
        adoptanteId: adoptanteId,
        publicadorId: publicadorId,
        mensaje: mensaje,
        motivo: motivo,
        experiencia: experiencia,
        hogar: hogar,
        otrosDetalles: otrosDetalles,
      );
}

class UpdateAdoptionStatusUseCase {
  final AdoptionRepository r;
  UpdateAdoptionStatusUseCase(this.r);
  Future<void> execute(String id, AdoptionStatus s, {String? comentarioRespuesta}) =>
      r.updateAdoptionStatus(id, s, comentarioRespuesta: comentarioRespuesta);
}
