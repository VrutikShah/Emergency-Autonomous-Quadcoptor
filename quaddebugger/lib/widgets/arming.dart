import 'package:flutter/material.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:quaddebugger/constants.dart';

class ArmingWidget extends StatefulWidget {
  ArmingWidget({Key key}) : super(key: key);

  @override
  _ArmingWidgetState createState() => _ArmingWidgetState();
}

class _ArmingWidgetState extends State<ArmingWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AbsorbPointer(
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
              sendMessage(requestStateDecoder['ARM'], connected, channel); //armed
            } else {
              sendMessage(
                  requestStateDecoder['DISARM'], connected, channel); //disarmed
            }

            armed = state;
          },
        ),
      ),
    );
  }
}
