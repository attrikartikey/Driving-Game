import 'dart:convert';
import 'package:http/http.dart' as http;
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
  Set<Polyline> _polylines = {};

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

  Future<void> _getRoutes() async {
    if (startLatLng == null || destinationLatLng == null) {
      return;
    }

    const String DIRECTIONS_API_KEY = "AIzaSyA45rU9Oy-w-d0AzvrAM3w_DCVthjN43vU";
    String baseURL = 'https://maps.googleapis.com/maps/api/directions/json';
    String request = '$baseURL?origin=${startLatLng!.latitude},${startLatLng!
        .longitude}&destination=${destinationLatLng!
        .latitude},${destinationLatLng!
        .longitude}&alternatives=true&key=$DIRECTIONS_API_KEY';
    var response = await http.get(Uri.parse(request));
    var data = json.decode(response.body);
    print('Directions API response data: $data');

    if (data['status'] == 'OK') {
      _polylines.clear();
      for (var route in data['routes']) {
        List<LatLng> polylineCoordinates = [];
        var points = decodePolyline(route['overview_polyline']['points']);
        for (var point in points) {
          polylineCoordinates.add(LatLng(point[0], point[1]));
        }
        _polylines.add(Polyline(
          polylineId: PolylineId(route['summary']),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));
      }
      setState(() {});
    } else {
      print('Error getting directions: ${data['status']}');
    }
  }

  List<List<double>> decodePolyline(String encoded) {
    List<List<double>> polyline = [];
    int index = 0,
        len = encoded.length;
    int lat = 0,
        lng = 0;

    while (index < len) {
      int b,
          shift = 0,
          result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add([(lat / 1E5), (lng / 1E5)]);
    }

    return polyline;
  }

  void _navigateToRoutesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RoutesScreen(
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
        _getRoutes();
      });
    }
  }


  // void _navigateToRoutesScreen() async {
  //   final result = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => RoutesScreen(
  //         mapController: mapController,
  //         initialStartLatLng: startLatLng,
  //         initialDestinationLatLng: destinationLatLng,
  //       ),
  //     ),
  //   );
  //
  //   if (result != null) {
  //     setState(() {
  //       startLatLng = result['start'];
  //       destinationLatLng = result['destination'];
  //       _updateMarkers();
  //     });
  //   }
  // }

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
        polylines: _polylines,
      ),
    );
  }
}
