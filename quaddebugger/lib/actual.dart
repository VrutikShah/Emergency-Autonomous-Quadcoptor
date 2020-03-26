import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';

import 'package:web_socket_channel/io.dart';
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

  bool connected = false;
  bool armed = false;
  Random r = Random();
  bool x = false;
  var stateDecoder = const <String, String>{
    "s1": "NETWORK_DISCONNECTED",
    "s2": "NETWORK_CONNECTED",
    "s3": "DRONE_INIT",
    "s4": "MOTORS_INIT",
    "s5": "IMU_CALIBRATING",
    "s6": "IMU_INIT",
    "s7": "DISARMED",
    "s8": "ARMED",
    "s9": "IMU_READY"
  };
  @override
  void initState() {
    super.initState();

    // connectWebsocket();
  }

  GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
  void connectWebsocket() {
    print("Connecting...");
    // channel = IOWebSocketChannel.connect('wss://echo.websocket.org');
    channel = IOWebSocketChannel.connect('ws://' + ipAddress);
    currentState = stateDecoder['s2'];
    channel.stream.listen(
      (message) {
        // print("Received: $message");
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
          currentState = stateDecoder[message.substring(0, 2)];
          setState(() {});
          return;
        }

        // print(message.split(';'));
        throttles.add(GraphData(i, int.parse(message.split(';')[1])));
        if (throttles.length >= 20) {
          throttles =
              throttles.reversed.toList().sublist(0, 20).reversed.toList();
        }
        roll.add(GraphData(i, int.parse(message.split(';')[2])));
        if (roll.length >= 20) {
          roll = roll.reversed.toList().sublist(0, 20).reversed.toList();
        }
        pitch.add(GraphData(i, int.parse(message.split(';')[3])));
        if (pitch.length >= 20) {
          pitch = pitch.reversed.toList().sublist(0, 20).reversed.toList();
        }
        yaw.add(GraphData(i, int.parse(message.split(';')[4])));
        if (yaw.length >= 20) {
          yaw = yaw.reversed.toList().sublist(0, 20).reversed.toList();
        }
        i = i+1;
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
    connected = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 10,
              ),
              Center(
                child: Container(
                    child: Text(
                  "Websocket Address",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                )),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 1,
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: TextField(
                    controller: _controller,
                    // keyboardType: TextInputType.number,
                    decoration: InputDecoration(border: OutlineInputBorder()),
                    onChanged: (value) {
                      ipAddress = value;
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
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
                height: 30,
              ),
              LiteRollingSwitch(
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
                    sendMessage("4"); //armed
                  } else {
                    sendMessage("3"); //disarmed
                  }

                  armed = state;
                },
              ),
              SizedBox(
                height: 40,
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1.0, color: Colors.black),
                  borderRadius: BorderRadius.all(
                      Radius.circular(5.0) //         <--- border radius here
                      ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(currentState, style: TextStyle(fontSize: 20)),
                ),
              ),
              SizedBox(
                height: 40,
              ),
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
                        legendItemText: "Throttle",
                        animationDuration: 0,
                        dataLabelSettings: DataLabelSettings(isVisible: false)),
                    LineSeries<GraphData, dynamic>(
                        dataSource: yaw,
                        xValueMapper: (GraphData sales, _) => sales.timestamp,
                        yValueMapper: (GraphData sales, _) =>
                            sales.value.toInt(),
                        // Enable data label
                        legendItemText: "Yaw",
                        animationDuration: 0,
                        dataLabelSettings: DataLabelSettings(isVisible: false)),
                    LineSeries<GraphData, dynamic>(
                        dataSource: pitch,
                        xValueMapper: (GraphData sales, _) => sales.timestamp,
                        yValueMapper: (GraphData sales, _) =>
                            sales.value.toInt(),
                        // Enable data label
                        legendItemText: "Pitch",
                        animationDuration: 0,
                        dataLabelSettings: DataLabelSettings(isVisible: false)),
                    LineSeries<GraphData, dynamic>(
                        dataSource: roll,
                        xValueMapper: (GraphData sales, _) => sales.timestamp,
                        yValueMapper: (GraphData sales, _) =>
                            sales.value.toInt(),
                        // Enable data label
                        legendItemText: "Roll",
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
              SizedBox(
                height: 10,
              ),
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
