// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  LatLng _currentPosition = LatLng(0, 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      await Permission.location.request();
    }
    if (await Permission.location.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _getCurrentLocation() async {
    await requestLocationPermission();
    var status = await Permission.location.status;

    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _loading = false;
        });
      } catch (e) {
        setState(() {
          _loading = false;
        });
        print("Error getting location: $e");
      }
    } else {
      setState(() {
        _loading = false;
      });
      print("Location permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color.fromARGB(255, 208, 226, 230),
        title: Row(
          children: [
            Image.asset(
              'assets/valknut.png',
              height: 60,
            ),
            SizedBox(width: 60),
            Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center horizontally
              children: [
                Text('Built by Dmitri'),
                Text('flutify.co.za'),
              ],
            )
          ],
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: _currentPosition,
                zoom: 15,
              ),
              nonRotatedChildren: const [], // Add this line
              children: [
                TileLayer(
                  // Changed from TileLayerOptions
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  // Changed from MarkerLayerOptions
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 80,
                      height: 80,
                      builder: (ctx) =>
                          const Icon(Icons.location_pin, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
