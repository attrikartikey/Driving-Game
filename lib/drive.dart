import 'package:flutter/material.dart';
import 'dart:math';

class DriveControls extends StatefulWidget {
  final Function(double, double, double) onMoveButtonPressed;

  DriveControls({required this.onMoveButtonPressed});

  @override
  _DriveControlsState createState() => _DriveControlsState();
}

class _DriveControlsState extends State<DriveControls> {
  Set<String> pressedButtons = {};
  late Function(double, double, double) _onMoveButtonPressed;
  double currentRotation = 0;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _onMoveButtonPressed = widget.onMoveButtonPressed;
  }

  void _startMoving() {
    if (_isMoving) return;

    _isMoving = true;
    _moveContinuously();
  }

  void _moveContinuously() {
    if (!_isMoving) return;

    double latOffset = 0;
    double lngOffset = 0;
    double rotation = currentRotation;

    if (pressedButtons.contains('left')) {
      rotation = (currentRotation - 2) % 360;
    }
    if (pressedButtons.contains('right')) {
      rotation = (currentRotation + 2) % 360;
    }

    currentRotation = rotation;

    if (pressedButtons.contains('up')) {
      final double rad = currentRotation * (pi / 180.0);
      latOffset += 0.000005 * cos(rad);
      lngOffset += 0.000005 * sin(rad);
    }
    if (pressedButtons.contains('down')) {
      final double rad = currentRotation * (pi / 180.0);
      latOffset -= 0.000005 * cos(rad);
      lngOffset -= 0.000005 * sin(rad);
    }

    _onMoveButtonPressed(latOffset, lngOffset, rotation);

    Future.delayed(Duration(milliseconds: 50), _moveContinuously); // Increase update frequency
  }

  void _onButtonPress(String direction) {
    setState(() {
      pressedButtons.add(direction);
      _startMoving();
    });
  }

  void _onButtonRelease(String direction) {
    setState(() {
      pressedButtons.remove(direction);
      if (pressedButtons.isEmpty) {
        _isMoving = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTapDown: (_) => _onButtonPress('up'),
          onTapUp: (_) => _onButtonRelease('up'),
          child: ElevatedButton(
            onPressed: null,
            child: Icon(Icons.arrow_upward),
          ),
        ),
        GestureDetector(
          onTapDown: (_) => _onButtonPress('left'),
          onTapUp: (_) => _onButtonRelease('left'),
          child: ElevatedButton(
            onPressed: null,
            child: Icon(Icons.arrow_back),
          ),
        ),
        GestureDetector(
          onTapDown: (_) => _onButtonPress('right'),
          onTapUp: (_) => _onButtonRelease('right'),
          child: ElevatedButton(
            onPressed: null,
            child: Icon(Icons.arrow_forward),
          ),
        ),
        GestureDetector(
          onTapDown: (_) => _onButtonPress('down'),
          onTapUp: (_) => _onButtonRelease('down'),
          child: ElevatedButton(
            onPressed: null,
            child: Icon(Icons.arrow_downward),
          ),
        ),
      ],
    );
  }
}
