import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class Task {
  final String id; // ID để quản lý công việc
  final String title;
  final TimeOfDay time;

  Task({required this.id, required this.title, required this.time});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
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
    );
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotification(Task task, DateTime taskDateTime) async {
    final tz.TZDateTime notificationTime =
        tz.TZDateTime.from(taskDateTime, tz.local);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_channel_id', // ID của kênh thông báo
      'Task Notifications', // Tên kênh
      channelDescription: 'Thông báo nhắc nhở công việc',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.hashCode, // Mã định danh thông báo
      'Nhắc nhở công việc',
      task.title,
      notificationTime,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exact, // Thêm dòng này
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final NotificationService _notificationService;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasks = {};

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _notificationService.initializeNotifications();
    _loadTasksFromFirebase();
  }

  // Lấy công việc từ Firestore
  void _loadTasksFromFirebase() {
    FirebaseFirestore.instance
        .collection('tasks')
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        _tasks.clear();
        querySnapshot.docs.forEach((doc) {
          final task = Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          final date = DateTime.parse(doc['day']);
          if (_tasks[date] == null) {
            _tasks[date] = [];
          }
          _tasks[date]!.add(task);
        });
      });
    });
  }

  // Thêm công việc
  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thêm Công Việc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Tên Công Việc'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                },
                child: Text('Chọn Thời Gian'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && selectedTime != null) {
                  final task = Task(
                    id: '',
                    title: titleController.text,
                    time: selectedTime!,
                  );
                  _addTaskToFirebase(_selectedDay ?? _focusedDay, task);
                }
                Navigator.pop(context);
              },
              child: Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  // Lưu công việc vào Firestore
  void _addTaskToFirebase(DateTime day, Task task) {
    FirebaseFirestore.instance.collection('tasks').add({
      'day': day.toIso8601String(),
      ...task.toMap(),
    }).then((docRef) {
      final notificationTime = DateTime(
        day.year,
        day.month,
        day.day,
        task.time.hour,
        task.time.minute,
      );
      final newTask = Task(id: docRef.id, title: task.title, time: task.time);

      _notificationService.scheduleNotification(newTask, notificationTime);

      print('Công việc đã được lưu và thông báo đã được lên lịch');
    }).catchError((error) {
      print('Lỗi lưu công việc: $error');
    });
  }

  // Xóa công việc từ Firestore
  void _deleteTaskFromFirebase(Task task) {
    FirebaseFirestore.instance
        .collection('tasks')
        .doc(task.id)
        .delete()
        .then((_) {
      _notificationService.flutterLocalNotificationsPlugin
          .cancel(task.hashCode);
      print('Công việc đã bị xóa và thông báo đã bị hủy');
    }).catchError((error) {
      print('Lỗi xóa công việc: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch Công Việc'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return _tasks[day] ?? [];
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks[_selectedDay ?? _focusedDay]?.length ?? 0,
              itemBuilder: (context, index) {
                final task = _tasks[_selectedDay ?? _focusedDay]![index];
                return ListTile(
                  leading: Icon(Icons.work),
                  title: Text(task.title),
                  subtitle: Text('Giờ: ${task.time.hour}:${task.time.minute}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteTaskFromFirebase(task);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
