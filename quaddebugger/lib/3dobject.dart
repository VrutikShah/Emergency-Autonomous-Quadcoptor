import 'package:flutter/material.dart';

import '3dobj.dart';

class Drone3d extends StatefulWidget {
  Drone3d({Key key}) : super(key: key);

  @override
  _Drone3dState createState() => _Drone3dState();
}

class _Drone3dState extends State<Drone3d> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        color: Colors.black,
        child: Object3D(
          asset: true,
          path: 'assets/model.obj',
          size: const Size(40.0, 40.0),
          zoom: 0.5,
        ),
      ),
    );
  }
}
