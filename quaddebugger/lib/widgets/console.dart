import 'package:flutter/material.dart';
import 'package:quaddebugger/constants.dart';

class Consolewidget extends StatefulWidget {
  Consolewidget({Key key}) : super(key: key);

  @override
  _ConsolewidgetState createState() => _ConsolewidgetState();
}

class _ConsolewidgetState extends State<Consolewidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
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
                borderRadius: BorderRadius.all(
                    Radius.circular(5.0) //         <--- border radius here
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
    );
  }
}
