import 'package:flutter/material.dart';
import 'package:quaddebugger/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphWidget extends StatefulWidget {
  GraphWidget({Key key, this.width}) : super(key: key);
  var width;
  @override
  _GraphWidgetState createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      child: Column(
        children: <Widget>[
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
                    dataSource: motor1,
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
                    dataSource: motor2,
                    xValueMapper: (GraphData sales, _) => sales.timestamp,
                    yValueMapper: (GraphData sales, _) => sales.value.toInt(),
                    // Enable data label
                    legendItemText: "Motor 2",
                    animationDuration: 0,
                    dataLabelSettings: DataLabelSettings(isVisible: false)),
                LineSeries<GraphData, dynamic>(
                    dataSource: motor3,
                    xValueMapper: (GraphData sales, _) => sales.timestamp,
                    yValueMapper: (GraphData sales, _) => sales.value.toInt(),
                    // Enable data label
                    legendItemText: "Motor 3",
                    animationDuration: 0,
                    dataLabelSettings: DataLabelSettings(isVisible: false)),
                LineSeries<GraphData, dynamic>(
                    dataSource: motor4,
                    xValueMapper: (GraphData sales, _) => sales.timestamp,
                    yValueMapper: (GraphData sales, _) => sales.value.toInt(),
                    // Enable data label
                    legendItemText: "Motor 4",
                    animationDuration: 0,
                    dataLabelSettings: DataLabelSettings(isVisible: false))
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
    );
  }
}
