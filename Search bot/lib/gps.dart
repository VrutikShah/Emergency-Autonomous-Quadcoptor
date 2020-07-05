import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

import 'bndbox.dart';
import 'camera.dart';

class ImageRec extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String model;
  ImageRec(this.model, this.cameras);

  @override
  _ImageRecState createState() => new _ImageRecState();
}

class _ImageRecState extends State<ImageRec> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  String consoleOut = "";

  @override
  void initState() {
    super.initState();
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    String _model = widget.model;
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Camera(
            widget.cameras,
            _model,
            setRecognitions,
          ),
          BndBox(
            _recognitions == null ? [] : _recognitions,
            math.max(_imageHeight, _imageWidth),
            math.min(_imageHeight, _imageWidth),
            screen.height,
            screen.width,
            _model,
          ),
        ],
      ),
    );
  }
}

class GetGPScoordi extends StatefulWidget {
  @override
  _GetGPScoordiState createState() => _GetGPScoordiState();
}

class _GetGPScoordiState extends State<GetGPScoordi> {
  String consoleOut = "";
  getlocation() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    consoleOut +=
        "(${_locationData.latitude}, ${_locationData.longitude}, ${_locationData.altitude}, ${_locationData.accuracy})";
    consoleOut += "\n";
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Center(
              child: Container(
                  child: Text(
                "Console Output",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              )),
            ),
            SizedBox(
              height: 15,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    border: Border.all(width: 2.0, color: Colors.purple),
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      consoleOut,
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.left,
                    ),
                  )),
            ),
            Row(
              children: <Widget>[
                RaisedButton(
                  onPressed: () {
                    getlocation();
                    setState(() {});
                  },
                  child: Text("Get GPS"),
                ),
                RaisedButton(
                  onPressed: () {
                    consoleOut = "";
                    setState(() {});
                  },
                  child: Text("Clear console"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
