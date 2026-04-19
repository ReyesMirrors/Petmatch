import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/adoption_repository.dart';
import '../../domain/entities/entities.dart';
import '../../../pets/domain/usecases/pet_usecases.dart';

class AdoptionFormScreen extends StatefulWidget {
  final String petId;
  const AdoptionFormScreen({super.key, required this.petId});

  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  final _mc = TextEditingController();
  final _motivo = TextEditingController();
  final _experiencia = TextEditingController();
  final _hogar = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _mc.dispose();
    _motivo.dispose();
    _experiencia.dispose();
    _hogar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Solicitar Adopción'),
      backgroundColor: Theme.of(context).primaryColor,
    ),
    body: Column(
      children: [
        // Header sticky
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cuéntanos sobre ti 🐾',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'El publicador necesita saber por qué eres el candidato ideal para adoptar.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Form scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildField('Motivo de adopción', _motivo, maxLines: 3, maxLength: 200, hint: 'Por qué quieres adoptar a esta mascota'),
                const SizedBox(height: 16),
                _buildField('Experiencia con mascotas', _experiencia, maxLines: 3, maxLength: 300, hint: 'Ej: He tenido perros/gatos antes, voluntario en refugio...'),
                const SizedBox(height: 16),
                _buildField('Tu hogar', _hogar, maxLines: 3, maxLength: 300, hint: 'Ej: Vivo en casa con patio, familia de 3 personas, otros animales...'),
                const SizedBox(height: 16),
                _buildField('Mensaje adicional', _mc, maxLines: 4, maxLength: 500, hint: 'Algo más que quieras contar sobre ti o tu familia...'),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off_outlined, color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'La ubicación del animal solo será compartida una vez que tu solicitud sea aprobada.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Espacio para floating button
              ],
            ),
          ),
        ),
        // Floating Action Button sticky bottom
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _submitForm,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Enviar Solicitud',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildField(String label, TextEditingController controller, {
    required int maxLines,
    required int maxLength,
    required String hint,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    maxLength: maxLength,
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.all(16),
    ),
  );

  Future<void> _submitForm() async {
    final context = this.context;
    if (_motivo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el motivo de adopción')),
      );
      return;
    }
    if (_experiencia.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe tu experiencia con mascotas')),
      );
      return;
    }
    if (_hogar.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe tu hogar')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = getIt<AuthService>().currentUser!.uid;
      final pet = await getIt<GetPetByIdUseCase>().execute(widget.petId);
      if (pet == null) return;

      final has = await getIt<AdoptionRepository>().hasRequest(widget.petId, uid);
      if (has) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya enviaste una solicitud para esta mascota.')),
        );
        return;
      }

      await getIt<AdoptionRepository>().requestAdoption(
        petId: widget.petId,
        petNombre: pet.nombre,
        adoptanteId: uid,
        publicadorId: pet.publicadorId,
        mensaje: _mc.text.trim(),
        motivo: _motivo.text.trim(),
        experiencia: _experiencia.text.trim(),
        hogar: _hogar.text.trim(),
        otrosDetalles: _mc.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Solicitud enviada correctamente! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
        final chatId = chatIdFor(uid, pet.publicadorId, pet.id);
        GoRouter.of(context).push('/chat/$chatId/${pet.publicadorId}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

