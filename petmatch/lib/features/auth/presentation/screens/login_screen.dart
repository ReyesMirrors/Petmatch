import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _S();
}

class _S extends State<LoginScreen> {
  final _fk = GlobalKey<FormState>();
  final _ec = TextEditingController();
  final _pc = TextEditingController();
  bool _hide = true;

  @override void dispose() { _ec.dispose(); _pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) => BlocProvider(
    create: (_) => getIt<AuthBloc>(),
    child: BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, s) {
        if (s is AuthAuthenticated) ctx.go(AppRouter.home);
        if (s is AuthVetPending) {
          showDialog(context: ctx, builder: (_) => AlertDialog(
            title: const Text('Solicitud enviada'),
            content: const Text('Tu registro como veterinaria esta en revision. Recibiras una notificacion cuando sea aprobado.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
          ));
        }
        if (s is AuthError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(s.msg), backgroundColor: AppTheme.error));
      },
      builder: (ctx, s) {
        final loading = s is AuthLoading;
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(
            key: _fk,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              Center(child: Column(children: [
                Container(width: 72, height: 72, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.pets, color: Colors.white, size: 40)),
                const SizedBox(height: 12),
                const Text('PetMatch', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const Text('Adopcion responsable', style: TextStyle(color: AppTheme.textSec)),
              ])),
              const SizedBox(height: 40),
              const Text('Iniciar sesion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(controller: _ec, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electronico', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v == null || !v.contains('@')) ? 'Correo invalido' : null),
              const SizedBox(height: 14),
              TextFormField(controller: _pc, obscureText: _hide, decoration: InputDecoration(labelText: 'Contrasena', prefixIcon: const Icon(Icons.lock_outlined), suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _hide = !_hide))), validator: (v) => (v == null || v.length < 8) ? 'Minimo 8 caracteres' : null),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : () { if (_fk.currentState!.validate()) ctx.read<AuthBloc>().add(LoginEmailEvent(_ec.text.trim(), _pc.text)); },
                child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Ingresar'),
              ),
              const SizedBox(height: 14),
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o')), Expanded(child: Divider())]),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: loading ? null : () => ctx.read<AuthBloc>().add(LoginGoogleEvent()),
                icon: const Icon(Icons.g_mobiledata, size: 26),
                label: const Text('Continuar con Google'),
              ),
              const SizedBox(height: 24),
              Center(child: TextButton(
                onPressed: () => ctx.push(AppRouter.register),
                child: const Text.rich(TextSpan(text: 'No tienes cuenta? ', style: TextStyle(color: AppTheme.textSec), children: [TextSpan(text: 'Registrate', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600))])),
              )),
            ]),
          ))),
        );
      },
    ),
  );
}
