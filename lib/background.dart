import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import 'navigation/routes.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LocationData? currentLocation;
  LatLng? startLatLng;
  LatLng? destinationLatLng;
  Set<Marker> _markers = {};

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
    _requestPermission();
  }

  void _requestPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }

    if (await Permission.location.isGranted) {
      _getCurrentLocation();
    } else {
      print("Location permission denied");
    }
  }

  void _getCurrentLocation() async {
    Location location = new Location();
    currentLocation = await location.getLocation();
    setState(() {
      if (currentLocation != null) {
        mapController?.animateCamera(CameraUpdate.newLatLng(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        ));
      }
    });

    location.onLocationChanged.listen((LocationData loc) {
      setState(() {
        currentLocation = loc;
        if (mapController != null) {
          mapController?.animateCamera(CameraUpdate.newLatLng(
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          ));
        }
      });
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
        _updateMarkers();
      });
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      if (startLatLng != null) {
        _markers.add(Marker(
          markerId: MarkerId('start'),
          position: startLatLng!,
          infoWindow: InfoWindow(title: 'Start Location'),
        ));
      }
      if (destinationLatLng != null) {
        _markers.add(Marker(
          markerId: MarkerId('destination'),
          position: destinationLatLng!,
          infoWindow: InfoWindow(title: 'Destination Location'),
        ));
      }
    });
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
          : GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194), // Default to San Francisco
          zoom: 18.0,
        ),
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
      ),
    );
  }
}
