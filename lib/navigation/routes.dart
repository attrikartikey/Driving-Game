import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutesScreen extends StatefulWidget {
  final GoogleMapController? mapController;
  final LatLng? initialStartLatLng;
  final LatLng? initialDestinationLatLng;

  RoutesScreen({this.mapController, this.initialStartLatLng, this.initialDestinationLatLng});

  @override
  _RoutesScreenState createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  TextEditingController startController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  String _sessionToken = '1234567890';
  var uuid = Uuid();
  List<dynamic> _placeList = [];
  bool isStart = true;

  LatLng? startLatLng;
  LatLng? destinationLatLng;

  @override
  void initState() {
    super.initState();
    startLatLng = widget.initialStartLatLng;
    destinationLatLng = widget.initialDestinationLatLng;
    startController.addListener(() {
      _onChanged(true);
    });
    destinationController.addListener(() {
      _onChanged(false);
    });
  }

  _onChanged(bool isStartInput) {
    setState(() {
      isStart = isStartInput;
    });
    if (_sessionToken.isEmpty) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(isStartInput ? startController.text : destinationController.text);
  }

  void getSuggestion(String input) async {
    const String PLACES_API_KEY = "AIzaSyA45rU9Oy-w-d0AzvrAM3w_DCVthjN43vU";
    print("Fetching suggestions for input: $input");

    String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request = '$baseURL?input=$input&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';
    var response = await http.get(Uri.parse(request));
    var data = json.decode(response.body);
    print('Autocomplete response status: ${response.statusCode}');
    print('Autocomplete response data: $data');

    if (response.statusCode == 200) {
      setState(() {
        _placeList = data['predictions'];
      });
    } else {
      print('Failed to load predictions');
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    const String PLACES_API_KEY = "AIzaSyA45rU9Oy-w-d0AzvrAM3w_DCVthjN43vU";
    print("Fetching place details for placeId: $placeId");

    String baseURL = 'https://maps.googleapis.com/maps/api/place/details/json';
    String request = '$baseURL?place_id=$placeId&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';
    var response = await http.get(Uri.parse(request));
    var data = json.decode(response.body);
    print('Place details response status: ${response.statusCode}');
    print('Place details response data: $data');

    if (response.statusCode == 200) {
      var placeDetails = data['result'];
      var lat = placeDetails['geometry']['location']['lat'];
      var lng = placeDetails['geometry']['location']['lng'];
      print('Selected Place: $lat, $lng');
      setState(() {
        if (isStart) {
          startController.text = placeDetails['name'];
          startLatLng = LatLng(lat, lng);
        } else {
          destinationController.text = placeDetails['name'];
          destinationLatLng = LatLng(lat, lng);
        }
        _placeList = [];
      });
    } else {
      print('Failed to load place details');
    }
  }

  void _saveLocations() {
    if (startLatLng != null && destinationLatLng != null) {
      Navigator.pop(context, {
        'start': startLatLng,
        'destination': destinationLatLng,
      });
    } else {
      _showErrorDialog('Error', 'Please select both start and destination locations.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Locations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: startController,
              decoration: InputDecoration(
                hintText: "Search start location",
                prefixIcon: const Icon(Icons.map),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    startController.clear();
                  },
                ),
              ),
            ),
            TextField(
              controller: destinationController,
              decoration: InputDecoration(
                hintText: "Search destination location",
                prefixIcon: const Icon(Icons.map),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    destinationController.clear();
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _placeList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      String placeId = _placeList[index]["place_id"];
                      await _getPlaceDetails(placeId);
                    },
                    child: ListTile(
                      title: Text(_placeList[index]["description"]),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveLocations,
              child: Text('Save Locations'),
            ),
          ],
        ),
      ),
    );
  }
}
