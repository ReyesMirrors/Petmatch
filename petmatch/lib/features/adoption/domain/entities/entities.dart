import 'package:equatable/equatable.dart';

enum AdoptionStatus { pendiente, en_revision, aprobada, rechazada }
enum LocationReqStatus { pendiente, aprobada, rechazada }
enum DonationStatus { pendiente, confirmada, fallida }

String chatIdFor(String userA, String userB, String petId) {
  final ids = [userA, userB]..sort();
  return '${ids[0]}_${ids[1]}_$petId';
}

String locationRequestId(String petId, String solicitanteId) => '${petId}_$solicitanteId';

// ── Adoption Request ─────────────────────────────────────────────────────────
class AdoptionRequest extends Equatable {
  final String id;
  final String petId;
  final String petNombre;
  final String adoptanteId;
  final String publicadorId;
  final String mensaje;
  final String motivo;
  final String experiencia;
  final String hogar;
  final String otrosDetalles;
  final String comentarioRespuesta;
  final AdoptionStatus estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdoptionRequest({
    required this.id, required this.petId, required this.petNombre,
    required this.adoptanteId, required this.publicadorId, required this.mensaje,
    required this.motivo, required this.experiencia, required this.hogar,
    required this.otrosDetalles, required this.comentarioRespuesta,
    required this.estado, required this.createdAt, required this.updatedAt,
  });

  String get estadoDisplay {
    switch (estado) {
      case AdoptionStatus.pendiente: return 'Pendiente';
      case AdoptionStatus.en_revision: return 'En revision';
      case AdoptionStatus.aprobada: return 'Aprobada';
      case AdoptionStatus.rechazada: return 'Rechazada';
    }
  }

  @override
  List<Object?> get props => [id, petId, adoptanteId, estado, motivo, experiencia, hogar, otrosDetalles, comentarioRespuesta];
}

// ── Chat Message ──────────────────────────────────────────────────────────────
class ChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String texto;
  final bool leido;
  final DateTime timestamp;

  const ChatMessage({
    required this.id, required this.chatId, required this.senderId,
    required this.receiverId, required this.texto, required this.leido,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, chatId, senderId, texto, timestamp];
}

// ── Location Request ──────────────────────────────────────────────────────────
class LocationRequest extends Equatable {
  final String id;
  final String petId;
  final String solicitanteId;
  final String propietarioId;
  final LocationReqStatus estado;
  final String? ubicacionTexto;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  const LocationRequest({
    required this.id, required this.petId, required this.solicitanteId,
    required this.propietarioId, required this.estado,
    this.ubicacionTexto, this.lat, this.lng, required this.createdAt,
  });

  @override
  List<Object?> get props => [id, petId, solicitanteId, estado];
}

// ── Donation ──────────────────────────────────────────────────────────────────
class Donation extends Equatable {
  final String id;
  final String petId;
  final String petNombre;
  final String donorId;
  final String donorNombre;
  final double monto;
  final String nequiReceptor;
  final String nequiDonador;
  final String motivo;
  final DonationStatus estado;
  final DateTime createdAt;

  const Donation({
    required this.id, required this.petId, required this.petNombre, required this.donorId,
    required this.donorNombre, required this.monto,
    required this.nequiReceptor, required this.nequiDonador,
    required this.motivo,
    required this.estado, required this.createdAt,
  });

  @override
  List<Object?> get props => [id, petId, petNombre, donorId, monto, motivo, estado];
}
