import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  final GeoPoint currentLocation;

  const MapScreen({Key? key, required this.currentLocation}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  GeoPoint? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
  }

  void _onMapTap(LatLng tappedLocation) {
    setState(() {
      _selectedLocation =
          GeoPoint(tappedLocation.latitude, tappedLocation.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedLocation);
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        onTap: _onMapTap,
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _selectedLocation!.latitude,
            _selectedLocation!.longitude,
          ),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('selectedLocation'),
            position: LatLng(
              _selectedLocation!.latitude,
              _selectedLocation!.longitude,
            ),
          ),
        },
      ),
    );
  }
}
