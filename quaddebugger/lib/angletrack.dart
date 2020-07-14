import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quaddebugger/3dobj.dart';
import 'package:sensors/sensors.dart';

class AngleTrack extends StatefulWidget {
  AngleTrack(this.callback);
  Function callback;

  @override
  _AngleTrackState createState() => _AngleTrackState();
}

class _AngleTrackState extends State<AngleTrack> {
  double angle = 0;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      // print(asin(event.x / 9.8) * 180 / 3.14);
      angle = asin(event.x / 9.8) * 180 / pi;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.callback(angle);
      },
      child: Column(
        children: <Widget>[
          AbsorbPointer(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                // color: Colors.black,
                child: Object3D(
                  asset: true,
                  angleZ: -90,
                  angleX: -60,
                  angleY: -angle,
                  path: 'assets/drone1.obj',
                  size: const Size(300.0, 300.0),
                  zoom: 10,
                ),
              ),
            ),
          ),
          Text("SEND"),
        ],
      ),
    );
  }
}
