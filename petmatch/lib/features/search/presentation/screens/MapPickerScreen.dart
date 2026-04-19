import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  final Function(double lat, double lng) onSelected;

  const MapPickerScreen({super.key, required this.onSelected});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _pos = const LatLng(4.711, -74.0721);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _pos,
            zoom: 14,
          ),
          markers: {
            Marker(
              markerId: const MarkerId("selected"),
              position: _pos,
              draggable: true,
              onDragEnd: (p) => setState(() => _pos = p),
            )
          },
          onTap: (p) => setState(() => _pos = p),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Toca el mapa para mover el pin. Ubicación seleccionada: ${_pos.latitude.toStringAsFixed(5)}, ${_pos.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: SafeArea(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                widget.onSelected(_pos.latitude, _pos.longitude);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Aceptar ubicación'),
            ),
          ),
        ),
      ],
    );
  }
}