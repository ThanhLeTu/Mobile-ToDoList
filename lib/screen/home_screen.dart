import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/cupertino.dart';

import '../models/task.dart';
import '../controller/task_controller.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../screen/login_screen.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

import 'next_7_days_screen.dart';
import 'all_tasks_screen.dart';

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
  int _selectedIndex = 2;

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
    context: context,builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        ),
      child: SingleChildScrollView( // Thêm SingleChildScrollView
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thêm Công Việc',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C4DFF),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Tên Công Việc',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF7C4DFF)),
                ),
              ),
              SizedBox(height: 20),
              Container(
                height: 150, //chiều cao cho picker
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),// Viền xám nhạt
                  borderRadius: BorderRadius.circular(10),// Bo góc 10px
                ),
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: Color(0xFF7C4DFF), // Màu tím cho text
                        fontSize: 16, // Cỡ chữ
                      ),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    minuteInterval: 1, // Khoảng cách giữa các phút
                    secondInterval: 1,
                    initialTimerDuration: Duration.zero, // Thời gian ban đầu
                    alignment: Alignment.center, // Căn giữa picker
                    backgroundColor: Colors.transparent, // Nền trong suốt
                    onTimerDurationChanged: (Duration duration) {
                      selectedTime = TimeOfDay(
                        hour: duration.inHours,
                        minute: (duration.inMinutes % 60),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7C4DFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Thêm',
                    style: TextStyle(fontSize: 16,color: Colors.white, fontWeight: FontWeight.w600,),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
/////////////////////////////////////////////
//xử lý sự kiến nhấn vào tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
//Điều hướng
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return Next7DaysScreen(taskController: _taskController);
      case 1:
        return AllTasksScreen(taskController: _taskController);
      case 2:
      default:
        return _buildCalendarView();
    }
  }
//////////////////////////////////////////
  
/////////////////////////
///Hiện lịch
  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Color(0xFF7C4DFF),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Color(0xFF7C4DFF).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Color(0xFF7C4DFF),
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7C4DFF),
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => _tasks[DateTime(day.year, day.month, day.day)] ?? [],
        ),
        //Hiển thị danh sách công việc
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tasks[DateTime(_selectedDay?.year ?? _focusedDay.year, 
                _selectedDay?.month ?? _focusedDay.month, 
                _selectedDay?.day ?? _focusedDay.day)]?.length ?? 0,
              itemBuilder: (context, index) {
                final task = _tasks[DateTime(_selectedDay?.year ?? _focusedDay.year, 
                  _selectedDay?.month ?? _focusedDay.month, 
                  _selectedDay?.day ?? _focusedDay.day)]![index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF7C4DFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.work, //Icon công việc
                              color: Color(0xFF7C4DFF),
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                          subtitle: Text(
                            'Time: ${task.time.format(context)}',
                            style: TextStyle(
                              color: Color(0xFF7C4DFF),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[400],
                            ),
                            onPressed: () => _taskController.deleteTask(task),
                          ),
                        ),
                      ),
                    ),
                  ),
                ); 
              },
            ),
          ),
        ),
      ],
    );
  }
///////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
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
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 2 ? FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ) : null,
    );
  }
}