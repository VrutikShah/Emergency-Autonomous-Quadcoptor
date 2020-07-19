import 'package:flutter/material.dart';
import 'dart:async';
import 'mqtt_stream.dart';

class MqttPage extends StatefulWidget {
  MqttPage();

  @override
  MqttPageState createState() => MqttPageState();
}

class MqttPageState extends State<MqttPage> {
  // Instantiate an instance of the class that handles
  // connecting, subscribing, publishing to Adafruit.io
  MQTTClientWrapper myMqtt = MQTTClientWrapper();
  final myTopicController = TextEditingController();
  final myValueController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MQTT Home Page"),
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      children: <Widget>[
        _subscriptionInfo(),
        _publishInfo(),
        // _streamdata(),
      ],
    );
  }

  Widget _subscriptionInfo() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 20.0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Topic:',
                style: TextStyle(fontSize: 24),
              ),
              Flexible(
                child: TextField(
                  controller: myTopicController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter topic to subscribe to',
                  ),
                ),
              ),
            ],
          ),
          RaisedButton(
            color: Colors.blue,
            textColor: Colors.white,
            child: Text('Subscribe'),
            onPressed: () {
              subscribe(myTopicController.text);
            },
          ),
        ],
      ),
    );
  }

  // Widget _streamdata() {}

  // Widget _subscriptionData() {
  //   return StreamBuilder(
  //       stream: AdafruitFeed.sensorStream,
  //       builder: (context, snapshot) {
  //         if (!snapshot.hasData) {
  //           return CircularProgressIndicator();
  //         }
  //         String reading = snapshot.data;
  //         if (reading == null) {
  //           reading = 'no value is available';
  //         }
  //         return Text(reading);
  //       });
  // }

  Widget _publishInfo() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 20.0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Value:',
                style: TextStyle(fontSize: 24),
              ),
              Flexible(
                child: TextField(
                  controller: myValueController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter value to publish',
                  ),
                ),
              ),
            ],
          ),
          RaisedButton(
            color: Colors.blue,
            textColor: Colors.white,
            child: Text('Publish'),
            onPressed: () {
              publish(myTopicController.text, myValueController.text);
            },
          ),
        ],
      ),
    );
  }

  Future<void> alertbox(bool rc, String topic) {
    String _text = rc
        ? ("Subscribed successfully to topic: $topic")
        : ("failed to Subscribe to topic: $topic");
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_text),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[Text('This is a demo alert dialog.')],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  subscribe(String topic) async {
    myMqtt.prepareMqttClient(topic);
  }

  void publish(String topic, String value) {
    myMqtt.publish(topic, value);
  }

  // Widget _currentStatus() {
  //   String _status = myMqtt.checkstatus();
  //   return Container(
  //     child: Text(_status),
  //   );
  // }
}
