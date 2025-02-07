// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
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
      // Request permission
      await Permission.location.request();
    }
    // Check if the permission is permanently denied
    if (await Permission.location.isPermanentlyDenied) {
      // Open app settings
      openAppSettings();
    }
  }

  Future<void> _getCurrentLocation() async {
    // Request location permission
    await requestLocationPermission();

    // Get the current position with LocationSettings
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Optional: Set the distance filter
    );

    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
    } catch (e) {
      // Handle the error (e.g., permission denied, location unavailable)
      print("Error getting location: $e");
      setState(() {
        _loading = false; // Stop loading even if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Current Location'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: _currentPosition,
                ),
              },
            ),
    );
  }
}
