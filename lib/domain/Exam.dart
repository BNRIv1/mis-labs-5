import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  String subjectName;
  DateTime examDate;
  GeoPoint location;

  Exam({
    required this.subjectName,
    required this.examDate,
    required this.location
  });

  factory Exam.fromMap(Map<String, dynamic>? map) {
    if (map == null || map['subjectName'] == null || map['examDate'] == null ||  map['location'] == null)  {
      return Exam(subjectName: 'Default', examDate: DateTime.now(), location: const GeoPoint(41.9954, 21.4246));
    }

    return Exam(
      subjectName: map['subjectName'] as String,
      examDate: (map['examDate'] as Timestamp).toDate(),
      location: map['location'] as GeoPoint
    );
  }
}