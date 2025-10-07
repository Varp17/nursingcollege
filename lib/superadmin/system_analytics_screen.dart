import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SystemAnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Analytics'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('System Analytics Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 6,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 3),
                        FlSpot(1, 1),
                        FlSpot(2, 4),
                        FlSpot(3, 2),
                        FlSpot(4, 5),
                        FlSpot(5, 3),
                        FlSpot(6, 4),
                      ],
                      isCurved: true,
                      color: Colors.orange.shade800,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}