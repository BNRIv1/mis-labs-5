import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/Exam.dart';
import '../widgets/AuthGate.dart';
import '../widgets/NewExam.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CollectionReference _itemsCollection =
      FirebaseFirestore.instance.collection('exams');
  List<Exam> _exams = [];
  Map<DateTime, List<dynamic>> _events = {};
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await _itemsCollection
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get() as QuerySnapshot<Map<String, dynamic>>;

    _exams =
        querySnapshot.docs.map((DocumentSnapshot<Map<String, dynamic>> doc) {
      return Exam.fromMap(doc.data()!);
    }).toList();
    _updateEvents();
  }

  void _updateEvents() {
    _events = {};
    for (Exam exam in _exams) {
      DateTime examDate = DateTime(
          exam.examDate.year, exam.examDate.month, exam.examDate.day, 0, 0, 0);
      if (_events.containsKey(examDate)) {
        _events[examDate]!.add(exam);
      } else {
        _events[examDate] = [exam];
      }
    }
    setState(() {});
  }

  void _addExam() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: NewExam(
            addExam: _addNewExamToDatabase,
          ),
        );
      },
    );
  }

  void _addNewExamToDatabase(
      String subject, DateTime date, TimeOfDay time) async {
    String topic = 'exams';

    FirebaseMessaging.instance.subscribeToTopic(topic);

    try {
      var deviceState = await OneSignal.shared.getDeviceState();
      String? playerId = deviceState?.userId;

      if (playerId != null && playerId.isNotEmpty) {
        List<String> playerIds = [playerId];

        try {
          await OneSignal.shared.postNotification(OSCreateNotification(
            playerIds: playerIds,
            content: "You have a new exam: $subject",
            heading: "New Exam Added",
          ));
        } catch (e) {}
      } else {}
    } catch (e) {}

    addExam(subject, date, time);
  }

  Future<void> addExam(String subject, DateTime date, TimeOfDay time) async {
    User? user = FirebaseAuth.instance.currentUser;
    DateTime newDate = DateTime(
        date.year, date.month, date.day, time.hour, time.minute, 0, 0, 0);
    if (user != null) {
      await FirebaseFirestore.instance.collection('exams').add({
        'subjectName': subject,
        'examDate': newDate,
        'userId': user.uid,
      });
      _loadExams();
    }
  }

  Future<void> _signOutAndNavigateToLogin(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {}
  }

  void _launchGoogleMaps(GeoPoint location) async {
    final lat = location.latitude;
    final long = location.longitude;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$long';

    if (await canLaunch(url)) {
      await launch(url);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Scheduler - 201177"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          ElevatedButton(
            onPressed: () => _addExam(),
            style: const ButtonStyle(
              backgroundColor:
                  MaterialStatePropertyAll<Color>(Colors.greenAccent),
            ),
            child: const Text(
              "Add exam",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => _signOutAndNavigateToLogin(context),
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue),
            ),
            child: const Text(
              "Sign out",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2023),
            lastDay: DateTime(2025),
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              formatButtonTextStyle: const TextStyle()
                  .copyWith(color: Colors.white, fontSize: 15.0),
              formatButtonDecoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            calendarStyle: CalendarStyle(
              weekendTextStyle: const TextStyle().copyWith(color: Colors.blue),
              outsideDaysVisible: false,
              markersMaxCount: 1,
              markersAlignment: Alignment.bottomCenter,
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
            ),
            onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (DateTime focusedDay) {
              setState(() {
                _focusedDay = DateTime(focusedDay.year, focusedDay.month, 1);
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                DateTime eventDate = DateTime(date.year, date.month, date.day);
                if (_events.containsKey(eventDate) &&
                    _events[eventDate]!.isNotEmpty) {
                  return Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      width: 20.0,
                      height: 20.0,
                      child: Center(
                        child: Text(
                          _events[eventDate]!.length.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildExamList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExamList() {
    // Filter exams for the focused month
    final currentMonthExams = _exams
        .where((exam) =>
            exam.examDate.month == _focusedDay.month &&
            exam.examDate.year == _focusedDay.year)
        .toList();

    if (currentMonthExams.isEmpty) {
      return const Center(
        child: Text("No exams for the current month."),
      );
    }

    return GridView.builder(
      itemCount: currentMonthExams.length,
      itemBuilder: (context, index) {
        return GestureDetector(
            onTap: () {
              _launchGoogleMaps(currentMonthExams[index].location);
            },
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentMonthExams[index].subjectName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm')
                            .format(currentMonthExams[index].examDate),
                        style:
                            const TextStyle(fontSize: 20, color: Colors.grey),
                      )
                    ],
                  )
                ],
              ),
            ));
      },
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    );
  }
}
