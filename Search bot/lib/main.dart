import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'home.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: AppBar(
          title: Text("COVID-19 Search bot"),
          backgroundColor: Colors.blueAccent,
        ),
        body: HomePage(cameras),
      ),
    );
  }
}
