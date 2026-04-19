import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/extensions/enum_extensions.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/domain/pet_repository.dart';
import '../../../pets/presentation/bloc/pets_bloc.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _sc = TextEditingController();

  PetType? _tipo;
  PetSex? _sexo;
  PetSize? _tamano;
  PetHealthStatus? _salud;
  PetSituation? _sit;

  void _apply() {
    setState(() {});
  }

  bool _matchesFilter(Pet p) {
    if (_tipo != null && p.tipo != _tipo) return false;
    if (_sexo != null && p.sexo != _sexo) return false;
    if (_tamano != null && p.tamano != _tamano) return false;
    if (_salud != null && p.estadoSalud != _salud) return false;
    if (_sit != null && p.situacion != _sit) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<PetsBloc>()..add(LoadPetsEvent()),
      child: Builder(
        builder: (ctx) {
          final bloc = ctx.read<PetsBloc>();

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.pets, color: Colors.teal),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Encuentra tu compañero peludo',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sc,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Buscar por nombre o ciudad',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Tipo: ',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          ...PetType.values.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(t.enumName),
                                selected: _tipo == t,
                                selectedColor: Colors.teal.shade100,
                                showCheckmark: false,
                                onSelected: (v) {
                                  setState(() => _tipo = v ? t : null);
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Situación: ',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          _chip('Todos', _sit == null, () {
                            setState(() => _sit = null);
                          }),
                          _chip('Sin hogar',
                              _sit == PetSituation.sin_hogar, () {
                            setState(
                                () => _sit = PetSituation.sin_hogar);
                          }),
                          _chip('Encontrado',
                              _sit == PetSituation.encontrado, () {
                            setState(
                                () => _sit = PetSituation.encontrado);
                          }),
                          _chip('Temporal',
                              _sit == PetSituation.temporal, () {
                            setState(
                                () => _sit = PetSituation.temporal);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<PetsBloc, PetsState>(
                  builder: (ctx, state) {
                    if (state is PetsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is PetsEmpty) {
                      return const Center(child: Text('Sin resultados'));
                    }

                    if (state is PetsLoaded) {
                      final pets = [...state.pets]
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      final filteredBySearch = pets.where((p) {
                        final q = _sc.text.toLowerCase();
                        if (q.isEmpty) return true;
                        return p.nombre.toLowerCase().contains(q) ||
                            p.ciudad.toLowerCase().contains(q);
                      }).toList();
                      final visible = filteredBySearch.where(_matchesFilter).toList();

                      if (visible.isEmpty) {
                        return const Center(child: Text('Sin resultados'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: visible.length,
                        itemBuilder: (_, i) {
                          final p = visible[i];

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: p.fotos.isEmpty
                                  ? const Icon(Icons.pets, size: 40)
                                  : CachedNetworkImage(
                                      imageUrl: p.fotos.first,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            title: Text(
                              p.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p.tipo.enumName} • ${p.ciudad}'),
                                const SizedBox(height: 4),
                                Text('Estado: ${p.estadoPublicacionDisplay}'),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => ctx.push('/pet/${p.id}'),
                          );
                        },
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}