import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/extensions/enum_extensions.dart';
import '../../../pets/data/models/pet_model.dart';
import '../../../pets/domain/entities/pet.dart';

class PetsMapScreen extends StatefulWidget {
  const PetsMapScreen({super.key});

  @override
  State<PetsMapScreen> createState() => _PetsMapScreenState();
}

class _PetsMapScreenState extends State<PetsMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final Map<String, BitmapDescriptor> _markerIcons = {};
  final Set<String> _loadingMarkerIds = {};
  LatLng? _userLocation;
  late final String _heroMessage;

  static const _initialPosition = CameraPosition(
    target: LatLng(4.711, -74.0721),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    final heroMessages = [
      '¿Quieres conocernos y darle un hogar a un amigo peludo?',
      '¿Listo para encontrar tu próxima mascota favorita?',
      '¿Buscas compañía con patas y mucho cariño?',
      '¿Qué tal adoptar amor en lugar de comprar?',
      '¿Te gustaría tocar un marcador y descubrir una historia?',
    ];
    _heroMessage = heroMessages[Random().nextInt(heroMessages.length)];
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _userLocation = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {});
        _goToLocation(_userLocation!);
      }
    } catch (_) {
      // ignore location errors, map seguirá funcionando en Bogotá.
    }
  }

  Future<void> _goToLocation(LatLng position) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
  }

  Set<Marker> _buildMarkers(List<PetModel> pets) {
    for (final pet in pets) {
      if (pet.fotos.isNotEmpty &&
          !_markerIcons.containsKey(pet.id) &&
          !_loadingMarkerIds.contains(pet.id)) {
        _loadMarkerIcon(pet);
      }
    }

    return pets.map((pet) {
      final currentPet = pet;
      return Marker(
        markerId: MarkerId(currentPet.id),
        position: LatLng(currentPet.latitud, currentPet.longitud),
        icon: _markerIconForPet(currentPet),
        anchor: const Offset(0.5, 0.5),
        zIndex: _markerIcons.containsKey(currentPet.id) ? 1 : 0,
        infoWindow: InfoWindow(
          title: currentPet.nombre,
          snippet: '${currentPet.ciudad} • ${currentPet.tipo.enumName}',
          onTap: () => _openPetDetails(currentPet),
        ),
        onTap: () => _showPetBottomSheet(currentPet),
      );
    }).toSet();
  }

  BitmapDescriptor _markerIconForPet(PetModel pet) {
    if (_markerIcons.containsKey(pet.id)) {
      return _markerIcons[pet.id]!;
    }

    final type = pet.tipo;
    if (type == PetType.perro) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    if (type == PetType.gato) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  Future<void> _loadMarkerIcon(PetModel pet) async {
    if (pet.fotos.isEmpty || _markerIcons.containsKey(pet.id)) return;
    _loadingMarkerIds.add(pet.id);

    try {
      final bitmap = await _createMarkerFromImage(pet.fotos.first);
      if (mounted) {
        setState(() {
          _markerIcons[pet.id] = bitmap;
        });
      }
    } catch (_) {
      // Fall back to default marker if photo load falla.
    } finally {
      _loadingMarkerIds.remove(pet.id);
    }
  }

  Future<BitmapDescriptor> _createMarkerFromImage(String imageUrl) async {
    final completer = Completer<ImageInfo>();
    final provider = CachedNetworkImageProvider(imageUrl);
    final stream =
        provider.resolve(const ImageConfiguration(size: Size(120, 120)));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(info);
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        completer.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    final imageInfo = await completer.future;
    final image = imageInfo.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(56, 56);
    final rect = Offset.zero & size;
    final paint = Paint()..color = Colors.transparent;
    canvas.drawRect(rect, paint);

    final center = const Offset(28, 28);
    canvas.drawCircle(center, 28, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final circleRect = Rect.fromCircle(center: center, radius: 24);
    canvas.save();
    canvas.clipPath(Path()..addOval(circleRect));
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, src, circleRect, Paint());
    canvas.restore();

    final picture = recorder.endRecording();
    final uiImage =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  void _openPetDetails(PetModel pet) {
    GoRouter.of(context).push('/pet/${pet.id}');
  }

  void _showPetBottomSheet(PetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (pet.fotos.isNotEmpty) ...[
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: CachedNetworkImageProvider(pet.fotos.first),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.nombre,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pet.tipo.enumName.toUpperCase(),
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text('Ubicación: ${pet.ciudad}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Publicación: ${pet.estadoPublicacionDisplay}'),
                        const SizedBox(height: 6),
                        Text('Salud: ${pet.estadoSalud.enumName}'),
                        const SizedBox(height: 6),
                        Text('Situación: ${pet.situacion.enumName}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (pet.descripcion.isNotEmpty) ...[
                    Text(
                      pet.descripcion,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openPetDetails(pet);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Ver detalles'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pets')
          .where('estado', isEqualTo: 'disponible')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error cargando mascotas: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No se encontraron mascotas'));
        }

        final pets = snapshot.data!.docs
            .map((doc) => PetModel.fromFirestore(doc))
            .toList();
        final markers = _buildMarkers(pets);

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _userLocation != null
                  ? CameraPosition(target: _userLocation!, zoom: 14)
                  : _initialPosition,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                if (_userLocation != null) {
                  controller.moveCamera(
                      CameraUpdate.newLatLngZoom(_userLocation!, 14));
                }
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _heroMessage,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Toca un marcador para ver la mascota. El mapa se centra en tu ubicación cuando está disponible.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        if (_userLocation != null) {
                          _goToLocation(_userLocation!);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.my_location,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
