import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';
import '../domain/entities/app_user.dart';
import 'models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _google = GoogleSignIn();
  AppUser? _cache;

  AuthRepositoryImpl(this._auth, this._db, this._storage);

  @override AppUser? get currentUser => _cache;

  @override
  Stream<AppUser?> get userStream => _auth.authStateChanges().asyncMap((u) async {
    if (u == null) { _cache = null; return null; }
    _cache = await getUserById(u.uid);
    return _cache;
  });

  @override
  Future<String> loginWithEmail({required String email, required String password}) async {
    final c = await _auth.signInWithEmailAndPassword(email: email, password: password);
    _cache = await getUserById(c.user!.uid);
    return c.user!.uid;
  }

  @override
  Future<String> loginWithGoogle() async {
    final g = await _google.signIn();
    if (g == null) throw Exception('Cancelado');
    final ga = await g.authentication;
    final c = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(accessToken: ga.accessToken, idToken: ga.idToken));
    final uid = c.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      final u = AppUser(uid: uid, nombre: c.user!.displayName ?? 'Usuario',
          email: c.user!.email ?? '', tipo: UserType.normal,
          fotoUrl: c.user!.photoURL, createdAt: DateTime.now());
      await _db.collection('users').doc(uid).set(UserModel.fromEntity(u).toFirestore());
    }
    _cache = await getUserById(uid);
    return uid;
  }

  @override
  Future<String> registerNormal({required String nombre, required String email,
      required String password, required String telefono, required String ciudad,
      required String nequi}) async {
    final c = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = c.user!.uid;
    final u = AppUser(uid: uid, nombre: nombre, email: email, telefono: telefono,
        ciudad: ciudad, tipo: UserType.normal, nequiTelefono: nequi, createdAt: DateTime.now());
    await _db.collection('users').doc(uid).set(UserModel.fromEntity(u).toFirestore());
    _cache = u;
    return uid;
  }

  @override
  Future<String> registerVeterinaria({required String nombre, required String email,
      required String password, required String telefono, required String ciudad,
      required String nombreVet, required String nequi, required String direccionLocal,
      required File cedulaFile, required File certificadoFile}) async {
    final c = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = c.user!.uid;
    final cUrl = await _upload(uid, 'cedula', cedulaFile);
    final certUrl = await _upload(uid, 'cert', certificadoFile);
    final u = AppUser(uid: uid, nombre: nombre, email: email, telefono: telefono,
        ciudad: ciudad, tipo: UserType.veterinaria, vetStatus: VetStatus.pendiente,
        cedulaUrl: cUrl, certificadoUrl: certUrl, nombreVeterinaria: nombreVet,
        direccionLocal: direccionLocal, nequiTelefono: nequi, createdAt: DateTime.now());
    await _db.collection('users').doc(uid).set(UserModel.fromEntity(u).toFirestore());
    await _db.collection('vet_requests').doc(uid).set({
      'uid': uid, 'nombre': nombre, 'email': email, 'nombreVet': nombreVet,
      'telefono': telefono, 'direccionLocal': direccionLocal,
      'cedulaUrl': cUrl, 'certificadoUrl': certUrl,
      'estado': 'pendiente', 'createdAt': FieldValue.serverTimestamp(),
    });
    _cache = u;
    return uid;
  }

  Future<String> _upload(String uid, String tipo, File f) async {
    final ref = _storage.ref().child('vet_docs/\$uid/\$tipo.jpg');
    final t = await ref.putFile(f);
    return t.ref.getDownloadURL();
  }

  @override
  Future<void> logout() async { await _google.signOut(); await _auth.signOut(); _cache = null; }

  @override
  Future<AppUser?> getUserById(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    if (!d.exists) return null;
    return UserModel.fromFirestore(d);
  }

  @override
  Future<void> updateUser(AppUser u) async =>
      _db.collection('users').doc(u.uid).update(UserModel.fromEntity(u).toFirestore());
}
