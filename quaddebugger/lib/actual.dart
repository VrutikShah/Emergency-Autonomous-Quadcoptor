import 'dart:math';

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
  String ipAddress = "192.168.4.1:81";
  var channel;
  String consoleOut = "";
  List<String> stringList;
  TextEditingController _controller =
      TextEditingController(text: "192.168.4.1:81");
  int i = 0;
  String currentState = "NETWORK_DISCONNECTED";
  List<GraphData> motor4 = [GraphData(0, 0)];
  List<GraphData> motor3 = [GraphData(0, 0)];
  List<GraphData> motor2 = [GraphData(0, 0)];
  List<GraphData> motor1 = [GraphData(0, 0)];
  bool change = false;
  String wifiSSID;
  int maxLengthGraph = 60;
  bool connected = false;
  var subscription;
  bool armed = false;

  bool x = false;

  List<String> pids = ['0', '0', '0', '0', '0', '0', '0', '0', '0']; // rpy, pid
  String pidGainsText = 'r3;0;0;0;0;0;0;'; //motor2 motor3 motor1 || kp kd

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
    "PID_KI_SEND": "r6",
    "PID_KP_SEND": "r3",
    "PID_KD_SEND": "r5",
    "ESC_CALIBRATE":
        "r7                                                 ".substring(0, 30),
  };
  void setLabels() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    s.setStringList('key', stateDecoder.keys.toList());
    s.setStringList('labels', stateDecoder.values.toList());
  }

  void setSettings() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    s.setString('pidGains', pids.join(';'));
    s.setString('trimText', trimText);
  }

  void getSettings() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    pidGainsText = s.getString('pidGains');
    pids = pidGainsText.split(';');
    trimText = s.getString('trimText');
    if (pidGainsText == null) {
      pids = ['0', '0', '0', '0', '0', '0', '0', '0', '0'];
    }
    if (trimText == null) {
      trimText = 'r4;1500;1500;1500;1500;';
    }
    setState(() {});
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
        } else if (message[0] == 'd') {
          if (message[1] == '0') {
            // throttles
            currentState = "ARMED";

            // print(message.split(';'));
            motor4.add(GraphData(i, int.parse(message.split(';')[4])));
            if (motor4.length >= maxLengthGraph) {
              motor4 = motor4.reversed
                  .toList()
                  .sublist(0, maxLengthGraph)
                  .reversed
                  .toList();
            }
            motor2.add(GraphData(i, int.parse(message.split(';')[2])));
            if (motor2.length >= maxLengthGraph) {
              motor2 = motor2.reversed
                  .toList()
                  .sublist(0, maxLengthGraph)
                  .reversed
                  .toList();
            }
            motor3.add(GraphData(i, int.parse(message.split(';')[3])));
            if (motor3.length >= maxLengthGraph) {
              motor3 = motor3.reversed
                  .toList()
                  .sublist(0, maxLengthGraph)
                  .reversed
                  .toList();
            }
            motor1.add(GraphData(i, int.parse(message.split(';')[1])));
            if (motor1.length >= maxLengthGraph) {
              motor1 = motor1.reversed
                  .toList()
                  .sublist(0, maxLengthGraph)
                  .reversed
                  .toList();
            }
            i = i + 1;
            setState(() {});
          } else if (message[1] == '1') {
            //SET angles - <d1;x;y;z>
            var poses = message.split(';');
            DronePose.y = double.parse(poses[1]);
            DronePose.x = double.parse(poses[2]);
            DronePose.z = double.parse(poses[3]);

            setState(() {});
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
      setSettings();
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
      setSettings();
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
          )
        ],
      ),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 230,
                  ),
                  Text("PID Gains",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  DataTable(columns: [
                    DataColumn(label: Text("Label", textAlign: TextAlign.center,)),
                    DataColumn(label: Text("Kp", textAlign: TextAlign.center)),
                    DataColumn(label: Text("Ki", textAlign: TextAlign.center)),
                    DataColumn(label: Text("Kd", textAlign: TextAlign.center)),
                  ], rows: [
                    DataRow(cells: [
                      DataCell(Text("Roll", textAlign: TextAlign.center)),
                      DataCell(Text(pids[0].toString(), textAlign: TextAlign.center)),
                      DataCell(Text(pids[3].toString(), textAlign: TextAlign.center)),
                      DataCell(Text(pids[6].toString(), textAlign: TextAlign.center)),
                    ]),
                    DataRow(cells: [
                      DataCell(Text("Pitch", textAlign: TextAlign.center)),
                      DataCell(Text(pids[1].toString(), textAlign: TextAlign.center)),
                      DataCell(Text(pids[4].toString(), textAlign: TextAlign.center)),
                      DataCell(Text(pids[7].toString(), textAlign: TextAlign.center)),
                    ]),
                    DataRow(cells: [
                      DataCell(Text("Yaw", textAlign: TextAlign.center)),
                      DataCell(Text(pids[2].toString(), textAlign: TextAlign.center)),
                      DataCell(Text(pids[5].toString(), textAlign: TextAlign.center)),
                      DataCell(Text(pids[8].toString(), textAlign: TextAlign.center)),
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
                                    dataSource: motor4,
                                    xValueMapper: (GraphData sales, _) =>
                                        sales.timestamp,
                                    yValueMapper: (GraphData sales, _) {
                                      // print(sales.value);
                                      return sales.value;
                                    },
                                    // Enable data label
                                    legendItemText: "Motor 1",
                                    animationDuration: 0,
                                    dataLabelSettings:
                                        DataLabelSettings(isVisible: false)),
                                LineSeries<GraphData, dynamic>(
                                    dataSource: motor1,
                                    xValueMapper: (GraphData sales, _) =>
                                        sales.timestamp,
                                    yValueMapper: (GraphData sales, _) =>
                                        sales.value.toInt(),
                                    // Enable data label
                                    legendItemText: "Motor 2",
                                    animationDuration: 0,
                                    dataLabelSettings:
                                        DataLabelSettings(isVisible: false)),
                                LineSeries<GraphData, dynamic>(
                                    dataSource: motor3,
                                    xValueMapper: (GraphData sales, _) =>
                                        sales.timestamp,
                                    yValueMapper: (GraphData sales, _) =>
                                        sales.value.toInt(),
                                    // Enable data label
                                    legendItemText: "Motor 3",
                                    animationDuration: 0,
                                    dataLabelSettings:
                                        DataLabelSettings(isVisible: false)),
                                LineSeries<GraphData, dynamic>(
                                    dataSource: motor2,
                                    xValueMapper: (GraphData sales, _) =>
                                        sales.timestamp,
                                    yValueMapper: (GraphData sales, _) =>
                                        sales.value.toInt(),
                                    // Enable data label
                                    legendItemText: "Motor 4",
                                    animationDuration: 0,
                                    dataLabelSettings:
                                        DataLabelSettings(isVisible: false))
                              ],
                            ),
                          ),
                          RaisedButton(
                              onPressed: () {
                                motor4 = [GraphData(0, 0)];
                                motor1 = [GraphData(0, 0)];
                                motor2 = [GraphData(0, 0)];
                                motor3 = [GraphData(0, 0)];
                                i = 0;
                                setState(() {});
                              },
                              child: Text("Clear graph")),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Center(
                            child: Container(
                                child: Text(
                              "Console Output",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            )),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                            child: Container(
                                // color: Colors.grey,
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 2.0, color: Colors.purple),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
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
          Container(
            color: Colors.white,
            height: 220,
            child: Column(children: [
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
                height: 10,
              ),
              AnimatedContainer(
                decoration: BoxDecoration(
                  color: (change == true)
                      ? Colors.amber.withAlpha(0)
                      : Colors.amber.withAlpha(255),
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
            ]),
          ),
        ],
      ),
    );
  }
}

class DronePose {
  // DronePose(this.x, this.y, this.z);
  static double x, y, z;
}

class GraphData {
  GraphData(this.timestamp, this.value);

  final dynamic timestamp;
  final int value;
}
