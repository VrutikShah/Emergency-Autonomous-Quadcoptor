import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

class AcroModePage extends StatefulWidget {
  AcroModePage({Key key}) : super(key: key);

  @override
  _AcroModePageState createState() => _AcroModePageState();
}

class _AcroModePageState extends State<AcroModePage> {
  List<int> motorValues = [1000, 1000, 1000, 1000];
  List<int> inputValues = [0, 0, 0, 0];
  void updateMotors() {
    motorValues[0] = 1500 +
        inputValues[3] -
        inputValues[1] -
        inputValues[0] -
        inputValues[2];
    motorValues[1] = 1500 +
        inputValues[3] +
        inputValues[1] -
        inputValues[0] +
        inputValues[2];
    motorValues[2] = 1500 +
        inputValues[3] -
        inputValues[1] +
        inputValues[0] +
        inputValues[2];
    motorValues[3] = 1500 +
        inputValues[3] +
        inputValues[1] +
        inputValues[0] -
        inputValues[2];
  }
  void sendData(){
    
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Acro mode")),
      body: SingleChildScrollView(
        child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Center(
                      child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: FlutterSlider(
                              step: 25,
                              axis: Axis.vertical,
                              values: <double>[1000],
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                motorValues[0] = lowerValue.toInt();
                                setState(() {});
                              },
                              min: 1000,
                              max: 2000,

                              // rangeSlider: true,
                            ),
                          ),
                          Text(
                            "M1\n ${motorValues[0]}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: FlutterSlider(
                              step: 25,
                              axis: Axis.vertical,
                              values: <double>[1000],
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                motorValues[1] = lowerValue.toInt();
                                setState(() {});
                              },
                              min: 1000,
                              max: 2000,
                            ),
                          ),
                          Text(
                            "M2\n ${motorValues[1]}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: FlutterSlider(
                              step: 25,
                              axis: Axis.vertical,
                              values: <double>[1000],
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                motorValues[2] = lowerValue.toInt();
                                setState(() {});
                              },
                              min: 1000,
                              max: 2000,
                              // rangeSlider: true,
                            ),
                          ),
                          Text(
                            "M3\n ${motorValues[2]}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: FlutterSlider(
                              step: 25,
                              axis: Axis.vertical,
                              values: <double>[1000],
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                motorValues[3] = lowerValue.toInt();
                                setState(() {});
                              },
                              min: 1000,
                              max: 2000,
                              // rangeSlider: true,
                            ),
                          ),
                          Text(
                            "M4\n ${motorValues[3]}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  )),
                  SizedBox(
                    height: 30,
                  ),
                  Center(
                      child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: FlutterSlider(
                              axis: Axis.vertical,
                              values: <double>[-500],
                              min: -500,
                              max: 500,
                              step: 25,
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                inputValues[3] = lowerValue.toInt();
                                updateMotors();
                                setState(() {});
                              },
                              // centeredOrigin: true,
                            ),
                          ),
                          Text(
                            "Throttle\n ${1500+inputValues[3]}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: FlutterSlider(
                              axis: Axis.vertical,
                              values: <double>[0],
                              min: -500,
                              max: 500, step: 25,
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                inputValues[0] = lowerValue.toInt();
                                updateMotors();
                                setState(() {});
                              },
                              centeredOrigin: true,
                              // rangeSlider: true,
                            ),
                          ),
                          Text(
                            "Roll\n ${1500+inputValues[0]}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: FlutterSlider(
                              axis: Axis.vertical,
                              values: <double>[0],
                              min: -500,
                              max: 500,
                              step: 25,
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                inputValues[1] = lowerValue.toInt();
                                updateMotors();
                                setState(() {});
                              },
                              centeredOrigin: true,
                            ),
                          ),
                          Text(
                            "Pitch\n ${1500+inputValues[1]}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: FlutterSlider(
                              axis: Axis.vertical,
                              values: <double>[0],
                              min: -500,
                              max: 500,
                              step: 25,
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                inputValues[2] = lowerValue.toInt();
                                updateMotors();
                                setState(() {});
                              },
                              centeredOrigin: true,
                            ),
                          ),
                          Text(
                            "Yaw\n ${1500+inputValues[2]}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  )),
                ],
              ),
            )),
      ),
    );
  }
}
