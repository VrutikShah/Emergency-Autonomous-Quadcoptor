import 'package:flutter/material.dart';
import 'package:quaddebugger/constants.dart';
import 'package:web_socket_channel/io.dart';

class StateLabel extends StatefulWidget {
  StateLabel(this.label,{Key key}) : super(key: key);
String label;
  @override
  _StateLabelState createState() => _StateLabelState();
}

class _StateLabelState extends State<StateLabel> {
 

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      decoration: BoxDecoration(
        color: (change == true)
            ? Colors.amber.withAlpha(0)
            : Colors.amber.withAlpha(255),
        // border:
        //     Border.all(width: 1.0, color: Colors.black),
        borderRadius: BorderRadius.all(
            Radius.circular(5.0) //         <--- border radius here
            ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(widget.label,
            style: TextStyle(fontSize: 18, color: Colors.black)),
      ),
      duration: Duration(milliseconds: 500),
    );
  }
}
