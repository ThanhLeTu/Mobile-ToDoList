import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/models/group.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;
  final String userId;

  TaskController(this._notificationService, this.userId);

  Stream<Map<DateTime, List<Task>>> getTasksStream() {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) {
      Map<DateTime, List<Task>> tasks = {};
      querySnapshot.docs.forEach((doc) {
        final task = Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        final date = DateTime.parse(doc['day']);
        if (tasks[date] == null) {
          tasks[date] = [];
        }
        tasks[date]!.add(task);
      });
      return tasks;
    });
  }

  Future<void> addTask(DateTime day, Task task) async {
    final docRef = _firestore.collection('tasks').doc();

    await docRef.set({
      // 'id': docRef.id,
      'id': task.id,
      'title': task.title,
      'time':
          '${task.time.hour}:${task.time.minute.toString().padLeft(2, '0')}',
      'day': day.toIso8601String(),
      // 'userId': userId,
      'userId': task.userId,
    });

    final newTask = Task(
      id: docRef.id,
      title: task.title,
      time: task.time,
      userId: userId,
    );

    final notificationTime = DateTime(
      day.year,
      day.month,
      day.day,
      task.time.hour,
      task.time.minute,
    );

    await _notificationService.scheduleNotification(newTask, notificationTime);
  }

  Future<void> deleteTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).delete();
    await _notificationService.cancelNotification(task.hashCode);
  }

  void assignGroupTask(DateTime day, Task task, Group group) {
    // Implement task association with the group
    // Example logic to associate task with group tasks storage (pseudo-code)
    print('Assigning task "${task.title}" on $day for group "${group.name}".');
    // _groupTasks[day] = _groupTasks[day] ?? [];
    // _groupTasks[day]?.add({'task': task, 'group': group});
    // Optionally trigger a notification for all group members.
    _notificationService.showNotification(
      title: 'New Group Task Assigned',
      body: 'Task: ${task.title} on $day for group: ${group.name}',
    );
  }
}
