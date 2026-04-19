import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/enum_extensions.dart';
import '../../pets/domain/entities/pet.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null && userId == null) {
      return const Center(child: Text('No autenticado'));
    }

    final profileId = userId ?? currentUser!.uid;
    final isOwnProfile = currentUser?.uid == profileId;

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(profileId)
        .snapshots();
    final petsStream = FirebaseFirestore.instance
        .collection('pets')
        .where('publicadorId', isEqualTo: profileId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error al cargar perfil: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final nombre = data['nombre'] ?? data['name'] ?? 'Sin nombre';
        final email = data['email'] ?? currentUser?.email ?? '';
        final photoUrl = data['fotoUrl'] ?? data['photoUrl'] ?? '';
        final bio = data['bio'] ?? data['descripcion'] ?? '';
        final tipoValor = (data['tipo'] ?? 'normal').toString();
        final isVet = tipoValor.toLowerCase().contains('veterinaria');
        final vetStatus = data['vetStatus'] ?? '';
        final vetLabel = isVet
            ? 'Veterinaria${vetStatus != '' ? ' (${vetStatus.toString()})' : ''}'
            : 'Persona normal';
        final nombreVet = data['nombreVeterinaria'] ?? '';
        final direccionLocal = data['direccionLocal'] ?? '';
        final verified = data['verificado'] == true;
        final favoritesCount = (data['favorites'] ?? data['favoritos'] ?? []).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isNotEmpty
                      ? null
                      : const Icon(Icons.person, size: 40),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  nombre,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Center(child: Text(email)),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  bio.isNotEmpty ? bio : 'Sin bio',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Chip(
                  label: Text(vetLabel),
                  backgroundColor: isVet ? Colors.green.shade100 : Colors.blueGrey.shade100,
                ),
              ),
              if (isVet && verified) ...[
                const SizedBox(height: 8),
                Center(
                  child: Chip(
                    label: const Text('Verificado'),
                    backgroundColor: Colors.amber.shade100,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('Mascotas', '0'),
                  _stat('Favoritos', '$favoritesCount'),
                  _stat('Likes', '0'),
                ],
              ),
              const SizedBox(height: 20),
              if (isVet && nombreVet.isNotEmpty) ...[
                Text('Nombre veterinaria: $nombreVet'),
                const SizedBox(height: 4),
              ],
              if (isVet && direccionLocal.isNotEmpty) ...[
                Text('Dirección: $direccionLocal'),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOwnProfile ? 'Tus publicaciones' : 'Publicaciones de $nombre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.push('/profile/edit'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: petsStream,
                builder: (context, petsSnapshot) {
                  if (petsSnapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error al cargar publicaciones: ${petsSnapshot.error}'));
                  }
                  if (petsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pets = petsSnapshot.data?.docs ?? [];
                  if (pets.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(isOwnProfile
                          ? 'No tienes mascotas publicadas aún.'
                          : 'Este usuario no tiene mascotas publicadas.'),
                    );
                  }

                  final sortedPets = pets.toList()
                    ..sort((a, b) {
                      final aTs = (a['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final bTs = (b['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return bTs.compareTo(aTs);
                    });

                  final petIds = sortedPets.map((doc) => doc.id).cast<String>().toList();
                  final petCards = sortedPets.map((doc) {
                    final p = doc.data() as Map<String, dynamic>;
                    final estado = (p['estado'] as String?) ?? 'disponible';
                    final statusLabel = _statusLabel(estado);
                    final statusColor = _statusColor(estado);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p['nombre'] ?? 'Mascota',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Chip(
                                  label: Text(statusLabel),
                                  backgroundColor: statusColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (p['fotos'] is List && p['fotos'].isNotEmpty && p['fotos'][0] is String)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  p['fotos'][0] as String,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 140,
                                    color: Colors.grey.shade300,
                                    child: const Center(child: Icon(Icons.broken_image)),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(p['ciudad'] ?? ''),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => context.push('/pet/${doc.id}'),
                                  child: const Text('Ver detalles'),
                                ),
                                if (estado == 'disponible') ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _updatePetStatus(
                                        context,
                                        doc.id,
                                        PetStatus.adoptado.enumName,
                                        'adoptada'),
                                    child: const Text('Marcar adoptada'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => _updatePetStatus(
                                        context,
                                        doc.id,
                                        PetStatus.cancelado.enumName,
                                        'cancelada'),
                                    child: const Text('Cancelar publicación'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...petCards,
                      if (petIds.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Historial de donaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: petIds.length <= 10
                              ? FirebaseFirestore.instance
                                  .collection('donations')
                                  .where('estado', isEqualTo: 'confirmada')
                                  .where('petId', whereIn: petIds)
                                  .orderBy('createdAt', descending: true)
                                  .snapshots()
                              : FirebaseFirestore.instance
                                  .collection('donations')
                                  .where('estado', isEqualTo: 'confirmada')
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                          builder: (context, donationSnapshot) {
                            if (donationSnapshot.hasError) {
                              return Center(child: Text('Error al cargar donaciones: ${donationSnapshot.error}'));
                            }
                            if (!donationSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final donations = donationSnapshot.data!.docs.where((doc) {
                              if (petIds.length <= 10) return true;
                              final m = doc.data() as Map<String, dynamic>;
                              return petIds.contains(m['petId']);
                            }).toList();

                            if (donations.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Aún no hay donaciones confirmadas para estas mascotas.'),
                              );
                            }

                            return Column(
                              children: donations.map((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                final fecha = (d['createdAt'] as Timestamp?)?.toDate();
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Text(d['petNombre'] ?? 'Mascota'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Donante: ${d['donorNombre'] ?? 'Anónimo'}'),
                                        Text('Motivo: ${d['motivo'] ?? 'No especificado'}'),
                                        if (fecha != null)
                                          Text('Fecha: ${fecha.toLocal().toString().split('.').first}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    trailing: Text(
                                      '\$${double.tryParse((d['monto'] ?? 0).toString())?.toStringAsFixed(0) ?? '0'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
              if (isOwnProfile) ...[
                const SizedBox(height: 20),
                const Text('Solicitudes enviadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('adoption_requests')
                      .where('adoptanteId', isEqualTo: currentUser!.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, requestSnapshot) {
                    if (requestSnapshot.hasError) {
                      return Center(child: Text('Error al cargar solicitudes: ${requestSnapshot.error}'));
                    }
                    if (requestSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = requestSnapshot.data?.docs ?? [];
                    if (requests.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('No tienes solicitudes enviadas.'),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: requests.map((doc) {
                        final r = doc.data() as Map<String, dynamic>;
                        final status = (r['estado'] as String?) ?? 'pendiente';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(r['petNombre'] ?? 'Mascota'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['mensaje'] ?? ''),
                                if ((r['comentarioRespuesta'] as String?)?.isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Text('Comentario de respuesta: ${r['comentarioRespuesta']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ],
                            ),
                            trailing: Chip(label: Text(status[0].toUpperCase() + status.substring(1))),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              if (isOwnProfile)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String title, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title),
      ],
    );
  }

  String _statusLabel(String estado) {
    switch (estado) {
      case 'adoptado':
        return 'Adoptada';
      case 'en_proceso':
        return 'En proceso';
      case 'cancelado':
        return 'Cancelada';
      default:
        return 'Disponible';
    }
  }

  Color _statusColor(String estado) {
    switch (estado) {
      case 'adoptado':
        return Colors.blue.shade100;
      case 'en_proceso':
        return Colors.orange.shade100;
      case 'cancelado':
        return Colors.red.shade100;
      default:
        return Colors.green.shade100;
    }
  }

  Future<void> _updatePetStatus(
      BuildContext context, String petId, String status, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(petId)
          .update({'estado': status});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publicación marcada como $message.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $e')),
      );
    }
  }
}
