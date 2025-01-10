import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final TimeOfDay time;
 final String userId;
  Task({required this.id, required this.title, required this.time, required this.userId,});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
        'userId': userId,
    };
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    final timeParts = map['time'].split(':');
    return Task(
      id: id,
      title: map['title'],
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      userId: map['userId'],
    );
  }
}