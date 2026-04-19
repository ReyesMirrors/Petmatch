import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/adoption_repository.dart';
import '../../domain/entities/entities.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherId;
  const ChatScreen({super.key, required this.chatId, required this.otherId});
  @override State<ChatScreen> createState() => _S();
}

class _S extends State<ChatScreen> {
  final _tc = TextEditingController();
  final _scroll = ScrollController();
  late final String _uid;
  late final AdoptionRepository _repo;

  @override
  void initState() {
    super.initState();
    _uid = getIt<AuthService>().currentUser?.uid ?? '';
    _repo = getIt<AdoptionRepository>();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('Chat privado'), leading: const BackButton()),
    body: Column(children: [
      Expanded(child: StreamBuilder<List<ChatMessage>>(
        stream: _repo.getMessages(widget.chatId),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final msgs = snap.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) { if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent); });
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = msgs[i];
              final isMe = m.senderId == _uid;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                  ),
                  child: Text(m.texto, style: TextStyle(color: isMe ? Colors.white : AppTheme.textPrimary)),
                ),
              );
            },
          );
        },
      )),
      Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
        Expanded(child: TextField(controller: _tc, decoration: const InputDecoration(hintText: 'Escribe un mensaje...', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
        const SizedBox(width: 8),
        FloatingActionButton.small(onPressed: () {
          if (_tc.text.trim().isEmpty) return;
          _repo.sendMessage(chatId: widget.chatId, senderId: _uid, receiverId: widget.otherId, texto: _tc.text.trim());
          _tc.clear();
        }, backgroundColor: AppTheme.primary, child: const Icon(Icons.send, color: Colors.white)),
      ])),
    ]),
  );
}

const textPrimary = AppTheme.textPrimary;
