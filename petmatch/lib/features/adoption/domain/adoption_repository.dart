import 'entities/entities.dart';

abstract class AdoptionRepository {
  // Adoption
  Future<void> requestAdoption({required String petId, required String petNombre, required String adoptanteId, required String publicadorId, required String mensaje, required String motivo, required String experiencia, required String hogar, required String otrosDetalles});
  Stream<List<AdoptionRequest>> getRequestsPublicador(String uid);
  Stream<List<AdoptionRequest>> getRequestsAdoptante(String uid);
  Future<void> updateAdoptionStatus(String reqId, AdoptionStatus status, {String? comentarioRespuesta});
  Future<bool> hasRequest(String petId, String adoptanteId);
  // Location
  Future<void> requestLocation({required String petId, required String solicitanteId, required String propietarioId});
  Stream<LocationRequest?> watchLocationRequest(String petId, String solicitanteId);
  Future<void> respondLocation(String reqId, LocationReqStatus status, {double? lat, double? lng, String? texto});
  // Chat
  Stream<List<ChatMessage>> getMessages(String chatId);
  Future<void> sendMessage({required String chatId, required String senderId, required String receiverId, required String texto});
  // Donations
  Future<void> createDonation({required String petId, required String donorId, required String donorNombre, required double monto, required String nequiReceptor, required String nequiDonador, required String motivo});
  Future<void> confirmDonation(String donationId);
  Future<void> rejectDonation(String donationId, {String? comentario});
  Stream<List<Donation>> getDonationsForPet(String petId);
  Future<bool> hasActiveDonation(String petId, String donorId);
}
