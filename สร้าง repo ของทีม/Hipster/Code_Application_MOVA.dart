import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

//////////////////////////////////////////////////
// MODEL
//////////////////////////////////////////////////

class SensorData {
  final List<double> pressures;
  final double angle;

  SensorData({required this.pressures, required this.angle});

  factory SensorData.mock() {
    return SensorData(
      pressures: [50, 30, 60, 40],
      angle: 10,
    );
  }
}

//////////////////////////////////////////////////
// LOGIC
//////////////////////////////////////////////////

class PostureService {
  static bool isGoodPosture(SensorData data) {
    double left = data.pressures[0] + data.pressures[2];
    double right = data.pressures[1] + data.pressures[3];

    if ((left - right).abs() > 20) return false;
    if (data.angle.abs() > 15) return false;

    return true;
  }

  static List<bool> sensorBalance(SensorData data) {
    double avg =
        data.pressures.reduce((a, b) => a + b) / data.pressures.length;

    return data.pressures.map((p) => (p - avg).abs() < 15).toList();
  }

  static String getFeedbackText(SensorData data) {
    double left = data.pressures[0] + data.pressures[2];
    double right = data.pressures[1] + data.pressures[3];

    if (left > right + 20) return "Leaning left too much";
    if (right > left + 20) return "Leaning right too much";
    if (data.angle > 15) return "Leaning forward";
    if (data.angle < -15) return "Leaning backward";

    return "Good posture";
  }
}

//////////////////////////////////////////////////
// APP
//////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MainScreen(),
    );
  }
}

//////////////////////////////////////////////////
// MAIN SCREEN
//////////////////////////////////////////////////

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;
  SensorData data = SensorData.mock();

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        data: data,
        goToFeedback: () => setState(() => index = 1),
      ),
      FeedbackPage(data: data),
      HistoryPage(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: "Feedback"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "History"),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////
// HOME
//////////////////////////////////////////////////

class HomePage extends StatefulWidget {
  final SensorData data;
  final VoidCallback goToFeedback;

  HomePage({required this.data, required this.goToFeedback});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int remainingSeconds = 7200;
  Timer? timer;

  bool isSitting = false;
  bool isRunning = false;
  bool autoMode = true; // 🔥 สลับ manual / auto

  @override
  void initState() {
    super.initState();
  }

  void startTimer() {
    if (isRunning) return;

    isRunning = true;

    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        bool currentSitting = checkIfSitting(widget.data);

        if (autoMode) {
          // 🤖 AUTO MODE
          if (!currentSitting) {
            remainingSeconds = 7200; // ลุก = reset
          } else {
            if (remainingSeconds > 0) remainingSeconds--;
          }
        } else {
          // 🎮 MANUAL MODE (ไม่สน sensor)
          if (remainingSeconds > 0) remainingSeconds--;
        }

        isSitting = currentSitting;

        if (remainingSeconds == 0) {
          stopTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Time’s up! Stand up now!")),
          );
        }
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
    isRunning = false;
  }

  void resetTimer() {
    setState(() {
      remainingSeconds = 7200;
    });
  }

  bool checkIfSitting(SensorData data) {
    double total = data.pressures.reduce((a, b) => a + b);
    return total > 50;
  }

  String formatTime(int sec) {
    int h = sec ~/ 3600;
    int m = (sec % 3600) ~/ 60;
    int s = sec % 60;
    return "$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    bool good = PostureService.isGoodPosture(widget.data);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Home"), backgroundColor: Colors.black),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔥 สถานะหลัก
          Text(
            isRunning
                ? (autoMode
                    ? (isSitting ? "AUTO: SITTING" : "AUTO: NOT SITTING")
                    : "MANUAL MODE")
                : "STOPPED",
            style: TextStyle(
              color: isRunning
                  ? (autoMode
                      ? (isSitting ? Colors.green : Colors.grey)
                      : Colors.blue)
                  : Colors.orange,
              fontSize: 18,
            ),
          ),

          SizedBox(height: 10),

          Text(
            good ? "GOOD POSTURE" : "BAD POSTURE",
            style: TextStyle(
              color: good ? Colors.green : Colors.red,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 30),

          // ⭕ นาฬิกา
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: good ? Colors.green : Colors.red,
                width: 6,
              ),
            ),
            child: Center(
              child: Text(
                formatTime(remainingSeconds),
                style: TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
          ),

          SizedBox(height: 20),

          Text(
            isRunning
                ? (autoMode
                    ? (isSitting
                        ? "Auto running"
                        : "Auto reset (not sitting)")
                    : "Manual running")
                : "Press START",
            style: TextStyle(color: Colors.white70),
          ),

          SizedBox(height: 30),

          // 🔥 ปุ่มไป feedback
          GestureDetector(
            onTap: widget.goToFeedback,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: good ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "FEEDBACK",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          SizedBox(height: 30),

          // 🔥 ปุ่มควบคุม
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: startTimer, child: Text("START")),
              SizedBox(width: 10),
              ElevatedButton(onPressed: stopTimer, child: Text("STOP")),
              SizedBox(width: 10),
              ElevatedButton(onPressed: resetTimer, child: Text("RESET")),
            ],
          ),

          SizedBox(height: 20),

          // 🔥 สวิตช์ AUTO / MANUAL
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Manual"),
              Switch(
                value: autoMode,
                onChanged: (val) {
                  setState(() {
                    autoMode = val;
                  });
                },
              ),
              Text("Auto"),
            ],
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////
// FEEDBACK
//////////////////////////////////////////////////

