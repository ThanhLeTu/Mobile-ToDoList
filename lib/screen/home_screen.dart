import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/controller/group_controller.dart';
import 'package:do_an/models/group.dart';
import 'package:do_an/models/group_task.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../controller/task_controller.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../screen/login_screen.dart';

class CalendarScreen extends StatefulWidget {
  final String userId;
  // Danh sách task nhóm

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

/////

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
      ),
    );
  }
}
