import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/enum_extensions.dart';

import '../domain/entities/pet.dart';
import '../domain/pet_repository.dart';
import 'models/pet_model.dart';

class PetRepositoryImpl implements PetRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();
  static const _col = 'pets';

  PetRepositoryImpl(this._db, this._storage);

@override
  Stream<List<Pet>> getPets({PetFilter? filter}) => getPetsPaginated(filter: filter);
  
  @override
  Stream<List<Pet>> getPetsPaginated({
    PetFilter? filter,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> q = _db.collection(_col)
        .where('estado', isEqualTo: PetStatus.disponible.enumName)
        .orderBy('createdAt', descending: true)
        .limit(limit);
        
    if (startAfter != null) {
      q = q.startAfter([startAfter]);
    }
        
    if (filter != null) {
      if (filter.tipo != null) q = q.where('tipo', isEqualTo: filter.tipo!.enumName);
      if (filter.sexo != null) q = q.where('sexo', isEqualTo: filter.sexo!.enumName);
      if (filter.tamano != null) q = q.where('tamano', isEqualTo: filter.tamano!.enumName);
      if (filter.ciudad != null && filter.ciudad!.isNotEmpty)
        q = q.where('ciudad', isEqualTo: filter.ciudad);
      if (filter.estadoSalud != null)
        q = q.where('estadoSalud', isEqualTo: filter.estadoSalud!.enumName);
      if (filter.situacion != null)
        q = q.where('situacion', isEqualTo: filter.situacion!.enumName);
    }
return q.snapshots().map((s) {
      final pets = s.docs.map((doc) => PetModel.fromFirestore(doc)).toList();
return pets.cast<Pet>(); // cast List<PetModel> to List<Pet> (PetModel extends Pet)
    }).asBroadcastStream(); // allow multiple listeners if needed

  }

  @override
  Future<Pet?> getPetById(String id) async {
    final d = await _db.collection(_col).doc(id).get();
    return d.exists ? PetModel.fromFirestore(d) : null;
  }

  @override
  Future<String> publishPet({required Pet pet, required List<String> localImagePaths}) async {
    final id = _uuid.v4();
    final urls = await _uploadImages(id, localImagePaths);
    final m = PetModel.fromEntity(pet.copyWith(id: id, fotos: urls));
    await _db.collection(_col).doc(id).set(m.toFirestore());
    return id;
  }

  @override
  Future<void> updatePetStatus(String petId, PetStatus s) =>
      _db.collection(_col).doc(petId).update({'estado': s.enumName});

  @override
  Future<void> setApoyador(String petId, String? apoyadorId) =>
      _db.collection(_col).doc(petId).update({'apoyadorActivoId': apoyadorId});

  @override
  Future<void> addRecaudado(String petId, double monto) =>
      _db.collection(_col).doc(petId).update({'totalRecaudado': FieldValue.increment(monto)});

  @override
  Future<void> deletePet(String petId) async {
    try {
      final l = await _storage.ref().child('pets/\$petId').listAll();
      for (final i in l.items) await i.delete();
    } catch (_) {}
    await _db.collection(_col).doc(petId).delete();
  }

  Future<List<String>> _uploadImages(String petId, List<String> paths) async {
    final urls = <String>[];
    for (int i = 0; i < paths.length; i++) {
      final b = await FlutterImageCompress.compressWithFile(paths[i], quality: 75, minWidth: 1024, minHeight: 1024);
      if (b == null) continue;
      final ref = _storage.ref().child('pets/\$petId/img_\$i.jpg');
      final t = await ref.putData(b, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await t.ref.getDownloadURL());
    }
    return urls;
  }
}
