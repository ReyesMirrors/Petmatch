import 'package:flutter/material.dart';

import '../../../../core/extensions/enum_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../domain/adoption_repository.dart';
import '../../domain/entities/entities.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});
  @override State<RequestsScreen> createState() => _S();
}

class _S extends State<RequestsScreen> {
  int _tab = 0;
  late final String _uid;
  late final AdoptionRepository _repo;

  @override
  void initState() {
    super.initState();
    _uid = getIt<AuthService>().currentUser?.uid ?? '';
    _repo = getIt<AdoptionRepository>();
  }

  @override
  Widget build(BuildContext ctx) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const SizedBox(height: 8),
        const Text('Solicitudes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const TabBar(tabs: [Tab(text: 'Recibidas'), Tab(text: 'Enviadas')]),
        Expanded(
          child: TabBarView(children: [
            _ReqList(
              key: const ValueKey('requests-recibidas'),
              stream: _repo.getRequestsPublicador(_uid),
              isPublicador: true,
              repo: _repo,
            ),
            _ReqList(
              key: const ValueKey('requests-enviadas'),
              stream: _repo.getRequestsAdoptante(_uid),
              isPublicador: false,
              repo: _repo,
            ),
          ]),
        ),
      ],
    ),
  );
}

class _ReqList extends StatefulWidget {
  final Stream<List<AdoptionRequest>> stream;
  final bool isPublicador;
  final AdoptionRepository repo;
  const _ReqList({super.key, required this.stream, required this.isPublicador, required this.repo});

  @override
  State<_ReqList> createState() => _ReqListState();
}

class _ReqListState extends State<_ReqList> with AutomaticKeepAliveClientMixin {
  List<AdoptionRequest>? _cachedRequests;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx);
    return StreamBuilder<List<AdoptionRequest>>(
      stream: widget.stream,
      builder: (ctx, snap) {
        if (snap.hasData && snap.data!.isNotEmpty) {
          _cachedRequests = snap.data;
        }
        if (snap.connectionState == ConnectionState.waiting && _cachedRequests != null) {
          return _buildList(_cachedRequests!);
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Center(child: Text('Sin solicitudes'));
        }
        return _buildList(snap.data!);
      },
    );
  }

  Widget _buildList(List<AdoptionRequest> requests) {
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (_, i) {
        final r = requests[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(r.petNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.motivo.isNotEmpty ? r.motivo : r.mensaje, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Hogar: ${r.hogar}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                Text('Experiencia: ${r.experiencia}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ],
            ),
            isThreeLine: true,
            trailing: _StatusChip(r.estado),
            onTap: () => _showRequestDetails(context, r),
            onLongPress: widget.isPublicador && r.estado == AdoptionStatus.pendiente ? () => _showActions(context, r) : null,
          ),
        );
      },
    );
  }

  void _showActions(BuildContext ctx, AdoptionRequest r) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: Colors.green),
            title: const Text('Aprobar'),
            onTap: () {
              Navigator.pop(ctx);
              _showStatusCommentDialog(context, r, AdoptionStatus.aprobada);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel_outlined, color: Colors.red),
            title: const Text('Rechazar'),
            onTap: () {
              Navigator.pop(ctx);
              _showStatusCommentDialog(context, r, AdoptionStatus.rechazada);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusCommentDialog(BuildContext ctx, AdoptionRequest r, AdoptionStatus status) async {
    final controller = TextEditingController();
    final action = status == AdoptionStatus.aprobada ? 'aprobar' : 'rechazar';
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Confirmar $action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Puedes dejar un comentario opcional al ${action} la solicitud.'),
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
          ElevatedButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repo.updateAdoptionStatus(
        r.id,
        status,
        comentarioRespuesta: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
    }
  }

  void _showRequestDetails(BuildContext ctx, AdoptionRequest r) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(r.petNombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _detailRow('Estado', r.estadoDisplay),
            const SizedBox(height: 12),
            _detailRow('Motivo', r.motivo.isNotEmpty ? r.motivo : 'No especificado'),
            const SizedBox(height: 12),
            _detailRow('Hogar', r.hogar.isNotEmpty ? r.hogar : 'No especificado'),
            const SizedBox(height: 12),
            _detailRow('Experiencia', r.experiencia.isNotEmpty ? r.experiencia : 'No especificado'),
            const SizedBox(height: 12),
            _detailRow('Mensaje', r.mensaje.isNotEmpty ? r.mensaje : 'Sin mensaje adicional'),
            if (r.comentarioRespuesta.isNotEmpty) ...[
              const SizedBox(height: 12),
              _detailRow('Comentario de respuesta', r.comentarioRespuesta),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final chatId = chatIdFor(r.adoptanteId, r.publicadorId, r.petId);
                      final otherId = widget.isPublicador ? r.adoptanteId : r.publicadorId;
                      Navigator.pop(ctx);
                      context.push('/chat/$chatId/$otherId');
                    },
                    icon: const Icon(Icons.chat_bubble),
                    label: const Text('Abrir chat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.isPublicador && r.estado == AdoptionStatus.pendiente) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showStatusCommentDialog(context, r, AdoptionStatus.rechazada);
                      },
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showStatusCommentDialog(context, r, AdoptionStatus.aprobada);
                      },
                      child: const Text('Aprobar'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AdoptionStatus s;
  const _StatusChip(this.s);
  @override
  Widget build(BuildContext ctx) {
    Color c; switch(s) {
      case AdoptionStatus.pendiente: c = Colors.orange; break;
      case AdoptionStatus.en_revision: c = Colors.blue; break;
      case AdoptionStatus.aprobada: c = Colors.green; break;
      case AdoptionStatus.rechazada: c = Colors.red; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c)), child: Text(s.enumName, style: TextStyle(color: c, fontSize: 11)));
  }
}
