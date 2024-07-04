import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoutesScreen extends StatefulWidget {
  final GoogleMapController? mapController;

  RoutesScreen({this.mapController});

  @override
  _RoutesScreenState createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  TextEditingController startController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  final Mode _mode = Mode.overlay;
  LatLng? startLatLng;
  LatLng? destinationLatLng;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylines = {};

  Future<void> _handlePressButton(TextEditingController controller, bool isStart) async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: 'AIzaSyDvaT-prA0fqz5bMehCJD1K2p3xPZvXbNI',
      mode: _mode,
      language: 'en',
      components: [Component(Component.country, "in")],
    );

    await _displayPrediction(p, controller, isStart);
  }

  Future<void> _displayPrediction(Prediction? p, TextEditingController controller, bool isStart) async {
    if (p != null) {
      GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: 'AIzaSyDvaT-prA0fqz5bMehCJD1K2p3xPZvXbNI');
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId!);
      final lat = detail.result.geometry?.location.lat;
      final lng = detail.result.geometry?.location.lng;

      if (lat != null && lng != null) {
        setState(() {
          controller.text = p.description!;
          if (isStart) {
            startLatLng = LatLng(lat, lng);
          } else {
            destinationLatLng = LatLng(lat, lng);
          }
        });

        widget.mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          18.0,
        ));
      }
    }
  }

  void _getDirections() async {
    if (startLatLng == null || destinationLatLng == null) {
      return;
    }

    String start = '${startLatLng!.latitude},${startLatLng!.longitude}';
    String destination = '${destinationLatLng!.latitude},${destinationLatLng!.longitude}';
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$start&destination=$destination&key=YOUR_GOOGLE_MAPS_API_KEY';

    var response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      var steps = data['routes'][0]['legs'][0]['steps'];

      polylineCoordinates.clear();
      steps.forEach((step) {
        polylineCoordinates.add(LatLng(step['start_location']['lat'], step['start_location']['lng']));
        polylineCoordinates.add(LatLng(step['end_location']['lat'], step['end_location']['lng']));
      });

      setState(() {
        polylines = {
          Polyline(
            polylineId: PolylineId('route1'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        };
      });

      widget.mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(polylineCoordinates.map((e) => e.latitude).reduce((a, b) => a < b ? a : b),
                polylineCoordinates.map((e) => e.longitude).reduce((a, b) => a < b ? a : b)),
            northeast: LatLng(polylineCoordinates.map((e) => e.latitude).reduce((a, b) => a > b ? a : b),
                polylineCoordinates.map((e) => e.longitude).reduce((a, b) => a > b ? a : b)),
          ),
          50,
        ),
      );
    } else {
      print('Error getting directions: ${data['status']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Get Directions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    readOnly: true,
                    onTap: () => _handlePressButton(startController, true),
                    decoration: InputDecoration(
                      hintText: 'Start Location',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _handlePressButton(startController, true),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: destinationController,
                    readOnly: true,
                    onTap: () => _handlePressButton(destinationController, false),
                    decoration: InputDecoration(
                      hintText: 'Destination',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _handlePressButton(destinationController, false),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _getDirections,
              child: Text('Get Directions'),
            ),
          ],
        ),
      ),
    );
  }
}
