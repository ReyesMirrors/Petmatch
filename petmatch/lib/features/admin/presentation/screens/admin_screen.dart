import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../adoption/domain/adoption_repository.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final Future<AppUser?> _currentUserFuture;

  @override
  void initState() {
    super.initState();
    final uid = getIt<AuthService>().currentUser?.uid;
    _currentUserFuture = uid == null
        ? Future.value(null)
        : getIt<AuthRepository>().getUserById(uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _currentUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null || !user.isAdmin) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Acceso restringido. Solo los usuarios con rol de administrador pueden entrar aquí. ' 
                  'Si quieres probar el panel, actualiza el campo "tipo" a "admin" en tu documento de usuario en Firestore.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Admin')),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [Tab(text: 'Donaciones'), Tab(text: 'Veterinarias')],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _donationsTab(),
                      _vetRequestsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _donationsTab() {
    final repo = getIt<AdoptionRepository>();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('estado', isEqualTo: 'pendiente')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No hay donaciones pendientes'));
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final fecha = (d['createdAt'] as Timestamp?)?.toDate();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d['donorNombre']} donó \$${d['monto']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Motivo: ${d['motivo'] ?? 'No especificado'}'),
                    const SizedBox(height: 4),
                    Text('Nequi: ${d['nequiDonador']} → ${d['nequiReceptor']}'),
                    if (fecha != null) ...[
                      const SizedBox(height: 4),
                      Text('Registrada: ${fecha.toLocal().toString().split('.').first}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await repo.confirmDonation(doc.id);
                            if (mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Donación confirmada')));
                            }
                          },
                          child: const Text('Confirmar'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () async {
                            final controller = TextEditingController();
                            final confirmed = await showDialog<bool>(
                              context: ctx,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Rechazar donación'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Puedes dejar un comentario opcional para el donante.'),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: controller,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: 'Comentario (opcional)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancelar')),
                                  ElevatedButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Rechazar')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await repo.rejectDonation(doc.id, comentario: controller.text.trim());
                              if (mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Donación rechazada')));
                              }
                            }
                          },
                          child: const Text('Rechazar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _vetRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('tipo', isEqualTo: 'veterinaria')
          .where('vetStatus', isEqualTo: 'pendiente')
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No hay solicitudes de veterinarias pendientes'));
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['nombre'] ?? 'Veterinaria', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Nombre local: ${d['nombreVet'] ?? 'N/D'}'),
                    const SizedBox(height: 4),
                    Text('Email: ${d['email'] ?? 'N/D'}'),
                    const SizedBox(height: 4),
                    Text('Teléfono: ${d['telefono'] ?? 'N/D'}'),
                    const SizedBox(height: 4),
                    Text('Ciudad: ${d['ciudad'] ?? 'N/D'}'),
                    const SizedBox(height: 4),
                    Text('Ubicación local: ${d['direccionLocal'] ?? 'N/D'}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(doc.id)
                                .update({'vetStatus': 'aprobado', 'verificado': true});
                          },
                          child: const Text('Aprobar'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(doc.id)
                                .update({'vetStatus': 'rechazado', 'verificado': false});
                          },
                          child: const Text('Rechazar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
