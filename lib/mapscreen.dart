// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Using flutter_map
import 'package:latlong2/latlong.dart'; // Specific LatLng for flutter_map
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  // Removed GoogleMapController as we are using flutter_map
  LatLng _currentPosition = LatLng(0, 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Requests location permission from the user.
  // If permission is denied, it attempts to request it.
  // If permanently denied, it opens app settings.
  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      // Request permission
      await Permission.location.request();
    }
    // Check if the permission is permanently denied after requesting
    if (await Permission.location.isPermanentlyDenied) {
      // Open app settings
      openAppSettings();
    }
  }

  // Gets the current location of the device.
  // It first requests permission, then attempts to get the position.
  // Handles errors if location is unavailable or permission is denied.
  Future<void> _getCurrentLocation() async {
    // Request location permission
    await requestLocationPermission();
    var status = await Permission.location.status;

    if (status.isGranted) {
      try {
        // Define location settings for high accuracy and a distance filter
        LocationSettings locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Optional: Set the distance filter
        );

        // Get the current position using Geolocator
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );

        // Update the state with the new position and set loading to false
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _loading = false;
        });
      } catch (e) {
        // Handle errors during location retrieval
        setState(() {
          _loading = false;
        });
        print("Error getting location: $e");
      }
    } else {
      // If permission is not granted, set loading to false and print a message
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
            // Image asset for the app logo
            Image.asset(
              'assets/valknut.png', // Ensure this asset exists in your pubspec.yaml
              height: 60,
            ),
            const SizedBox(width: 60), // Spacing between image and text
            Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center horizontally
              children: const [
                Text('Built by Dmitri'),
                Text('flutify.co.za'),
              ],
            )
          ],
        ),
        centerTitle: true, // Center the title in the app bar
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : FlutterMap(
              options: MapOptions(
                center: _currentPosition, // Set map center to current location
                zoom: 15, // Set initial zoom level
              ),
              nonRotatedChildren: const [], // Required for FlutterMap
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", // OpenStreetMap tile server
                  subdomains: const ['a', 'b', 'c'], // Subdomains for tile loading
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition, // Marker at current location
                      width: 80,
                      height: 80,
                      builder: (ctx) =>
                          const Icon(Icons.location_pin, color: Colors.red), // Custom marker icon
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
