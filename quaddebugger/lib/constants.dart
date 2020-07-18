import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

bool connected = false;
bool armed = false;
IOWebSocketChannel channel;
Function rebuildCallback;
List<String> trims = ['1500', '1500', '1500', '1500'];
String trimText = 'r4;1500;1500;1500;1500;';
List<String> pids = ['0', '0', '0', '0', '0', '0', '0', '0', '0']; // rpy, pid
String pidGainsText = 'r3;0;0;0;0;0;0;'; //motor2 motor3 motor1 || kp kd
List<GraphData> motor4 = [GraphData(0, 0)];
List<GraphData> motor3 = [GraphData(0, 0)];
List<GraphData> motor2 = [GraphData(0, 0)];
List<GraphData> motor1 = [GraphData(0, 0)];
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
void sendMessage(String text, bool connected, channel1) {
  if (connected) {
    if (text.length > 30) {
      text = text.substring(0, 30);
    } else {
      text = text + '                                                     ';
      text = text.substring(0, 30);
    }
    channel1.sink.add(text);
    print("Sending: $text, ${text.length}");
    // channel.sink.close(status.goingAway);
  } else {
    print("Not connected");
  }
}

String ipAddress = "192.168.4.1:81";

String consoleOut = "";
List<String> stringList;

int i = 0;
String labelState = "";
GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
GlobalKey<ScaffoldState> joystickKey = GlobalKey<ScaffoldState>();
bool change = false;
String wifiSSID;
int maxLengthGraph = 60;
var subscription;
double angle = 0;
bool x = false;

class DronePose {
  // DronePose(this.x, this.y, this.z);
  static double x, y, z;
}

class GraphData {
  GraphData(this.timestamp, this.value);

  final dynamic timestamp;
  final int value;
}

void setLabels() async {
  SharedPreferences s = await SharedPreferences.getInstance();
  s.setStringList('key', stateDecoder.keys.toList());
  s.setStringList('labels', stateDecoder.values.toList());
}

void setSettings() async {
  SharedPreferences s = await SharedPreferences.getInstance();
  s.setString('pidGains', pids.join(';'));
  // s.setString('trimText', 'r4;1500;1500;1500;1500;');
  s.setString('trimText', trimText);
  print("SAVING: ${pids}, ${trimText}");
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
