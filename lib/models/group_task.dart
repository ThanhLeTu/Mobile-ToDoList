import 'package:do_an/models/task.dart';

class GroupTask {
  final String id;
  final String groupId;
  final DateTime date;
  final String assignedToEmail;
  final bool isCompleted;
  final List<Task> listTask;
  GroupTask({
    required this.id,
    required this.groupId,
    required this.date,
    required this.assignedToEmail,
    this.isCompleted = false,
    required this.listTask,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'date': date.toIso8601String(),
      'assignedToEmail': assignedToEmail,
      'listTask': listTask.map((task) => task.toMap()).toList(),
    };
  }

  factory GroupTask.fromMap(Map<String, dynamic> map) {
    return GroupTask(
        id: map['id'],
        groupId: map['groupId'],
        date: DateTime.parse(map['date']),
        assignedToEmail: map['assignedToEmail'],
        isCompleted: map['isCompleted'] ?? false,
        listTask: map['listTask']);
  }
}
