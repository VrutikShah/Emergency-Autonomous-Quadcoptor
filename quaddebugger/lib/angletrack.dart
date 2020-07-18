import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quaddebugger/3dobj.dart';
import 'package:sensors/sensors.dart';

import 'constants.dart';

class AngleTrack extends StatefulWidget {
  AngleTrack(this.channel, this.connected);
  // Function callback;
  var channel;
  bool connected;
  @override
  _AngleTrackState createState() => _AngleTrackState();
}

class _AngleTrackState extends State<AngleTrack> {
  double angle = 0;
  Timer timer;
  var accelStream;
  bool sending = false;
  void startTimer() {
    const milli = const Duration(milliseconds: 500);

    timer = new Timer.periodic(milli, (Timer timer) {
      // print(widget.connected);
      // print(widget.channel);
      sendMessage('r7;$angle;0;0;', widget.connected, widget.channel);
      // print(angle);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    timer.cancel();
    accelStream.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    accelStream = accelerometerEvents.listen((AccelerometerEvent event) {
      // print(asin(event.x / 9.8) * 180 / 3.14);
      angle = asin(event.x / 9.8) * 180 / pi;
      setState(() {});
    });

    // startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  angleY: (sending == false)?0:-angle,
                  path: 'assets/drone1.obj',
                  size: const Size(300.0, 300.0),
                  zoom: 10,
                ),
              ),
            ),
          ),
          RaisedButton(
            onPressed: () {
              sending = !sending;
              if (!sending) {
                timer.cancel();
                print("STOPPING TIMER");
              } else {
                startTimer();
                print("STARTING TIMER");
              }
            },
            child: Text(((sending == false) ? "Send" : "Stop Sending")),
          ),
        ],
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text("LIVE FOLLOW"),
    //   ),
    //   body: Container(
    //     child: InkWell(
    //       onTap: () {
    //         // widget.callback(angle);
    //       },
    //       child: Column(
    //         children: <Widget>[
    //           AbsorbPointer(
    //             child: Align(
    //               alignment: Alignment.center,
    //               child: Container(
    //                 // color: Colors.black,
    //                 child: Object3D(
    //                   asset: true,
    //                   angleZ: -90,
    //                   angleX: -60,
    //                   angleY: -angle,
    //                   path: 'assets/drone1.obj',
    //                   size: const Size(300.0, 300.0),
    //                   zoom: 10,
    //                 ),
    //               ),
    //             ),
    //           ),
    //           Text("SEND"),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}
