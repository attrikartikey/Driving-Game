import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import 'navigation/routes.dart';
import 'pointer.dart';
import 'drive.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  LatLng? startLatLng;
  LatLng? destinationLatLng;
  PointerManager? pointerManager;

  static const LatLng _initialPosition = LatLng(37.7749, -122.4194); // Default to San Francisco

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (currentLocation != null) {
      mapController?.animateCamera(CameraUpdate.newLatLng(
        LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLocation();
  }

  void _requestPermissionAndLocation() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }

    if (await Permission.location.isGranted) {
      await _getCurrentLocation();
    } else {
      print("Location permission denied");
    }
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    try {
      currentLocation = await location.getLocation();
      await _initializePointer(); // Initialize pointer with current location

      setState(() {
        if (currentLocation != null && mapController != null) {
          mapController?.animateCamera(CameraUpdate.newLatLng(
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          ));
        }
      });

      location.onLocationChanged.listen((LocationData loc) {
        setState(() {
          currentLocation = loc;
        });
      });
    } catch (e) {
      print("Failed to get location: $e");
    }
  }

  Future<void> _initializePointer() async {
    final icon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(24, 24)), // Reduced size of the pointer
      'assets/images/car.png',
    );

    setState(() {
      pointerManager = PointerManager(
        Pointer(
          position: currentLocation != null
              ? LatLng(currentLocation!.latitude!, currentLocation!.longitude!)
              : _initialPosition, // Initial position at current location
          rotation: 0,
          icon: icon,
        ),
      );
    });
  }

  void _movePointer(double latOffset, double lngOffset, double rotation) {
    setState(() {
      pointerManager?.movePointer(latOffset, lngOffset, rotation);
      // Smoothly update the camera position to follow the pointer
      mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(pointerManager!.pointer.position.latitude, pointerManager!.pointer.position.longitude),
        ),
      );
    });
  }

  void _navigateToRoutesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutesScreen(
          mapController: mapController,
          initialStartLatLng: startLatLng,
          initialDestinationLatLng: destinationLatLng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        startLatLng = result['start'];
        destinationLatLng = result['destination'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Background Dev'),
        actions: [
          IconButton(
            icon: Icon(Icons.directions),
            onPressed: _navigateToRoutesScreen,
          ),
        ],
      ),
      body: currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _initialPosition, // Default to initial position
                      zoom: 18.0,
                    ),
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: pointerManager != null
                        ? {pointerManager!.pointerMarker}
                        : {},
                  ),
                ),
                DriveControls(onMoveButtonPressed: _movePointer),
              ],
            ),
    );
  }
}
