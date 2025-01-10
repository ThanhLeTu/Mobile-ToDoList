import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../controller/task_controller.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../screen/login_screen.dart';
class CalendarScreen extends StatefulWidget {

   final String userId;
   
  CalendarScreen({required this.userId});
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final TaskController _taskController;
  late final NotificationService _notificationService;
  late final AuthService _authService;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasks = {};

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _notificationService.initializeNotifications();
    _taskController = TaskController(_notificationService, widget.userId);
      _authService = AuthService();
    _loadTasks();
  }

  void _loadTasks() {
    _taskController.getTasksStream().listen((tasks) {
      setState(() {
        _tasks = tasks;
      });
    });
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && selectedTime != null) {
                final task = Task(
                  id: '',
                  title: titleController.text,
                  time: selectedTime!,
                userId: widget.userId,
                );
                _taskController.addTask(_selectedDay ?? _focusedDay, task);
                Navigator.pop(context);
              }
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch Công Việc'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => _tasks[day] ?? [],
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
                    onPressed: () => _taskController.deleteTask(task),
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