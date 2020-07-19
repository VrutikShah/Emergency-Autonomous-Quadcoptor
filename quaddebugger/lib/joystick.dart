import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quaddebugger/3dobj.dart';
import 'package:quaddebugger/constants.dart';
import 'package:quaddebugger/joypad.dart';
import 'package:quaddebugger/widgets/arming.dart';
import 'package:quaddebugger/widgets/graph.dart';
import 'package:quaddebugger/widgets/label.dart';

class JoyStick extends StatefulWidget {
  JoyStick({Key key}) : super(key: key);

  @override
  _JoyStickState createState() => _JoyStickState();
}

class _JoyStickState extends State<JoyStick> {
  @override
  void initState() {
    super.initState();
    rebuildCallback = () {
      setState(() {});
    };
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  dispose() {
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.bottom, SystemUiOverlay.top]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

//roll pitch yaw throttle
  List<double> setpoints = [0, 0, 0, 0];
  List<double> prevSetpoints = [30, 0, 0, 0];
  void sendSetpoints() {
    double delta = 0;
    
    for (int i = 0; i < 4; i++) {
      delta += (setpoints[i] - prevSetpoints[i])*(setpoints[i] - prevSetpoints[i]);
    }
    delta = sqrt(delta);
    if(setpoints == [0,0,0,0]){
      print("END");
      delta = 100;
    }
    if (delta < 8) {
      return;
    }
    // print(setpoints);
    sendMessage('t7;${setpoints[0]};${setpoints[1]};${setpoints[2]};',
        connected, channel);
    for (int i = 0; i < 4; i++) {
      prevSetpoints[i] = setpoints[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
            title: StateLabel(labelState),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(context);
                })),
      ),
      body: Container(
        // color: Colors.grey,
        child: Center(
          child: Stack(
            children: <Widget>[
              Positioned(right: 0, top: 100, child: GraphWidget()),
              Positioned(
                left: MediaQuery.of(context).size.height / 2 + 60,
                top: 30 + -setpoints[3] * 3.5,
                child: AbsorbPointer(
                  absorbing: false,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      // color: Colors.black,
                      child: Object3D(
                        asset: true,
                        angleZ: -90 + setpoints[2].toDouble(),
                        angleX: -60 - setpoints[1].toDouble(),
                        angleY: setpoints[0].toDouble(),
                        path: 'assets/drone1.obj',
                        size: const Size(300.0, 300.0),
                        zoom: 10,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  // color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Joypad(
                          returnToCentre: false,
                          color: Colors.blue,
                          onEnd: (data) {},
                          onUpdate: (data) {
                            setpoints[2] = (-data.dx * 0.3).round().toDouble();
                            setpoints[3] = (data.dy * 0.2).round().toDouble();
                            setState(() {});
                            sendSetpoints();
                          }),
                      Column(
                        children: <Widget>[
                          Container(
                              // height: 100,
                              width: 200,
                              decoration: new BoxDecoration(
                                  color: Colors.white.withAlpha(200),
                                  borderRadius: new BorderRadius.all(
                                      const Radius.circular(40.0))),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text("Roll: ${setpoints[0]}"),
                                    Text("Pitch: ${setpoints[1]}"),
                                    Text("Yaw: ${setpoints[2]}"),
                                    Text(
                                        "Throttle: ${setpoints[3] * 25 + 1500}"),
                                  ],
                                )),
                              )),
                          SizedBox(
                            height: 20,
                          ),
                          ArmingWidget(),
                          (connected == true)
                              ? Text("Connected")
                              : Text("Disconnected")
                        ],
                      ),
                      Joypad(
                          returnToCentre: true,
                          color: Colors.red,
                          onEnd: (data) {
                            setpoints[0] = (data.dx * 0.3).round().toDouble();
                            setpoints[1] = (data.dy * 0.3).round().toDouble();
                            sendSetpoints();
                            setState(() {});
                          },
                          onUpdate: (data) {
                            setpoints[0] = (data.dx * 0.3).round().toDouble();
                            setpoints[1] = (data.dy * 0.3).round().toDouble();
                            sendSetpoints();
                            setState(() {});
                          }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
