import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/adoption_repository.dart';
import '../../../pets/domain/usecases/pet_usecases.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../auth/domain/auth_repository.dart';

class DonationScreen extends StatefulWidget {
  final String petId;
  const DonationScreen({super.key, required this.petId});
  @override State<DonationScreen> createState() => _S();
}

class _S extends State<DonationScreen> {
  final _mc = TextEditingController();
  final _nc = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;
  Pet? _pet;
  String? _nequiReceptor;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _mc.dispose();
    _nc.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final pet = await getIt<GetPetByIdUseCase>().execute(widget.petId);
    if (pet == null) return;
    final pub = await getIt<AuthRepository>().getUserById(pet.publicadorId);
    setState(() { _pet = pet; _nequiReceptor = pub?.nequiTelefono ?? ''; });
  }

  @override
  Widget build(BuildContext ctx) {
    if (_pet == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _pet!;
    return Scaffold(
      appBar: AppBar(title: const Text('Donar via Nequi')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info mascota
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(p.saludDisplay, style: const TextStyle(color: AppTheme.textSec)),
          if (p.metaDonacion > 0) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: p.porcentaje, color: AppTheme.donColor, backgroundColor: Colors.grey.shade200, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Recaudado: \$\${p.totalRecaudado.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
              Text('Meta: \$\${p.metaDonacion.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppTheme.donColor, fontWeight: FontWeight.bold)),
            ]),
            Text('Falta: \$\${(p.metaDonacion - p.totalRecaudado).clamp(0, double.infinity).toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ]))),
        const SizedBox(height: 20),
        // Como funciona
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.donColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Como funciona la donacion por Nequi', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.donColor)),
          const SizedBox(height: 8),
          _Step('1', 'Ingresa el monto que deseas donar.'),
          _Step('2', 'Copia el numero Nequi del receptor.'),
          _Step('3', 'Abre tu app Nequi y haz la transferencia.'),
          _Step('4', 'Vuelve aqui y registra tu donacion.'),
          _Step('5', 'El publicador confirmara el pago y el total se actualizara.'),
        ])),
        const SizedBox(height: 20),
        // Numero receptor
        if (_nequiReceptor != null && _nequiReceptor!.isNotEmpty) ...[
          const Text('Numero Nequi del receptor', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)), child: Row(children: [
            const Icon(Icons.account_balance_wallet, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(child: Text(_nequiReceptor!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2))),
            IconButton(icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: _nequiReceptor!)); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Numero copiado'))); }),
          ])),
        ],
        const SizedBox(height: 16),
        TextFormField(controller: _mc, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto a donar (COP)', prefixIcon: Icon(Icons.attach_money), prefixText: '\$ ')),
        const SizedBox(height: 12),
        TextFormField(controller: _nc, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Tu numero Nequi (con el que enviaste)', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 12),
        TextFormField(controller: _reasonController, maxLines: 3, decoration: const InputDecoration(labelText: 'Motivo de la donación', prefixIcon: Icon(Icons.edit), hintText: '¿Por qué donas para esta mascota?')),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.donColor),
          onPressed: _loading ? null : () async {
            final monto = double.tryParse(_mc.text.trim());
            if (monto == null || monto <= 0) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresa un monto valido'))); return; }
            if (_nc.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresa tu numero Nequi'))); return; }
            if (_reasonController.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Escribe el motivo de tu donación'))); return; }
            setState(() => _loading = true);
            try {
              final uid = getIt<AuthService>().currentUser?.uid ?? '';
              final user = await getIt<AuthRepository>().getUserById(uid);
              await getIt<AdoptionRepository>().createDonation(
              petId: widget.petId,
              donorId: uid,
              donorNombre: user?.nombre ?? 'Anonimo',
              monto: monto,
              nequiReceptor: _nequiReceptor ?? '',
              nequiDonador: _nc.text.trim(),
              motivo: _reasonController.text.trim(),
            );
              if (mounted) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Donacion registrada. El publicador confirmara el pago pronto.'))); Navigator.pop(ctx); }
            } catch (e) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: \$e'))); }
            finally { if (mounted) setState(() => _loading = false); }
          },
          child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Registrar mi donacion'),
        ),
      ])),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, t;
  const _Step(this.n, this.t);
  @override
  Widget build(BuildContext ctx) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8, top: 1), decoration: const BoxDecoration(color: AppTheme.donColor, shape: BoxShape.circle), child: Center(child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 11)))),
    Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
  ]));
}

extension _PetX on Pet {
  String get saludDisplay {
    switch (estadoSalud) {
      case PetHealthStatus.saludable:
        return 'Saludable';
      case PetHealthStatus.desparasitacion:
        return 'Desparasitación';
      case PetHealthStatus.cuidados_basicos:
        return 'Cuidados básicos';
      case PetHealthStatus.tratamiento:
        return 'En tratamiento';
      case PetHealthStatus.cirugia:
        return 'Necesita cirugía';
    }
  }
}
