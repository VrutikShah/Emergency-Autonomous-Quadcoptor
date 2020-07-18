import 'package:flutter/material.dart';

class Joypad extends StatefulWidget {
  Joypad(
      {@required this.onUpdate,
      this.radiusBg,
      this.radiusFg,
      this.color,
      this.onEnd,
      @required this.returnToCentre});
  Function onUpdate, onEnd;
  double radiusBg, radiusFg;
  Color color;
  bool returnToCentre;

  @override
  _JoypadState createState() => _JoypadState();
}

class _JoypadState extends State<Joypad> {
  Offset position;
  double radiusBg = 100;
  double radiusFg = 50;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.radiusBg != null) {
      radiusBg = widget.radiusBg;
    }
    if (widget.radiusFg != null) {
      radiusFg = widget.radiusFg;
    }
    position = Offset(radiusBg, radiusBg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (radiusBg + radiusFg) * 2,
      width: (radiusBg + radiusFg) * 2,
      child: Stack(
        children: <Widget>[
          Container(
            child: Center(
              child: CircleAvatar(
                backgroundColor: widget.color.withAlpha(120),
                minRadius: radiusBg,
                maxRadius: radiusBg,
              ),
            ),
          ),
          Positioned(
            top: position.dy,
            left: position.dx,
            child: GestureDetector(
              onPanStart: (details) => _onPanStart(context, details),
              onPanUpdate: (details) =>
                  _onPanUpdate(context, details, position),
              onPanEnd: (details) => _onPanEnd(context, details),
              onPanCancel: () => _onPanCancel(context),
              child: CircleAvatar(
                minRadius: radiusFg,
                maxRadius: radiusFg,
                backgroundColor: widget.color.withAlpha(120),
                // child: CircleAvatar(
                //   minRadius: radiusFg*0.8,
                //   maxRadius: radiusFg*0.8,
                //   backgroundColor: widget.color.withAlpha(255)
                // ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(BuildContext context, DragStartDetails details) {}

  void _onPanUpdate(
      BuildContext context, DragUpdateDetails details, Offset offset) {
    var x = position.dx + details.delta.dx;
    var y = position.dy + details.delta.dy;
    if ((x - radiusBg) * (x - radiusBg) + (y - radiusBg) * (y - radiusBg) <
        radiusBg * radiusBg) {
      position = Offset(x, y);
      setState(() {});
      widget.onUpdate(Offset(
          (x - radiusBg) * 100 / radiusBg, (-y + radiusBg) * 100 / radiusBg));
    }
  }

  void _onPanEnd(BuildContext context, DragEndDetails details) {
    setState(() {
      if (widget.returnToCentre) {
        position = Offset(radiusBg, radiusBg);
        widget.onEnd(Offset((position.dx - radiusBg) * 100 / radiusBg,
            (-position.dx + radiusBg) * 100 / radiusBg));
      }
    });
  }

  void _onPanCancel(BuildContext context) {
    print("Pan canceled !!");
  }
}
