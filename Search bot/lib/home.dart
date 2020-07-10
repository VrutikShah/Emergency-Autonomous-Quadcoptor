import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_detection/main.dart';
import 'package:tflite/tflite.dart';

import 'gps.dart';
import 'main.dart';
import 'models.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage(this.cameras);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _model = "";

  @override
  void initState() {
    super.initState();
  }

  loadModel() async {
    String res;
    switch (_model) {
      case yolo:
        res = await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
        );
        break;
      default:
        res = await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt");
    }
    // print(res);
  }

  onSelect(model) {
    setState(() {
      _model = model;
    });
    loadModel();
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ImageRec(_model, cameras)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RaisedButton(
            child: const Text(ssd),
            onPressed: () => onSelect(ssd),
          ),
          RaisedButton(
            child: const Text(yolo),
            onPressed: () => onSelect(yolo),
          ),
          RaisedButton(
              child: const Text("GPS"),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => GetGPScoordi()))),
        ],
      ),
    ));
  }
}
