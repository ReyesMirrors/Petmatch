import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/enum_extensions.dart';
import '../../../adoption/domain/adoption_repository.dart';
import '../../../adoption/domain/entities/entities.dart';
import '../../../pets/data/models/pet_model.dart';
import '../../../pets/domain/entities/pet.dart';

class PetDetailScreen extends StatelessWidget {
  final String petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
appBar: AppBar(
        title: const Text('Detalle mascota'),
leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pets')
            .doc(petId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar la mascota: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontr� la mascota.'));
          }

          final pet = PetModel.fromFirestore(snapshot.data!);
          final isOwner = currentUser?.uid == pet.publicadorId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pet.fotos.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: pet.fotos.first,
                    height: 280,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 280,
                      color: Colors.grey.shade300,
                      child: const Center(
                          child: Icon(Icons.broken_image, size: 48)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pet.nombre,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(pet.estadoPublicacionDisplay),
                            backgroundColor: _chipColorForStatus(pet.estado),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(pet.tipo.enumName.toUpperCase()),
                          _buildInfoChip(
                              pet.raza.isNotEmpty ? pet.raza : 'Sin raza'),
                          _buildInfoChip(pet.edadDisplay),
                          _buildInfoChip(pet.sexo.enumName),
                          _buildInfoChip(pet.tamano.enumName),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Ubicaci�n'),
                      Text(
                          pet.ciudad.isNotEmpty ? pet.ciudad : 'No disponible'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person),
                        label: const Text('Ver perfil del publicador'),
                        onPressed: () {
                          GoRouter.of(context).go('/user/${pet.publicadorId}');
                        },
                      ),
                      const SizedBox(height: 12),
                      if (pet.metaDonacion > 0) ...[
                        Text('Campaña de donación', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: pet.porcentaje, color: Colors.green.shade700, backgroundColor: Colors.grey.shade200, minHeight: 10),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Recaudado: \$${pet.totalRecaudado.toStringAsFixed(0)}'),
                          Text('Meta: \$${pet.metaDonacion.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        if (!pet.metaCumplida) ...[
                          const SizedBox(height: 4),
                          Text('Falta: \$${(pet.metaDonacion - pet.totalRecaudado).clamp(0, double.infinity).toStringAsFixed(0)}', style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => GoRouter.of(context).push('/donate/${pet.id}'),
                          icon: const Icon(Icons.attach_money),
                          label: const Text('Donar para esta mascota'),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Historial de donaciones'),
                        const SizedBox(height: 8),
                        StreamBuilder<List<Donation>>(
                          stream: getIt<AdoptionRepository>().getDonationsForPet(pet.id),
                          builder: (ctx, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 120,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final donations = snap.data;
                            if (donations == null || donations.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text('Aún no hay donaciones confirmadas.'),
                              );
                            }
                            return Column(
                              children: donations.map((donation) {
                                final fecha = donation.createdAt.toLocal();
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(donation.donorNombre, style: const TextStyle(fontWeight: FontWeight.bold))),
                                            Text('\$${donation.monto.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('Motivo: ${donation.motivo.isNotEmpty ? donation.motivo : 'No especificado'}'),
                                        const SizedBox(height: 6),
                                        Text('Confirmada: ${fecha.toLocal().toString().split('.').first}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildSectionTitle('Salud'),
                      Text(pet.saludDisplay),
                      if (pet.descripcionSalud.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(pet.descripcionSalud),
                      ],
                      const SizedBox(height: 12),
                      _buildSectionTitle('Situaci�n'),
                      Text(pet.situacionDisplay),
                      const SizedBox(height: 12),
                      _buildSectionTitle('Vacunado / Esterilizado'),
                      Text('Vacunado: ${pet.vacunado ? 'S�' : 'No'}'),
                      const SizedBox(height: 4),
                      Text('Esterilizado: ${pet.esterilizado ? 'S�' : 'No'}'),
                      const SizedBox(height: 12),
                      _buildSectionTitle('Descripci�n'),
                      Text(pet.descripcion.isNotEmpty
                          ? pet.descripcion
                          : 'Sin descripci�n'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Datos de publicaci�n'),
                      Text('ID: ${pet.id}'),
                      const SizedBox(height: 4),
                      Text(
                          'Fecha: ${pet.createdAt.toLocal().toString().split(' ').first}'),
                      const SizedBox(height: 20),
                      if (!isOwner && pet.estado == PetStatus.disponible) ...[
                        if (currentUser == null)
                          ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.login),
                            label: const Text('Inicia sesión para solicitar'),
                          )
                        else
                          FutureBuilder<bool>(
                            future: getIt<AdoptionRepository>().hasRequest(
                              pet.id,
                              currentUser.uid,
                            ),
                            builder: (ctx, snap) {
                              if (!snap.hasData) {
                                return const SizedBox(
                                  height: 48,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final hasRequest = snap.data!;
                              return ElevatedButton.icon(
                                onPressed: () {
                                  if (hasRequest) {
                                    final chatId = chatIdFor(currentUser.uid, pet.publicadorId, pet.id);
                                    GoRouter.of(context).push('/chat/$chatId/${pet.publicadorId}');
                                  } else {
                                    GoRouter.of(context).push('/adopt/${pet.id}');
                                  }
                                },
                                icon: Icon(hasRequest ? Icons.chat_bubble : Icons.pets),
                                label: Text(hasRequest
                                    ? 'Ir al chat'
                                    : 'Solicitar adopción'),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                      ],
                      if (isOwner && pet.estado == PetStatus.disponible) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _changeStatus(context, pet,
                                    PetStatus.adoptado, 'adoptada'),
                                child: const Text('Marcar adoptada'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _changeStatus(context, pet,
                                    PetStatus.cancelado, 'cancelada'),
                                child: const Text('Cancelar publicación'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Chip(
      label: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: Colors.blueGrey,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Color _chipColorForStatus(PetStatus status) {
    switch (status) {
      case PetStatus.disponible:
        return Colors.green.shade200;
      case PetStatus.en_proceso:
        return Colors.orange.shade200;
      case PetStatus.adoptado:
        return Colors.blue.shade200;
      case PetStatus.cancelado:
        return Colors.red.shade200;
    }
  }

  Future<void> _changeStatus(
      BuildContext context, Pet pet, PetStatus newStatus, String label) async {
    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(pet.id)
          .update({'estado': newStatus.enumName});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La mascota ahora est� $label.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el estado: $e')),
        );
      }
    }
  }
}
