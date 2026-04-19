import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/enum_extensions.dart';
import '../domain/adoption_repository.dart';
import '../domain/entities/entities.dart';

class AdoptionRepositoryImpl implements AdoptionRepository {
  final FirebaseFirestore _db;
  final _uuid = const Uuid();
  AdoptionRepositoryImpl(this._db);

  // ── Adoption ──────────────────────────────────────────────────────────────
  @override
  Future<void> requestAdoption({required String petId, required String petNombre,
      required String adoptanteId, required String publicadorId, required String mensaje,
      required String motivo, required String experiencia, required String hogar,
      required String otrosDetalles}) async {
    final id = _uuid.v4();
    await _db.collection('adoption_requests').doc(id).set({
      'id': id, 'petId': petId, 'petNombre': petNombre,
      'adoptanteId': adoptanteId, 'publicadorId': publicadorId, 'mensaje': mensaje,
      'motivo': motivo, 'experiencia': experiencia, 'hogar': hogar, 'otrosDetalles': otrosDetalles,
      'estado': AdoptionStatus.pendiente.enumName,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('notifications').doc('adoption_request_$id').set({
      'id': 'adoption_request_$id',
      'recipientId': publicadorId,
      'senderId': adoptanteId,
      'type': 'adoption_request',
      'title': 'Nueva solicitud de adopción',
      'body': 'Hay una nueva solicitud para $petNombre.',
      'petId': petId,
      'requestId': id,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  AdoptionRequest _mapReq(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    return AdoptionRequest(
      id: d.id, petId: m['petId'] ?? '', petNombre: m['petNombre'] ?? '',
      adoptanteId: m['adoptanteId'] ?? '', publicadorId: m['publicadorId'] ?? '',
      mensaje: m['mensaje'] ?? '',
      motivo: m['motivo'] ?? '',
      experiencia: m['experiencia'] ?? '',
      hogar: m['hogar'] ?? '',
      otrosDetalles: m['otrosDetalles'] ?? '',
      comentarioRespuesta: m['comentarioRespuesta'] ?? '',
      estado: AdoptionStatus.values.firstWhere((e) => e.enumName == m['estado'], orElse: () => AdoptionStatus.pendiente),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Stream<List<AdoptionRequest>> getRequestsPublicador(String uid) =>
      _db.collection('adoption_requests').where('publicadorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true).snapshots()
          .map((s) => s.docs.map(_mapReq).toList());

  @override
  Stream<List<AdoptionRequest>> getRequestsAdoptante(String uid) =>
      _db.collection('adoption_requests').where('adoptanteId', isEqualTo: uid)
          .orderBy('createdAt', descending: true).snapshots()
          .map((s) => s.docs.map(_mapReq).toList());

  @override
  Future<void> updateAdoptionStatus(String reqId, AdoptionStatus s, {String? comentarioRespuesta}) async {
    final ref = _db.collection('adoption_requests').doc(reqId);
    final doc = await ref.get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final adoptanteId = data['adoptanteId'] as String?;
    final petNombre = data['petNombre'] as String? ?? 'tu mascota';

    final updateData = <String, dynamic>{'estado': s.enumName, 'updatedAt': FieldValue.serverTimestamp()};
    if (comentarioRespuesta != null) {
      updateData['comentarioRespuesta'] = comentarioRespuesta;
    }

    await ref.update(updateData);

    if (adoptanteId != null && adoptanteId.isNotEmpty) {
      final bodyMessage = s == AdoptionStatus.aprobada
          ? 'Tu solicitud para $petNombre fue aprobada.'
          : 'Tu solicitud para $petNombre fue rechazada.';
      final body = comentarioRespuesta != null && comentarioRespuesta.isNotEmpty
          ? '$bodyMessage\nComentario: $comentarioRespuesta'
          : bodyMessage;

      await _db.collection('notifications').doc('adoption_response_$reqId').set({
        'id': 'adoption_response_$reqId',
        'recipientId': adoptanteId,
        'senderId': data['publicadorId'] as String? ?? '',
        'type': 'adoption_response',
        'title': 'Respuesta a tu solicitud de adopción',
        'body': body,
        'petId': data['petId'] as String? ?? '',
        'requestId': reqId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<bool> hasRequest(String petId, String adoptanteId) async {
    final q = await _db.collection('adoption_requests')
        .where('petId', isEqualTo: petId).where('adoptanteId', isEqualTo: adoptanteId)
        .limit(1).get();
    return q.docs.isNotEmpty;
  }

  // ── Location ──────────────────────────────────────────────────────────────
  @override
  Future<void> requestLocation({required String petId, required String solicitanteId,
      required String propietarioId}) async {
    final id = locationRequestId(petId, solicitanteId);
    await _db.collection('location_requests').doc(id).set({
      'id': id, 'petId': petId, 'solicitanteId': solicitanteId,
      'propietarioId': propietarioId, 'estado': LocationReqStatus.pendiente.enumName,
      'lat': null, 'lng': null, 'ubicacionTexto': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<LocationRequest?> watchLocationRequest(String petId, String solicitanteId) {
    final id = locationRequestId(petId, solicitanteId);
    return _db.collection('location_requests').doc(id).snapshots().map((d) {
      if (!d.exists) return null;
      final m = d.data() as Map<String, dynamic>;
      return LocationRequest(
        id: d.id, petId: m['petId'] ?? '', solicitanteId: m['solicitanteId'] ?? '',
        propietarioId: m['propietarioId'] ?? '',
        estado: LocationReqStatus.values.firstWhere((e) => e.enumName == m['estado'], orElse: () => LocationReqStatus.pendiente),
        ubicacionTexto: m['ubicacionTexto'],
        lat: (m['lat'] as num?)?.toDouble(), lng: (m['lng'] as num?)?.toDouble(),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }

  @override
  Future<void> respondLocation(String reqId, LocationReqStatus status,
      {double? lat, double? lng, String? texto}) async =>
      _db.collection('location_requests').doc(reqId)
          .update({'estado': status.enumName, 'lat': lat, 'lng': lng, 'ubicacionTexto': texto});

  // ── Chat ──────────────────────────────────────────────────────────────────
  @override
  Stream<List<ChatMessage>> getMessages(String chatId) =>
      _db.collection('chats').doc(chatId).collection('messages')
          .orderBy('timestamp').snapshots()
          .map((s) => s.docs.map((d) {
            final m = d.data();
            return ChatMessage(
              id: d.id, chatId: chatId,
              senderId: m['senderId'] ?? '', receiverId: m['receiverId'] ?? '',
              texto: m['texto'] ?? '', leido: m['leido'] ?? false,
              timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList());

  @override
  Future<void> sendMessage({required String chatId, required String senderId,
      required String receiverId, required String texto}) async {
    final id = _uuid.v4();
    await _db.collection('chats').doc(chatId).collection('messages').doc(id).set({
      'senderId': senderId, 'receiverId': receiverId,
      'texto': texto, 'leido': false, 'timestamp': FieldValue.serverTimestamp(),
    });
    await _db.collection('chats').doc(chatId).set({
      'participantes': [senderId, receiverId],
      'ultimoMensaje': texto, 'ultimaActividad': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('notifications').doc('chat_message_${chatId}_$id').set({
      'id': 'chat_message_${chatId}_$id',
      'recipientId': receiverId,
      'senderId': senderId,
      'type': 'chat_message',
      'title': 'Nuevo mensaje de PetMatch',
      'body': texto,
      'chatId': chatId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Donations ──────────────────────────────────────────────────────────────
  @override
  Future<void> createDonation({required String petId, required String donorId,
      required String donorNombre, required double monto, required String nequiReceptor,
      required String nequiDonador, required String motivo}) async {
    final id = _uuid.v4();
    final petSnapshot = await _db.collection('pets').doc(petId).get();
    final petNombre = (petSnapshot.data() as Map<String, dynamic>?)?['nombre'] ?? '';
    await _db.collection('donations').doc(id).set({
      'id': id, 'petId': petId, 'petNombre': petNombre,
      'donorId': donorId, 'donorNombre': donorNombre,
      'monto': monto, 'nequiReceptor': nequiReceptor, 'nequiDonador': nequiDonador,
      'motivo': motivo,
      'estado': DonationStatus.pendiente.enumName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> confirmDonation(String donationId) async {
    final d = await _db.collection('donations').doc(donationId).get();
    if (!d.exists) return;
    final m = d.data() as Map<String, dynamic>;
    final monto = (m['monto'] as num).toDouble();
    final petId = m['petId'] as String;
    final donorId = m['donorId'] as String;
    final petNombre = m['petNombre'] as String? ?? 'tu mascota';

    await _db.runTransaction((tx) async {
      tx.update(_db.collection('donations').doc(donationId), {'estado': DonationStatus.confirmada.enumName});
      tx.update(_db.collection('pets').doc(petId), {'totalRecaudado': FieldValue.increment(monto)});
    });

    await _db.collection('notifications').doc('donation_confirmed_$donationId').set({
      'id': 'donation_confirmed_$donationId',
      'recipientId': donorId,
      'senderId': '',
      'type': 'donation_confirmed',
      'title': 'Donación confirmada',
      'body': 'Tu donación de \$${monto.toStringAsFixed(0)} para $petNombre fue confirmada.',
      'petId': petId,
      'donationId': donationId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> rejectDonation(String donationId, {String? comentario}) async {
    final d = await _db.collection('donations').doc(donationId).get();
    if (!d.exists) return;
    final m = d.data() as Map<String, dynamic>;
    final donorId = m['donorId'] as String;
    final petNombre = m['petNombre'] as String? ?? 'la mascota';
    final message = comentario != null && comentario.isNotEmpty
        ? 'Tu donación para $petNombre fue rechazada. Comentario: $comentario'
        : 'Tu donación para $petNombre fue rechazada.';

    await _db.collection('donations').doc(donationId)
        .update({'estado': DonationStatus.fallida.enumName});
    await _db.collection('notifications').doc('donation_rejected_$donationId').set({
      'id': 'donation_rejected_$donationId',
      'recipientId': donorId,
      'senderId': '',
      'type': 'donation_rejected',
      'title': 'Donación rechazada',
      'body': message,
      'petId': m['petId'] as String? ?? '',
      'donationId': donationId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Donation>> getDonationsForPet(String petId) =>
      _db.collection('donations')
          .where('petId', isEqualTo: petId)
          .where('estado', isEqualTo: DonationStatus.confirmada.enumName)
          .orderBy('createdAt', descending: true).snapshots()
          .map((s) => s.docs.map((d) {
            final m = d.data() as Map<String, dynamic>;
            return Donation(
              id: d.id, petId: m['petId'] ?? '', petNombre: m['petNombre'] ?? '', donorId: m['donorId'] ?? '',
              donorNombre: m['donorNombre'] ?? '', monto: (m['monto'] ?? 0).toDouble(),
              nequiReceptor: m['nequiReceptor'] ?? '', nequiDonador: m['nequiDonador'] ?? '',
              motivo: m['motivo'] ?? '',
              estado: DonationStatus.values.firstWhere((e) => e.enumName == m['estado'], orElse: () => DonationStatus.pendiente),
              createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList());

  @override
  Future<bool> hasActiveDonation(String petId, String donorId) async {
    final q = await _db.collection('donations')
        .where('petId', isEqualTo: petId).where('donorId', isEqualTo: donorId)
        .where('estado', isEqualTo: DonationStatus.confirmada.enumName).limit(1).get();
    return q.docs.isNotEmpty;
  }
}
