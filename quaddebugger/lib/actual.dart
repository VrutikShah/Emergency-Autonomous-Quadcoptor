import 'dart:math';
import 'package:quaddebugger/constants.dart';
import 'package:quaddebugger/joystick.dart';
import 'package:quaddebugger/widgets/arming.dart';
import 'package:quaddebugger/widgets/console.dart';
import 'package:quaddebugger/widgets/graph.dart';
import 'package:quaddebugger/widgets/label.dart';
import 'package:sensors/sensors.dart';
import 'package:flutter/material.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:quaddebugger/3dobj.dart';
import 'package:quaddebugger/acroModePage.dart';
import 'package:quaddebugger/editLabels.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:web_socket_channel/io.dart';
import 'package:connectivity/connectivity.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:syncfusion_flutter_charts/charts.dart';

import 'angletrack.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController pageController = PageController(
    initialPage: 0,
  );
  String currentState = "NETWORK_DISCONNECTED";
  TextEditingController _controller =
      TextEditingController(text: "192.168.4.1:81");

  void getSettings() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    pidGainsText = s.getString('pidGains');
    pids = pidGainsText.split(';');

    trimText = s.getString('trimText');
    print('GETTING FROM MEMORY: ${pids} and ${trimText}');

    if (trimText != null) {
      trims = trimText.split(';');
      trims.remove('r4');
    }

    if (pidGainsText == null) {
      pids = ['0', '0', '0', '0', '0', '0', '0', '0', '0'];
    }
    if (trimText == null) {
      trimText = 'r4;1500;1500;1500;1500;';
      trims = ['1500', '1500', '1500', '1500'];
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    rebuildCallback = () {
      setState(() {});
    };

    getSettings();
    DronePose.x = 0;
    DronePose.y = 0;
    DronePose.z = 0;
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      // Got a new connectivity status!
      try {
        wifiSSID = await (Connectivity().getWifiName());
      } catch (e) {
        print("ERROR");
      }

      print(wifiSSID);
      setState(() {});
    });
    (Connectivity().getWifiName()).then((onValue) {
      wifiSSID = onValue;
      print(wifiSSID);
      setState(() {});
    });
    // connectWebsocket();
  }

  void sendCustomMessage() async {
    String customMsg = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Custom Message"),
          content: Container(
              // height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width * 0.5,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.1,
                child: TextField(
                  onChanged: (value) {
                    customMsg = value;
                  },
                ),
              )),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Send"),
              onPressed: () {
                if (customMsg == '') {
                  Navigator.of(context).pop();
                } else {
                  customMsg =
                      customMsg + '                                          ';
                  customMsg = customMsg.substring(0, 30);
                  sendMessage(customMsg, connected, channel);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    ).then((onValue) {
      setState(() {});
    });
  }

  void sendPIDGains(int type) async {
    String text;
    String requestText;
    if (type == 0) {
      text = 'Kp';
      requestText = 'r3';
    } else if (type == 1) {
      text = 'Ki';
      requestText = 'r5';
    } else {
      text = 'Kd';
      requestText = 'r6';
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Edit PID Gains - $text"),
          content: Container(
              // height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width * 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Roll"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: pids[type * 3]),
                          onChanged: (value) {
                            pids[0 + type * 3] = value;
                          },
                          keyboardType: TextInputType.number,
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Pitch"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration:
                              InputDecoration(hintText: pids[1 + type * 3]),
                          onChanged: (value) {
                            pids[1 + type * 3] = value;
                          },
                          keyboardType: TextInputType.number,
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Yaw"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration:
                              InputDecoration(hintText: pids[2 + type * 3]),
                          onChanged: (value) {
                            pids[2 + type * 3] = value;
                          },
                          keyboardType: TextInputType.number,
                        ),
                      )
                    ],
                  ),
                ],
              )),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Send"),
              onPressed: () {
                pidGainsText = pids.sublist(3 * type, 3 * type + 3).join(';');
                pidGainsText = '$requestText;' +
                    pidGainsText +
                    ';                         ';

                sendMessage(pidGainsText, connected, channel);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((onValue) {
      setState(() {});
      setSettings();
    });
  }

  void sendTrims() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Set Trims"),
          content: Container(
              // height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width * 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Motor 1"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: trims[0]),
                          onChanged: (value) {
                            trims[0] = value;
                          },
                          keyboardType: TextInputType.number,
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Motor 2"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: trims[1]),
                          onChanged: (value) {
                            trims[1] = value;
                          },
                          keyboardType: TextInputType.number,
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Motor 3"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: trims[2]),
                          onChanged: (value) {
                            trims[2] = value;
                          },
                          keyboardType: TextInputType.number,
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Motor 4"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: trims[3]),
                          onChanged: (value) {
                            trims[3] = value;
                          },
                          keyboardType: TextInputType.number,
                        ),
                      )
                    ],
                  ),
                ],
              )),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Send"),
              onPressed: () {
                trimText = trims.join(';');
                print('JOINED: ${trimText}');

                trimText = 'r4;' + trimText + '                          ';

                sendMessage(trimText, connected, channel);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((onValue) {
      setState(() {});
      setSettings();
    });
  }

  void connectWebsocket() {
    print("Connecting...");
    // channel = IOWebSocketChannel.connect('wss://echo.websocket.org');
    channel = IOWebSocketChannel.connect('ws://' + ipAddress);
    sendMessage("text", true, channel);
    channel.stream.listen(
      (message) {
        connected = true;
        consoleOut += message;
        stringList = consoleOut.split('\n');
        stringList = consoleOut.split('\n');
        // joystickKey.currentState.showSnackBar(SnackBar(content: Text(consoleOut),));
        rebuild();
        if (stringList.length >= 20) {
          stringList =
              stringList.reversed.toList().sublist(0, 20).reversed.toList();
        }
        consoleOut = stringList.join('\n');

        if (message[0] == 's') {
          //state function.
          currentState = stateDecoder[message.substring(0, 2)];
          change = !change;

          if (currentState == "DISARMED") {
            armed = false;
          }
          rebuild();
          return;
        } else if (message[0] == 'r') {
          return;
        } else if (message[0] == 'd') {
          if (message[1] == '0') {
            // throttles
            currentState = "ARMED";
            var x = message.split(';');
            // print(x);
            for (int i = 1; i <= 4; i++) {
              if (x[i].length != 4) {
                return;
              }
            }
            motor1.add(GraphData(i, int.parse(x[1])));
            if (motor1.length >= maxLengthGraph) {
              motor1 = motor1.reversed
                  .toList()
                  .sublist(0, maxLengthGraph)
                  .reversed
                  .toList();
            }
            motor2.add(GraphData(i, int.parse(x[2])));
            if (motor2.length >= maxLengthGraph) {
              motor2 = motor2.reversed
                  .toList()
                  .sublist(0, maxLengthGraph)
                  .reversed
                  .toList();
            }

            motor3.add(GraphData(i, int.parse(x[3])));
            if (motor3.length >= maxLengthGraph) {
              motor3 = motor3.reversed
                  .toList()
                  .sublist(0, maxLengthGraph)
                  .reversed
                  .toList();
            }
            motor4.add(GraphData(i, int.parse(x[4])));
            if (motor4.length >= maxLengthGraph) {
              motor4 = motor4.reversed
                  .toList()
                  .sublist(0, maxLengthGraph)
                  .reversed
                  .toList();
            }
            i = i + 1;
            rebuild();
          } else if (message[1] == '1') {
            //SET angles - <d1;x;y;z>
            var poses = message.split(';');

            DronePose.y = double.parse(poses[1]);
            DronePose.x = double.parse(poses[2]);
            DronePose.z = double.parse(poses[3]);

            rebuild();
          }
        }
      },
      onDone: () {
        connected = false;
        armed = false;
        print("Connection ended");
        key.currentState.hideCurrentSnackBar();

        key.currentState.showSnackBar(SnackBar(
          content: Text("Disconnected"),
        ));
        currentState = stateDecoder['s1'];
        rebuild();
      },
      onError: (error) {
        print("Error: $error");
        connected = false;
        armed = false;
        key.currentState.hideCurrentSnackBar();
        key.currentState.showSnackBar(SnackBar(
          content: Text(error),
        ));
        currentState = stateDecoder['s1'];
        rebuild();
      },
    );
  }

  int i = 0;
  void rebuild() {
    labelState = currentState;
    rebuildCallback();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: key,
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.message),
              tooltip: "Edit label maps",
              onPressed: () {
                if (connected == true) {
                  sendCustomMessage();
                } else {
                  key.currentState.showSnackBar(SnackBar(
                    content: Text("Not connected"),
                  ));
                  // }
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.play_arrow),
              tooltip: "AcroMode",
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => AcroModePage()));
              },
            ),
            IconButton(
              icon: Icon(Icons.play_circle_outline),
              tooltip: "Joystick",
              onPressed: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => JoyStick()))
                    .then((c) {
                  rebuildCallback = () {
                    setState(() {});
                  };
                });
              },
            )
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 150.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white.withAlpha(120),
                flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: StateLabel(currentState),
                    background: Column(
                      children: <Widget>[
                        Container(
                          // color: Colors.white,
                          height: 150,
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16.0, 16.0, 16.0, 0),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    height: MediaQuery.of(context).size.height *
                                        0.1,
                                    child: TextField(
                                      controller: _controller,
                                      // keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: "Websocket Address"),
                                      onChanged: (value) {
                                        ipAddress = value;
                                      },
                                    ),
                                  ),
                                ),
                                RaisedButton(
                                  onPressed: () {
                                    connectWebsocket();
                                    // x = !x;
                                  },
                                  child: Text("Connect"),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Icon(
                                  Icons.brightness_1,
                                  color: (connected == true)
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ]),
                        ),
                      ],
                    )),
              ),
            ];
          },
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ArmingWidget(),
                  Text("PID Gains",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  DataTable(columns: [
                    DataColumn(
                        label: Text(
                      "Label",
                      textAlign: TextAlign.center,
                    )),
                    DataColumn(label: Text("Kp", textAlign: TextAlign.center)),
                    DataColumn(label: Text("Ki", textAlign: TextAlign.center)),
                    DataColumn(label: Text("Kd", textAlign: TextAlign.center)),
                  ], rows: [
                    DataRow(cells: [
                      DataCell(Text("Roll", textAlign: TextAlign.center)),
                      DataCell(Text(pids[0].toString(),
                          textAlign: TextAlign.center)),
                      DataCell(Text(pids[3].toString(),
                          textAlign: TextAlign.center)),
                      DataCell(Text(pids[6].toString(),
                          textAlign: TextAlign.center)),
                    ]),
                    DataRow(cells: [
                      DataCell(Text("Pitch", textAlign: TextAlign.center)),
                      DataCell(Text(pids[1].toString(),
                          textAlign: TextAlign.center)),
                      DataCell(Text(pids[4].toString(),
                          textAlign: TextAlign.center)),
                      DataCell(Text(pids[7].toString(),
                          textAlign: TextAlign.center)),
                    ]),
                    DataRow(cells: [
                      DataCell(Text("Yaw", textAlign: TextAlign.center)),
                      DataCell(Text(pids[2].toString(),
                          textAlign: TextAlign.center)),
                      DataCell(Text(pids[5].toString(),
                          textAlign: TextAlign.center)),
                      DataCell(Text(pids[8].toString(),
                          textAlign: TextAlign.center)),
                    ]),
                    DataRow(cells: [
                      DataCell(Text("Send")),
                      DataCell(IconButton(
                          onPressed: () {
                            sendPIDGains(0);
                          },
                          icon: Icon(Icons.brightness_1, color: Colors.black))),
                      DataCell(IconButton(
                          onPressed: () {
                            sendPIDGains(1);
                          },
                          icon: Icon(Icons.brightness_1, color: Colors.black))),
                      DataCell(IconButton(
                          onPressed: () {
                            sendPIDGains(2);
                          },
                          icon: Icon(Icons.brightness_1, color: Colors.black))),
                    ]),
                  ]),
                  ListTile(
                    subtitle: Text(
                      "Send Trims",
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      if (connected == true) {
                        sendTrims();
                      } else {
                        key.currentState.showSnackBar(SnackBar(
                          content: Text("Not connected"),
                        ));
                      }
                    },
                    title: Container(
                        child: Text(
                      "Motor Trims: " + trimText.trim().substring(3),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    )),
                  ),
                  // Divider(),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 450,
                    child: PageView(controller: pageController, children: [
                      Column(
                        children: <Widget>[
                          Center(
                            child: Container(
                                child: Text(
                              "Motor Outputs",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            )),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          GraphWidget(),
                        ],
                      ),
                      Consolewidget(),
                      Column(
                        children: <Widget>[
                          Text(
                            "Drone Orientation",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          AbsorbPointer(
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                // color: Colors.black,
                                child: Object3D(
                                  asset: true,
                                  angleZ: -60 - DronePose.z,
                                  angleX: -60 + DronePose.x,
                                  angleY: DronePose.y,
                                  path: 'assets/drone1.obj',
                                  size: const Size(300.0, 300.0),
                                  zoom: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
