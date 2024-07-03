import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriveControls extends StatefulWidget {
  final Function(double, double) onMoveButtonPressed;

  DriveControls({required this.onMoveButtonPressed});

  static LatLng vehiclePosition = const LatLng(37.7749, -122.4194);

  static Marker createVehicleMarker(LatLng position) {
    return Marker(
      markerId: MarkerId('vehicle'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  static Marker moveVehicle(LatLng newPosition) {
    vehiclePosition = newPosition;
    return createVehicleMarker(newPosition);
  }

  @override
  _DriveControlsState createState() => _DriveControlsState();
}

class _DriveControlsState extends State<DriveControls> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => widget.onMoveButtonPressed(0.001, 0.0),
          child: Icon(Icons.arrow_upward),
        ),
        ElevatedButton(
          onPressed: () => widget.onMoveButtonPressed(0.0, -0.001),
          child: Icon(Icons.arrow_back),
        ),
        ElevatedButton(
          onPressed: () => widget.onMoveButtonPressed(0.0, 0.001),
          child: Icon(Icons.arrow_forward),
        ),
        ElevatedButton(
          onPressed: () => widget.onMoveButtonPressed(-0.001, 0.0),
          child: Icon(Icons.arrow_downward),
        ),
      ],
    );
  }
}
