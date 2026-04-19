import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _S();
}

class _S extends State<EditProfileScreen> {
  final name = TextEditingController();
  final bio = TextEditingController();
  File? image;
  String? photoUrl;
  bool _loading = true;
  bool _saving = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};
    name.text = data['name'] ?? '';
    bio.text = data['bio'] ?? '';
    photoUrl = data['photoUrl'] as String?;

    setState(() {
      _loading = false;
    });
  }

  Future<void> pickImage() async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      setState(() {
        image = File(x.path);
      });
    }
  }

  Future<String> _uploadProfilePhoto(String uid, File file) async {
    final ref =
        FirebaseStorage.instance.ref().child('user_photos/$uid/profile.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<void> save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es obligatorio.')));
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final data = {
        'name': name.text.trim(),
        'bio': bio.text.trim(),
      };

      if (image != null) {
        final url = await _uploadProfilePhoto(user.uid, image!);
        data['photoUrl'] = url;
        photoUrl = url;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente.')));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el perfil: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: image != null
                          ? FileImage(image!) as ImageProvider
                          : (photoUrl != null && photoUrl!.isNotEmpty)
                              ? NetworkImage(photoUrl!)
                              : null,
                      child: image == null &&
                              (photoUrl == null || photoUrl!.isEmpty)
                          ? const Icon(Icons.camera_alt)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bio,
                    decoration: const InputDecoration(labelText: 'Bio'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar'),
                  )
                ],
              ),
            ),
    );
  }
}
