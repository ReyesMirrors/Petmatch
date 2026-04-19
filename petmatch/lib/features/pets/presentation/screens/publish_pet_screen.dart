import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

import '../../../../core/extensions/enum_extensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../search/presentation/screens/MapPickerScreen.dart';
import '../../domain/entities/pet.dart';
import '../bloc/pets_bloc.dart';

class PublishPetScreen extends StatefulWidget {
  const PublishPetScreen({super.key});

  @override
  State<PublishPetScreen> createState() => _S();
}

class _S extends State<PublishPetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _desc = TextEditingController();
  final _healthDesc = TextEditingController();
  final _moneyGoal = TextEditingController();
  final _city = TextEditingController();

  PetType _type = PetType.perro;
  PetSex _sex = PetSex.macho;
  PetSize _size = PetSize.mediano;
  PetHealthStatus _health = PetHealthStatus.saludable;
  PetSituation _situation = PetSituation.sin_hogar;

  bool _vaccinated = false;
  bool _sterilized = false;

  int _ageMonths = 6;
  List<File> _images = [];

  bool _useLocation = false;
  double? _lat;
  double? _lng;

  final picker = ImagePicker();

  Future<void> pickImages() async {
    final files = await picker.pickMultiImage();

    if (files.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 5 fotos')),
      );
      return;
    }

    setState(() {
      _images = files.map((e) => File(e.path)).toList();
    });
  }

  Future<void> getLocation() async {
    final service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa el servicio de ubicación para usar esta opción.')),
        );
      }
      setState(() => _useLocation = false);
      return;
    }

    var perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permite acceso a ubicación desde la configuración.')),
        );
      }
      setState(() => _useLocation = false);
      return;
    }

    if (perm == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permite el acceso a ubicación para continuar.')),
        );
      }
      setState(() => _useLocation = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
    });
  }

  Widget _situationChip(String label, PetSituation value) {
    return ChoiceChip(
      label: Text(label),
      selected: _situation == value,
      onSelected: (_) => setState(() => _situation = value),
    );
  }

  Widget _healthChip(String label, PetHealthStatus value) {
    return ChoiceChip(
      label: Text(label),
      selected: _health == value,
      onSelected: (_) => setState(() => _health = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PetsBloc>(),
      child: BlocConsumer<PetsBloc, PetsState>(
        listener: (ctx, state) {
          if (state is PetPublished) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Publicada con éxito 🐾')),
            );
            ctx.go(AppRouter.home);
          }

          if (state is PetsError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (ctx, state) {
          final loading = state is PetPublishing;

          return Scaffold(
            appBar: AppBar(title: const Text('Publicar mascota')),

            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: pickImages,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _images.isEmpty
                            ? const Center(child: Text('Agregar hasta 5 fotos'))
                            : ListView(
                                scrollDirection: Axis.horizontal,
                                children: _images
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                              e,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la mascota',
                        prefixIcon: Icon(Icons.pets_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'El nombre es obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _breed,
                      decoration: const InputDecoration(
                        labelText: 'Raza',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'La raza es obligatoria'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'La ciudad es obligatoria'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Describe la mascota'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Tipo de mascota', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PetType.values.map((tipo) {
                        return ChoiceChip(
                          label: Text(tipo.enumName.toUpperCase()),
                          selected: _type == tipo,
                          onSelected: (_) => setState(() => _type = tipo),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Sexo', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PetSex.values.map((sexo) {
                        return ChoiceChip(
                          label: Text(sexo.enumName.toUpperCase()),
                          selected: _sex == sexo,
                          onSelected: (_) => setState(() => _sex = sexo),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tamaño', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PetSize.values.map((tamano) {
                        return ChoiceChip(
                          label: Text(tamano.enumName.toUpperCase()),
                          selected: _size == tamano,
                          onSelected: (_) => setState(() => _size = tamano),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Situación actual', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _situationChip('Con techo', PetSituation.con_dueno),
                        _situationChip('En la calle', PetSituation.sin_hogar),
                        _situationChip('Temporal', PetSituation.temporal),
                        _situationChip('Encontrado', PetSituation.encontrado),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Estado de salud', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _healthChip('Saludable', PetHealthStatus.saludable),
                        _healthChip('Desparasitación', PetHealthStatus.desparasitacion),
                        _healthChip('Cuidados', PetHealthStatus.cuidados_basicos),
                        _healthChip('Tratamiento', PetHealthStatus.tratamiento),
                        _healthChip('Cirugía', PetHealthStatus.cirugia),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _healthDesc,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Detalles de salud',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.health_and_safety_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: _vaccinated,
                            onChanged: (v) => setState(() => _vaccinated = v ?? false),
                            title: const Text('Vacunado'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            value: _sterilized,
                            onChanged: (v) => setState(() => _sterilized = v ?? false),
                            title: const Text('Esterilizado'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Edad', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _ageMonths.toDouble(),
                      min: 0,
                      max: 120,
                      divisions: 120,
                      label: _ageMonths < 12
                          ? '$_ageMonths meses'
                          : '${(_ageMonths / 12).floor()} años',
                      onChanged: (v) => setState(() => _ageMonths = v.round()),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _ageMonths < 12
                            ? '$_ageMonths meses'
                            : '${(_ageMonths / 12).floor()} años ${_ageMonths % 12} meses',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _moneyGoal,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Meta de donación (opcional)',
                        prefixIcon: Icon(Icons.attach_money_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _useLocation,
                      onChanged: (value) async {
                        setState(() => _useLocation = value);
                        if (value) {
                          await getLocation();
                        }
                      },
                      title: const Text('Usar ubicación actual'),
                      subtitle: _lat != null && _lng != null
                          ? Text('Lat: ${_lat!.toStringAsFixed(6)}, Lng: ${_lng!.toStringAsFixed(6)}')
                          : const Text('Activa para añadir coordenadas'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text('Elegir ubicación en el mapa'),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MapPickerScreen(
                                    onSelected: (lat, lng) {
                                      setState(() {
                                        _lat = lat;
                                        _lng = lng;
                                        _useLocation = true;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_lat != null && _lng != null) ...[
                      const SizedBox(height: 8),
                      Text('Ubicación seleccionada: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}'),
                    ],
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () {
                              if (!_formKey.currentState!.validate()) return;

                              final user =
                                  getIt<AuthService>().currentUser;

                              if (user == null) return;

                              final pet = Pet(
                                id: '',
                                nombre: _name.text,
                                tipo: _type,
                                raza: _breed.text,
                                edadMeses: _ageMonths,
                                sexo: _sex,
                                tamano: _size,
                                descripcion: _desc.text,
                                fotos: [],
                                vacunado: _vaccinated,
                                esterilizado: _sterilized,
                                estadoSalud: _health,
                                descripcionSalud: _healthDesc.text,
                                metaDonacion:
                                    double.tryParse(_moneyGoal.text) ?? 0,
                                situacion: _situation,
                                latitud: _lat ?? 4.711,
                                longitud: _lng ?? -74.0721,
                                ciudad: _city.text,
                                publicadorId: user.uid,
                                estado: PetStatus.disponible,
                                createdAt: DateTime.now(),
                              );

ctx.read<PetsBloc>().add(
                                  PublishPetEvent(
                                    pet,
                                    _images.map((e) => e.path).toList(),
                                  ),
                                );
                            },
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text('Publicar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}