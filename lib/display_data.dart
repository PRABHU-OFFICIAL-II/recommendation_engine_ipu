import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class DisplayData extends StatefulWidget {
  const DisplayData({super.key});

  @override
  State<DisplayData> createState() => _DisplayDataState();
}

class TaskData {
  final String date;
  final int taskCount;

  TaskData({required this.date, required this.taskCount});
}

class _DisplayDataState extends State<DisplayData>
    with SingleTickerProviderStateMixin {
  late List<TaskData> taskData;

  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(Uri.parse(
        'http://127.0.0.1:5000/masterEngine')); // Replace with your API endpoint
    if (response.statusCode == 200) {
      final Map<String, dynamic> organizations = json.decode(response.body);
      //print(organizations);
      return organizations;
    } else {
      throw Exception('Failed to load data');
    }
  }

  void _dataRefresh() {
    setState(() {
      fetchData().then((data) {
        // Handle the fetched data here
        setState(() {});
      }).catchError((error) {
        // Handle any errors that occur during the API call
        print('Error fetching data: $error');
      });
    });
  }

  String orgId = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Underdeveloped Application'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _dataRefresh,
          ),
        ],
      ),
      body: Row(children: [
        Column(children: [
          // Header Title
          Text(
            "Task Execution Report for org : $orgId",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          // Map Data Parser and Widget Builder
          FutureBuilder<Map<String, dynamic>>(
              future: fetchData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Column(children: [
                    const Center(child: CircularProgressIndicator()),
                    Text("Error: ${snapshot.error}")
                  ]);
                } else {
                  orgId = snapshot.data!["Org ID"];
                  Map<String, int> taskCountMap = {};
                  snapshot.data!['Tasks'].forEach((taskId, taskJson) {
                    String date = taskJson['Start Time'].substring(0, 10);
                    taskCountMap.update(date, (value) => value + 1,
                        ifAbsent: () => 1);
                  });

                  List<TaskData> tempTaskData = [];
                  taskCountMap.forEach((date, count) {
                    tempTaskData.add(TaskData(date: date, taskCount: count));
                  });

                  taskData = tempTaskData;
                  tempTaskData.sort((a, b) => a.date.compareTo(b.date));

                  // Side Title Widget for Line Graph
                  Widget customTitlesWidget(double value, TitleMeta titleMeta) {
                    final index = value.toInt();
                    if (index >= 0 && index < tempTaskData.length) {
                      final date = tempTaskData[index].date;
                      return SizedBox(
                        width: 100, // Adjust width as needed
                        child: Transform.rotate(
                          angle: -0.5 *
                              3.14159, // Rotate the text by 90 degrees (in radians)
                          child: Text(
                            date,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    }
                    return Container();
                  }

                  return SizedBox(
                    height: 600,
                    width: 800,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                                axisNameSize: 100,
                                axisNameWidget: const Text(
                                  "Task Execution Dates",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                drawBelowEverything: true,
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 25,
                                    getTitlesWidget: customTitlesWidget)),
                            // Hide left titles
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                                axisNameSize: 40,
                                axisNameWidget: Text(
                                  "No. of Tasks Executed",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                )),
                            // Hide top titles
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            // Hide right titles
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems:
                                  (List<LineBarSpot> touchedSpots) {
                                return touchedSpots
                                    .map((LineBarSpot touchedSpot) {
                                  const TextStyle textStyle = TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  );
                                  // Get the integer value from the double value of the spot
                                  final int value = touchedSpot.y.toInt();
                                  // Return the tooltip item with the integer value
                                  return LineTooltipItem(
                                    '$value', // Display the integer value
                                    textStyle,
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.red),
                          ),
                          minX: 0,
                          maxX: taskData.length.toDouble() - 1,
                          minY: 0,
                          maxY: taskData
                                  .map((data) => data.taskCount)
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble() +
                              5,
                          lineBarsData: [
                            LineChartBarData(
                              spots: taskData.map((data) {
                                // Map taskData to FlSpot for the chart
                                return FlSpot(taskData.indexOf(data).toDouble(),
                                    data.taskCount.toDouble());
                              }).toList(),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }),

          // Task Execution and frequency and Details
          const Row()
        ]),
      ]),
    );
  }
}