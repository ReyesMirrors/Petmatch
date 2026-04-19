import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: const Center(child: Text('Inicia sesión para ver tus notificaciones.')),
      );
    }

    final notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    final donationsStream = FirebaseFirestore.instance
        .collection('donations')
        .where('donorId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notificaciones'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Notificaciones'), Tab(text: 'Donaciones')],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar notificaciones: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No tienes notificaciones aún.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] as String? ?? 'Notificación';
                    final body = data['body'] as String? ?? '';
                    final type = data['type'] as String? ?? 'notification';
                    final read = data['read'] == true;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final chatId = data['chatId'] as String?;
                    final senderId = data['senderId'] as String?;
                    final petId = data['petId'] as String?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: Icon(
                          read ? Icons.notifications : Icons.notifications_active,
                          color: read ? Colors.grey : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(body),
                            if (createdAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${createdAt.toLocal()}'.split('.').first,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ],
                        ),
                        trailing: read ? null : const Text('Nuevo', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        onTap: () async {
                          if (!read) {
                            await doc.reference.update({'read': true});
                          }
                          if (type == 'chat_message' && chatId != null && senderId != null) {
                            context.push('/chat/$chatId/$senderId');
                          } else if (type == 'adoption_request' || type == 'adoption_response') {
                            context.push('/requests');
                          } else if ((type == 'donation_confirmed' || type == 'donation_rejected') && petId != null) {
                            context.push('/pet/$petId');
                          } else if (petId != null) {
                            context.push('/pet/$petId');
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: donationsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar donaciones: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Aún no tienes donaciones registradas.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final petNombre = data['petNombre'] as String? ?? 'Mascota';
                    final monto = (data['monto'] as num?)?.toDouble() ?? 0;
                    final motivo = data['motivo'] as String? ?? 'No especificado';
                    final estado = data['estado'] as String? ?? 'pendiente';
                    final petId = data['petId'] as String?;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text('$petNombre · \$${monto.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Motivo: $motivo'),
                            const SizedBox(height: 4),
                            Text('Estado: ${estado[0].toUpperCase()}${estado.substring(1)}'),
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${createdAt.toLocal()}'.split('.').first,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: petId != null ? () => context.push('/pet/$petId') : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
