// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  LatLng _currentPosition = LatLng(0, 0);
  bool _loading = true;
  String _address = 'Fetching address...';
  String _localTime = '';
  final List<LatLng> _trackedPositions = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Request notification permission at runtime (Android 13+)
    requestNotificationPermission();

    _getCurrentLocation();

    // Refresh location every 2 minutes
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
      }
    }
  }

  // Offload address fetching to background isolate
  static Future<String> _getAddressFromCoordinates(List<double> coords) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(coords[0], coords[1]);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> parts = [];
        if (place.street?.isNotEmpty ?? false) parts.add(place.street!);
        if (place.locality?.isNotEmpty ?? false) parts.add(place.locality!);
        if (parts.isNotEmpty) return parts.join(', ');
        return 'No address available';
      }
      return 'No address found';
    } catch (e) {
      return 'Failed to get address: $e';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loading = true;
    });

    await requestLocationPermission();
    var status = await Permission.location.status;

    if (!status.isGranted) {
      setState(() {
        _loading = false;
        _address = 'Location permission denied';
        _localTime = '';
      });
      print("Location permission denied");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      LatLng currentPos = LatLng(position.latitude, position.longitude);
      _trackedPositions.add(currentPos);

      // Fetch address off the UI thread
      String addressText = await compute(
        _getAddressFromCoordinates,
        [position.latitude, position.longitude],
      );

      final now = DateTime.now();
      String formattedTime = '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';

      setState(() {
        _currentPosition = currentPos;
        _address = addressText;
        _localTime = formattedTime;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _address = 'Error getting location';
        _localTime = '';
      });
      print("Error getting location: $e");
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
            const SizedBox(width: 60),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text('Built by Dmitri'),
                Text('flutify.co.za'),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    center: _currentPosition,
                    zoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _trackedPositions,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    MarkerLayer(
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
          if (!_loading)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.8 * 255).toInt()),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha((0.5 * 255).toInt()),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Lat: ${_currentPosition.latitude.toStringAsFixed(4)}    '
                  'Lon: ${_currentPosition.longitude.toStringAsFixed(4)}\n'
                  'Address: $_address\n'
                  'Time: $_localTime',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
