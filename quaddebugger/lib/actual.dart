import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:quaddebugger/acroModePage.dart';
import 'package:quaddebugger/editLabels.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:web_socket_channel/io.dart';
import 'package:connectivity/connectivity.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:syncfusion_flutter_charts/charts.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String ipAddress = "192.168.4.1:81";
  var channel;
  String consoleOut = "";
  List<String> stringList;
  TextEditingController _controller =
      TextEditingController(text: "192.168.4.1:81");
  int i = 0;
  String currentState = "NETWORK_DISCONNECTED";
  List<GraphData> throttles = [];
  List<GraphData> pitch = [];
  List<GraphData> roll = [];
  List<GraphData> yaw = [];
  bool change = false;
  String wifiSSID;
  int maxLengthGraph = 60;
  bool connected = false;
  var subscription;
  bool armed = false;

  bool x = false;

  List<String> pids = ['0', '0', '0', '0', '0', '0'];
  String pidGainsText = 'r3;0;0;0;0;0;0;'; //roll pitch yaw || kp kd

  var stateDecoder = <String, String>{
    "s1": "NETWORK_DISCONNECTED",
    "s2": "NETWORK_CONNECTED",
    "s3": "DRONE_INIT",
    "s4": "MOTORS_INIT",
    "s5": "IMU_CALIBRATING",
    "s6": "IMU_INIT",
    "s7": "DISARMED",
    "s8": "ARMED",
    "s9": "IMU_READY",
    "sA": " ESC_CALIBRATING",
    "sB": "ARMED_ACRO",
  };
  var requestStateDecoder = <String, String>{
    "ARM": "r0                                                          "
        .substring(0, 30),
    "DISARM": "r1                                                       "
        .substring(0, 30),
    "ACROMODE": "r2                                                     "
        .substring(0, 30),
    "PID_SEND": "r3",
    "ESC_CALIBRATE":"r5                                                 ".substring(0,30),
  };
  void setLabels() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    s.setStringList('key', stateDecoder.keys.toList());
    s.setStringList('labels', stateDecoder.values.toList());
  }

  void getLabels() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    List<String> x = s.getStringList('key');
    List<String> y = s.getStringList('labels');
    if (x == null || y == null) {
      stateDecoder = <String, String>{
        "s1": "NETWORK_DISCONNECTED",
        "s2": "NETWORK_CONNECTED",
        "s3": "DRONE_INIT",
        "s4": "MOTORS_INIT",
        "s5": "IMU_CALIBRATING",
        "s6": "IMU_INIT",
        "s7": "DISARMED",
        "s8": "ARMED",
        "s9": "IMU_READY",
        "sA": " ESC_CALIBRATING",
        "sB": "ARMED_ACRO"
      };
      setLabels();
      return;
    }
    for (int i = 0; i < x.length; i++) {
      stateDecoder[x[i]] = y[i];
    }
    setLabels();
  }

  @override
  void initState() {
    super.initState();
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

  GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
  void connectWebsocket() {
    print("Connecting...");
    // channel = IOWebSocketChannel.connect('wss://echo.websocket.org');
    channel = IOWebSocketChannel.connect('ws://' + ipAddress);

    channel.stream.listen(
      (message) {
        // print("Received: $message");
        connected = true;
        consoleOut += message;
        stringList = consoleOut.split('\n');
        stringList = consoleOut.split('\n');

        if (stringList.length >= 20) {
          stringList =
              stringList.reversed.toList().sublist(0, 20).reversed.toList();
        }
        consoleOut = stringList.join('\n');

        if (message[0] == 's') {
          //state function.
          change = !change;
          currentState = stateDecoder[message.substring(0, 2)];
          if (currentState == "DISARMED") {
            armed = false;
          }
          setState(() {});
          return;
        } else if (message[0] == 'r') {
          return;
        }
        currentState = "ARMED";

        // print(message.split(';'));
        throttles.add(GraphData(i, int.parse(message.split(';')[1])));
        if (throttles.length >= maxLengthGraph) {
          throttles = throttles.reversed
              .toList()
              .sublist(0, maxLengthGraph)
              .reversed
              .toList();
        }
        roll.add(GraphData(i, int.parse(message.split(';')[2])));
        if (roll.length >= maxLengthGraph) {
          roll = roll.reversed
              .toList()
              .sublist(0, maxLengthGraph)
              .reversed
              .toList();
        }
        pitch.add(GraphData(i, int.parse(message.split(';')[3])));
        if (pitch.length >= maxLengthGraph) {
          pitch = pitch.reversed
              .toList()
              .sublist(0, maxLengthGraph)
              .reversed
              .toList();
        }
        yaw.add(GraphData(i, int.parse(message.split(';')[4])));
        if (yaw.length >= maxLengthGraph) {
          yaw = yaw.reversed
              .toList()
              .sublist(0, maxLengthGraph)
              .reversed
              .toList();
        }
        i = i + 1;
        setState(() {});
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
        setState(() {});
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
        setState(() {});
      },
    );

    setState(() {});
  }

  void sendMessage(String text) {
    if (connected) {
      channel.sink.add(text);
      print("Sending: $text");
      // channel.sink.close(status.goingAway);
    } else {
      print("Not connected");
    }
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
                  keyboardType: TextInputType.number,
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
                  sendMessage(customMsg);
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

  void sendPIDGains() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Edit PID Gains"),
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
                      Text("Roll Kp"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: pids[0]),
                          onChanged: (value) {
                            pids[0] = value;
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
                      Text("Pitch Kp"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: pids[1]),
                          onChanged: (value) {
                            pids[1] = value;
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
                      Text("Yaw Kp"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: pids[2]),
                          onChanged: (value) {
                            pids[2] = value;
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
                      Text("Roll Kd"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: pids[3]),
                          onChanged: (value) {
                            pids[3] = value;
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
                      Text("Pitch Kd"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: pids[4]),
                          onChanged: (value) {
                            pids[4] = value;
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
                      Text("Yaw Kd"),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextField(
                          decoration: InputDecoration(hintText: pids[5]),
                          onChanged: (value) {
                            pids[5] = value;
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
                pidGainsText = pids.join(';');
                pidGainsText =
                    'r3;' + pidGainsText + ';                         ';
                print(pidGainsText);
                print(pidGainsText.length);
                sendMessage(pidGainsText);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((onValue) {
      setState(() {});
    });
  }

  List<String> trims = ['1500', '1500', '1500', '1500'];
  String trimText = 'r4;1500;1500;1500;1500;';
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
                trimText = 'r4;' + trimText + ';                         ';
                print(trimText);
                print(trimText.length);
                sendMessage(trimText);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((onValue) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: "Edit label maps",
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => EditLabelsPage()));
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
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                      onPressed: () {
                        if (connected == true) {
                          sendPIDGains();
                        } else {
                          key.currentState.showSnackBar(SnackBar(
                            content: Text("Not connected"),
                          ));
                        }
                      },
                      child: Text("PID Gains")),
                  RaisedButton(
                      child: Text("Trims"),
                      onPressed: () {
                        if (connected == true) {
                          sendTrims();
                        } else {
                          key.currentState.showSnackBar(SnackBar(
                            content: Text("Not connected"),
                          ));
                          // }
                        }
                      }),
                  RaisedButton(
                      child: Text("Custom Message"),
                      onPressed: () {
                        if (connected == true) {
                          sendCustomMessage();
                        } else {
                          key.currentState.showSnackBar(SnackBar(
                            content: Text("Not connected"),
                          ));
                          // }
                        }
                      }),
                ],
              ),
              // SizedBox(
              //   height: 10,
              // ),
              // Center(
              //   child: Container(
              //       child: Text(
              //     "Connected to: $wifiSSID ",
              //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //     textAlign: TextAlign.left,
              //   )),
              // ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.height * 0.1,
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
                    color: (connected == true) ? Colors.green : Colors.red,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              AbsorbPointer(
                absorbing: !connected,
                child: LiteRollingSwitch(
                  //initial value
                  value: armed,
                  textOn: 'Armed',
                  textOff: 'Disarmed',

                  colorOn: Colors.greenAccent[700],
                  colorOff: Colors.redAccent[700],
                  animationDuration: Duration(milliseconds: 100),
                  iconOn: Icons.power_settings_new,
                  iconOff: Icons.close,
                  textSize: 16.0,
                  onChanged: (bool state) {
                    //Use it to manage the different states
                    if (state == true) {
                      sendMessage(requestStateDecoder['ARM']); //armed
                    } else {
                      sendMessage(requestStateDecoder['DISARM']); //disarmed
                    }

                    armed = state;
                  },
                ),
              ),
              SizedBox(
                height: 40,
              ),
              AnimatedContainer(
                decoration: BoxDecoration(
                  color: (change == true)?Colors.amber.withAlpha(0):Colors.amber.withAlpha(255),
                  border: Border.all(width: 1.0, color: Colors.black),
                  borderRadius: BorderRadius.all(
                      Radius.circular(5.0) //         <--- border radius here
                      ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(currentState, style: TextStyle(fontSize: 20)),
                ),
                duration: Duration(milliseconds: 500),
              ),

              Divider(),
              Center(
                child: Container(
                    child: RichText(
                        text: TextSpan(
                            style: new TextStyle(
                              fontSize: 14.0,
                              color: Colors.black,
                            ),
                            children: [
                      TextSpan(
                        text: "P Gains: Roll: ",
                        style: new TextStyle(
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: "${pids[0]}"),
                      TextSpan(
                        text: " Pitch: ",
                        style: new TextStyle(
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: "${pids[1]}"),
                      TextSpan(
                        text: " Yaw: ",
                        style: new TextStyle(
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: "${pids[2]}"),
                    ]))),
              ),
              Center(
                child: Container(
                    child: RichText(
                        text: TextSpan(
                            style: new TextStyle(
                              fontSize: 14.0,
                              color: Colors.black,
                            ),
                            children: [
                      TextSpan(
                        text: "D Gains: Roll: ",
                        style: new TextStyle(
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: "${pids[3]}"),
                      TextSpan(
                        text: " Pitch: ",
                        style: new TextStyle(
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: "${pids[4]}"),
                      TextSpan(
                        text: " Yaw: ",
                        style: new TextStyle(
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: "${pids[5]}"),
                    ]))),
              ),
              Divider(),
              Center(
                child: Container(
                    child: Text(
                  "Motor Trims: " + trimText.trim().substring(3),
                  textAlign: TextAlign.left,
                )),
              ),
              Divider(),
              Center(
                child: Container(
                    child: Text(
                  "Motor Outputs",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                )),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                child: SfCartesianChart(
                  primaryXAxis: NumericAxis(),
                  // primaryXAxis: DateTimeAxis(),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                  ),
                  series: <LineSeries<GraphData, dynamic>>[
                    LineSeries<GraphData, dynamic>(
                        dataSource: throttles,
                        xValueMapper: (GraphData sales, _) => sales.timestamp,
                        yValueMapper: (GraphData sales, _) {
                          // print(sales.value);
                          return sales.value;
                        },
                        // Enable data label
                        legendItemText: "Motor 1",
                        animationDuration: 0,
                        dataLabelSettings: DataLabelSettings(isVisible: false)),
                    LineSeries<GraphData, dynamic>(
                        dataSource: yaw,
                        xValueMapper: (GraphData sales, _) => sales.timestamp,
                        yValueMapper: (GraphData sales, _) =>
                            sales.value.toInt(),
                        // Enable data label
                        legendItemText: "Motor 2",
                        animationDuration: 0,
                        dataLabelSettings: DataLabelSettings(isVisible: false)),
                    LineSeries<GraphData, dynamic>(
                        dataSource: pitch,
                        xValueMapper: (GraphData sales, _) => sales.timestamp,
                        yValueMapper: (GraphData sales, _) =>
                            sales.value.toInt(),
                        // Enable data label
                        legendItemText: "Motor 3",
                        animationDuration: 0,
                        dataLabelSettings: DataLabelSettings(isVisible: false)),
                    LineSeries<GraphData, dynamic>(
                        dataSource: roll,
                        xValueMapper: (GraphData sales, _) => sales.timestamp,
                        yValueMapper: (GraphData sales, _) =>
                            sales.value.toInt(),
                        // Enable data label
                        legendItemText: "Motor 4",
                        animationDuration: 0,
                        dataLabelSettings: DataLabelSettings(isVisible: false))
                  ],
                ),
              ),
              RaisedButton(
                  onPressed: () {
                    throttles = [];
                    yaw = [];
                    roll = [];
                    pitch = [];
                    i = 0;
                    setState(() {});
                  },
                  child: Text("Clear graph")),
              Divider(),
              Center(
                child: Container(
                    child: Text(
                  "Console Output",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                )),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Container(
                    // color: Colors.grey,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      border: Border.all(width: 2.0, color: Colors.purple),
                      borderRadius: BorderRadius.all(Radius.circular(
                              5.0) //         <--- border radius here
                          ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(consoleOut),
                    )),
              ),
              RaisedButton(
                  onPressed: () {
                    consoleOut = "";
                    setState(() {});
                  },
                  child: Text("Clear console")),
            ],
          ),
        ),
      ),
    );
  }
}

class GraphData {
  GraphData(this.timestamp, this.value);

  final dynamic timestamp;
  final int value;
}
