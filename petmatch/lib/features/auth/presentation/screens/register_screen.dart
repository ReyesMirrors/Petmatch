import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _S();
}

class _S extends State<RegisterScreen> {
  final _fk = GlobalKey<FormState>();
  final _nc = TextEditingController(); // nombre
  final _ec = TextEditingController(); // email
  final _pc = TextEditingController(); // pass
  final _tc = TextEditingController(); // telefono
  final _cc = TextEditingController(); // ciudad
  final _qc = TextEditingController(); // nequi
  final _vc = TextEditingController(); // nombre vet
  final _lc = TextEditingController(); // direccion local
  bool _isVet = false;
  bool _hide = true;
  File? _cedula;
  File? _certificado;
  final _picker = ImagePicker();

  Future<void> _pickFile(bool isCedula) async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() { if (isCedula) _cedula = File(x.path); else _certificado = File(x.path); });
  }

  @override
  Widget build(BuildContext ctx) => BlocProvider(
    create: (_) => getIt<AuthBloc>(),
    child: BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, s) {
        if (s is AuthAuthenticated) ctx.go(AppRouter.home);
        if (s is AuthVetPending) {
          showDialog(context: ctx, builder: (_) => AlertDialog(
            title: const Text('Solicitud enviada'),
            content: const Text('Revisaremos tus documentos y te notificaremos cuando tu cuenta de veterinaria sea aprobada.'),
            actions: [TextButton(onPressed: () { Navigator.pop(ctx); ctx.go(AppRouter.login); }, child: const Text('OK'))],
          ));
        }
        if (s is AuthError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(s.msg), backgroundColor: AppTheme.error));
      },
      builder: (ctx, s) {
        final loading = s is AuthLoading;
        return Scaffold(
          appBar: AppBar(title: const Text('Crear cuenta')),
          body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _fk, child: Column(children: [
            // Tipo de cuenta
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tipo de cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<bool>(value: false, groupValue: _isVet, onChanged: (v) => setState(() => _isVet = false), title: const Text('Persona normal'), subtitle: const Text('Quiero adoptar o publicar mascotas')),
              RadioListTile<bool>(value: true, groupValue: _isVet, onChanged: (v) => setState(() => _isVet = true), title: Row(children: [const Text('Veterinaria'), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppTheme.vetColor, borderRadius: BorderRadius.circular(12)), child: const Text('Verificacion requerida', style: TextStyle(color: Colors.white, fontSize: 11)))]), subtitle: const Text('Clinica veterinaria o rescatista oficial')),
            ]))),
            const SizedBox(height: 16),
            // Campos comunes
            TextFormField(controller: _nc, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _ec, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electronico', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v == null || !v.contains('@')) ? 'Correo invalido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _pc, obscureText: _hide, decoration: InputDecoration(labelText: 'Contrasena', prefixIcon: const Icon(Icons.lock_outlined), suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _hide = !_hide))), validator: (v) => (v == null || v.length < 8) ? 'Minimo 8 caracteres' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _tc, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined)), validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _cc, decoration: const InputDecoration(labelText: 'Ciudad', prefixIcon: Icon(Icons.location_city_outlined)), validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _qc, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Numero Nequi (para recibir donaciones)', prefixIcon: Icon(Icons.account_balance_wallet_outlined)), validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
            // Campos veterinaria
            if (_isVet) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text('Datos de la veterinaria', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.vetColor)),
              const SizedBox(height: 12),
              TextFormField(controller: _vc, decoration: const InputDecoration(labelText: 'Nombre de la veterinaria', prefixIcon: Icon(Icons.local_hospital_outlined)), validator: (v) => _isVet && (v == null || v.isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _lc, decoration: const InputDecoration(labelText: 'Ubicación del local', prefixIcon: Icon(Icons.place_outlined)), validator: (v) => _isVet && (v == null || v.isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 12),
              _FileButton(label: 'Cedula del responsable', file: _cedula, onTap: () => _pickFile(true)),
              const SizedBox(height: 8),
              _FileButton(label: 'Certificado de la veterinaria', file: _certificado, onTap: () => _pickFile(false)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.vetColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Text('Tu cuenta sera revisada por el administrador. Recibiras una notificacion push cuando sea aprobada.', style: TextStyle(fontSize: 12, color: AppTheme.vetColor))),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : () {
                if (!_fk.currentState!.validate()) return;
                if (_isVet) {
                  if (_cedula == null || _certificado == null) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Debes subir la cedula y el certificado'))); return; }
                  if (_lc.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Debes ingresar la ubicación del local'))); return; }
                  ctx.read<AuthBloc>().add(RegisterVetEvent(_nc.text.trim(), _ec.text.trim(), _pc.text, _tc.text.trim(), _cc.text.trim(), _vc.text.trim(), _qc.text.trim(), _lc.text.trim(), _cedula!, _certificado!));
                } else {
                  ctx.read<AuthBloc>().add(RegisterNormalEvent(_nc.text.trim(), _ec.text.trim(), _pc.text, _tc.text.trim(), _cc.text.trim(), _qc.text.trim()));
                }
              },
              child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isVet ? 'Enviar solicitud' : 'Crear cuenta'),
            ),
          ]))),
        );
      },
    ),
  );
}

class _FileButton extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;
  const _FileButton({required this.label, required this.file, required this.onTap});
  @override
  Widget build(BuildContext ctx) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(file == null ? Icons.upload_file : Icons.check_circle, color: file == null ? null : Colors.green),
    label: Text(file == null ? label : 'Archivo cargado: ${file!.path.split('/').last}', style: TextStyle(color: file == null ? null : Colors.green)),
  );
}