class FeedbackPage extends StatelessWidget {
  final SensorData data;

  FeedbackPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final sensors = PostureService.sensorBalance(data);
    final text = PostureService.getFeedbackText(data);

    return Scaffold(
      appBar: AppBar(title: Text("Feedback")),
      body: Center( // 👉 ทำให้ทั้ง layout อยู่กลางจริง
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // 🔲 layout เซนเซอร์ + กลาง
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  // มุมบนซ้าย
                  Align(
                    alignment: Alignment.topLeft,
                    child: sensorCircle(sensors[0]),
                  ),

                  // มุมบนขวา
                  Align(
                    alignment: Alignment.topRight,
                    child: sensorCircle(sensors[1]),
                  ),

                  // มุมล่างซ้าย
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: sensorCircle(sensors[2]),
                  ),

                  // มุมล่างขวา
                  Align(
                    alignment: Alignment.bottomRight,
                    child: sensorCircle(sensors[3]),
                  ),

                  // 📦 กล่องกลาง
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${data.angle}°",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // 📝 ข้อความ feedback
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  // 🔵 วงกลมเซนเซอร์
  Widget sensorCircle(bool ok) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: ok ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}

//////////////////////////////////////////////////
// HISTORY
//////////////////////////////////////////////////


class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double good = 70;
    double bad = 30;

    return Scaffold(
      appBar: AppBar(title: Text("History")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),

            // 🔵 PIE CHART
            Text("Posture Ratio", style: TextStyle(fontSize: 18)),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: good,
                      color: Colors.green,
                      title: "$good%",
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: bad,
                      color: Colors.red,
                      title: "$bad%",
                      radius: 60,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // 📊 BAR CHART
            Text("Session Duration", style: TextStyle(fontSize: 18)),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    makeGroupData(0, 60, 10),
                    makeGroupData(1, 45, 15),
                    makeGroupData(2, 80, 20),
                    makeGroupData(3, 30, 10),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text("S${value.toInt() + 1}");
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            Text("Average sitting time today: 1h 20m"),
          ],
        ),
      ),
    );
  }

  // 🔥 bar group (นั่ง + ลุก)
  BarChartGroupData makeGroupData(int x, double sit, double stand) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: sit,
          color: const Color.fromARGB(255, 207, 84, 195),
          width: 8,
        ),
        BarChartRodData(
          toY: stand,
          color: const Color.fromARGB(233, 244, 184, 54),
          width: 8,
        ),
      ],
    );
  }
}
