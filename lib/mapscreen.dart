// ignore_for_file: avoid_print

import 'dart:async';

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
    _getCurrentLocation();

    // Set up periodic timer to refresh location every 2 minutes
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) {
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loading = true; // Show loading indicator when refreshing
    });

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

        _currentPosition = LatLng(position.latitude, position.longitude);

        // Add current position to the tracked positions list
        _trackedPositions.add(_currentPosition);

        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          String addressText;
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            List<String> addressParts = [];
            if (place.street?.isNotEmpty ?? false) {
              addressParts.add(place.street!);
            }
            if (place.locality?.isNotEmpty ?? false) {
              addressParts.add(place.locality!);
            }

            addressText = addressParts.isNotEmpty
                ? addressParts.join(', ')
                : 'No address available';
          } else {
            addressText = 'No address found';
          }

          final now = DateTime.now();
          String formattedTime = '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}:'
              '${now.second.toString().padLeft(2, '0')}';

          setState(() {
            _address = addressText;
            _localTime = formattedTime;
            _loading = false;
          });
        } catch (e) {
          setState(() {
            _address = 'Failed to get address: $e';
            _localTime = '';
            _loading = false;
          });
          print("Error getting address: $e");
        }
      } catch (e) {
        setState(() {
          _loading = false;
          _address = 'Error getting location';
          _localTime = '';
        });
        print("Error getting location: $e");
      }
    } else {
      setState(() {
        _loading = false;
        _address = 'Location permission denied';
        _localTime = '';
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
            const SizedBox(width: 60),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text('Built by Dmitri'),
                Text('flutify.co.za'),
              ],
            )
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation, // Call the refresh function
            tooltip: 'Refresh Location', // Optional: shows on long press
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
                color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                   color: Colors.grey.withValues(alpha: 0.5),
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
