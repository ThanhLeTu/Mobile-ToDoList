import 'package:cloud_firestore/cloud_firestore.dart';

import '../controller/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/cupertino.dart';

import '../models/group.dart';
import '../models/group_task.dart';
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
  late final FirebaseFirestore _firestore;
 late String displayName;
  late String email;
  late String phoneNumber;
  
  late final GroupController _groupController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasks = {};
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
     _firestore = FirebaseFirestore.instance;
    _notificationService = NotificationService();
    _notificationService.initializeNotifications();
    _taskController = TaskController(_notificationService, widget.userId);
    _authService = AuthService();
    _groupController = GroupController(widget.userId);
    _loadTasks();
  }

  void _loadTasks() {
    _taskController.getTasksStream().listen((tasks) {
      setState(() {
        _tasks = tasks;
      });
    });
  }

  Future<void> _showUserInfoDialog() async {
    // Hiển thị thông tin người dùng khi bấm vào icon user
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thông Tin Người Dùng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tên: $displayName'),
            Text('Email: $email'),
            Text('Số Điện Thoại: $phoneNumber'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
Future<void> _showAddPersonalTaskDialog() async {
    final titleController = TextEditingController();
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm Công Việc Cá Nhân'),
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
  Future<void> _showAddGroupTaskDialog() async {
    final titleController = TextEditingController();
    final emailController = TextEditingController();
    Group? selectedGroup;
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay? selectedTime;
    List<Group> userGroups = [];
    List<Task> listTask = [];
    List<String> availableEmails = [];

    final groups = await _firestore
        .collection('groups')
        .where('leaderId', isEqualTo: widget.userId)
        .get();

    userGroups = groups.docs
        .map((doc) => Group.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Thêm Công Việc Nhóm'),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9, // Set max width
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Group Selection Row
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<Group>(
                            isExpanded: true, // Ensure dropdown doesn't overflow
                            value: selectedGroup,
                            hint: Text('Chọn Nhóm'),
                            items: userGroups.map((group) {
                              return DropdownMenuItem(
                                value: group,
                                child: Text(
                                  group.name,
                                  overflow: TextOverflow.ellipsis, // Handle long text
                                ),
                              );
                            }).toList(),
                            onChanged: (Group? value) {
                              setState(() {
                                selectedGroup = value;
                                emailController.clear();
                                if (value != null) {
                                  availableEmails = value.memberEmails;
                                } else {
                                  availableEmails = [];
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 4), // Reduced spacing
                        IconButton(
                          icon: Icon(Icons.add_circle, size: 24), // Adjusted size
                          padding: EdgeInsets.zero, // Remove padding
                          constraints: BoxConstraints(), // Remove constraints
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _showCreateGroupDialog();
                            _showAddGroupTaskDialog();
                          },
                          tooltip: 'Tạo Nhóm Mới',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Tên Công Việc'),
                  ),
                  SizedBox(height: 10),
                  // Email Selection Row
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true, // Ensure dropdown doesn't overflow
                            value: emailController.text.isEmpty ? null : emailController.text,
                            hint: Text('Chọn Email Thành Viên'),
                            items: availableEmails.map((email) {
                              return DropdownMenuItem(
                                value: email,
                                child: Text(
                                  email,
                                  overflow: TextOverflow.ellipsis, // Handle long text
                                ),
                              );
                            }).toList(),
                            onChanged: selectedGroup == null ? null : (String? value) {
                              if (value != null) {
                                setState(() {
                                  emailController.text = value;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              errorText: selectedGroup == null ? 'Vui lòng chọn nhóm trước' : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 4), // Reduced spacing
                        IconButton(
                          icon: Icon(Icons.person_add, size: 24), // Adjusted size
                          padding: EdgeInsets.zero, // Remove padding
                          constraints: BoxConstraints(), // Remove constraints
                          onPressed: selectedGroup == null
                              ? null
                              : () async {
                                  final currentGroup = selectedGroup!;
                                  Navigator.of(context).pop();
                                  await _showAddMemberToGroupDialog(currentGroup);
                                  _showAddGroupTaskDialog();
                                },
                          tooltip: 'Thêm Thành Viên Vào Nhóm',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  // Date Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Text(
                          'Chọn Ngày: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Time Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Text(selectedTime == null
                          ? 'Chọn Thời Gian'
                          : 'Thời gian: ${selectedTime!.format(context)}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    selectedTime != null &&
                    selectedGroup != null &&
                    emailController.text.isNotEmpty) {
                  if (selectedGroup!.memberEmails.contains(emailController.text)) {
                    final String? userIdNew =
                        await getUserIdByEmail(emailController.text);

                    final docRef = _firestore.collection('tasks').doc();
                    final taskId = docRef.id;
                    if (userIdNew != null) {
                      final task = Task(
                        id: taskId,
                        title: titleController.text,
                        time: selectedTime!,
                        userId: userIdNew,
                      );

                      _taskController.addTask(_selectedDay ?? _focusedDay, task);

                      listTask.add(task);
                      final taskGroup = GroupTask(
                        id: '',
                        groupId: selectedGroup!.id,
                        date: selectedDate,
                        assignedToEmail: emailController.text,
                        listTask: listTask,
                      );

                      final groupController = GroupController(userIdNew);
                      groupController.addGroupTask(taskGroup);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Thêm công việc nhóm thành công')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Không tìm thấy người dùng với email này')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Email không phải là thành viên của nhóm'),
                      ),
                    );
                  }
                }
              },
              child: Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }
Future<void> _showAddMemberToGroupDialog(Group group) async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm Thành Viên Vào Nhóm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Thành Viên Mới',
                hintText: 'Nhập email thành viên',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                // Add logic to update group members
                if (!group.memberEmails.contains(emailController.text)) {
                  final updatedEmails = [...group.memberEmails, emailController.text];
                  await _firestore.collection('groups').doc(group.id).update({
                    'memberEmails': updatedEmails,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm thành viên vào nhóm')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email đã tồn tại trong nhóm')),
                  );
                }
              }
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }
  Future<String?> getUserIdByEmail(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users') // Đảm bảo tên collection của bạn là 'users'
        .where('email', isEqualTo: email)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first['uid']; // Lấy uid từ document đầu tiên
    }

    return null; // Trả về null nếu không tìm thấy
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    List<String> memberEmails = [];
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Tạo Nhóm Mới'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Tên Nhóm'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Thành Viên',
                      hintText: 'Nhập email và nhấn thêm',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (emailController.text.isNotEmpty) {
                        setState(() {
                          memberEmails.add(emailController.text);
                          emailController.clear();
                        });
                      }
                    },
                    child: Text('Thêm Thành Viên'),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 100, // Giới hạn chiều cao của danh sách email
                    child: ListView(
                      children: memberEmails
                          .map((email) => Chip(
                                label: Text(email),
                                onDeleted: () {
                                  setState(() {
                                    memberEmails.remove(email);
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && memberEmails.isNotEmpty) {
                  final groupController = GroupController(widget.userId);
                  await groupController.createGroup(
                      nameController.text, memberEmails);
                  Navigator.pop(context);
                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tạo nhóm thành công')),
                  );
                }
              },
              child: Text('Tạo Nhóm'),
            ),
          ],
        ),
      ),
    );
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
          PopupMenuButton<int>(
            icon: Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 1) {
                _showUserInfoDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text('Thông Tin Người Dùng'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 2 ? FloatingActionButton(
       onPressed: () async {
          await showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Thêm Task Cá Nhân'),
                  onTap: () {
                    Navigator.pop(context); // Đóng bottom sheet
                    _showAddPersonalTaskDialog(); // Mở hộp thoại task cá nhân
                  },
                ),
                ListTile(
                  leading: Icon(Icons.group),
                  title: Text('Thêm Task Nhóm'),
                  onTap: () {
                    Navigator.pop(context); // Đóng bottom sheet
                    _showAddGroupTaskDialog(); // Mở hộp thoại task nhóm
                  },
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ) : null,
    );
  }
}