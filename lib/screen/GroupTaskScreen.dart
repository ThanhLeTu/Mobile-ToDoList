// // group_task_screen.dart
// import 'package:do_an/controller/group_controller.dart';
// import 'package:do_an/models/group_task.dart';
// import 'package:flutter/material.dart';

// class GroupTaskScreen extends StatefulWidget {
//   final String userId;
//   final String groupId;

//   GroupTaskScreen({required this.userId, required this.groupId});

//   @override
//   _GroupTaskScreenState createState() => _GroupTaskScreenState();
// }

// class _GroupTaskScreenState extends State<GroupTaskScreen> {
//   late GroupTaskController _taskController;
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _taskController = GroupTaskController(widget.userId);
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Quản Lý Công Việc Nhóm'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: [
//             Tab(text: 'Tất Cả'),
//             Tab(text: 'Việc Của Tôi'),
//             Tab(text: 'Thống Kê'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildAllTasksTab(),
//           _buildMyTasksTab(),
//           _buildStatsTab(),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddTaskDialog,
//         child: Icon(Icons.add),
//       ),
//     );
//   }

//   // Tab hiển thị tất cả công việc của nhóm
//   Widget _buildAllTasksTab() {
//     return StreamBuilder<List<GroupTask>>(
//       stream: _taskController.getGroupTasks(widget.groupId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(child: Text('Chưa có công việc nào'));
//         }

//         return ListView.builder(
//           itemCount: snapshot.data!.length,
//           itemBuilder: (context, index) {
//             final task = snapshot.data![index];
//             return _buildTaskCard(task);
//           },
//         );
//       },
//     );
//   }

//   // Tab hiển thị công việc được giao cho user hiện tại
//   Widget _buildMyTasksTab() {
//     return StreamBuilder<List<GroupTask>>(
//       stream: _taskController.getUserAssignedTasks(widget.userId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(child: Text('Bạn chưa được giao việc nào'));
//         }

//         return ListView.builder(
//           itemCount: snapshot.data!.length,
//           itemBuilder: (context, index) {
//             final task = snapshot.data![index];
//             return _buildTaskCard(task, showActions: true);
//           },
//         );
//       },
//     );
//   }

//   // Tab hiển thị thống kê
//   Widget _buildStatsTab() {
//     return FutureBuilder<Map<String, dynamic>>(
//       future: _taskController.getGroupTaskStats(widget.groupId),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Center(child: CircularProgressIndicator());
//         }

//         final stats = snapshot.data!;
//         return Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildStatCard(
//                 'Tổng số công việc',
//                 stats['totalTasks'].toString(),
//                 Colors.blue,
//               ),
//               SizedBox(height: 16),
//               _buildStatCard(
//                 'Đã hoàn thành',
//                 stats['completedTasks'].toString(),
//                 Colors.green,
//               ),
//               SizedBox(height: 16),
//               _buildStatCard(
//                 'Chưa hoàn thành',
//                 stats['pendingTasks'].toString(),
//                 Colors.orange,
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Widget hiển thị task
//   Widget _buildTaskCard(GroupTask task, {bool showActions = false}) {
//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: ListTile(
//         title: Text(task.title),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Ngày: ${task.date.day}/${task.date.month}/${task.date.year}',
//             ),
//             Text(
//               'Thời gian: ${task.time.format(context)}',
//             ),
//             Text('Giao cho: ${task.assignedToEmail}'),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Checkbox(
//               value: task.isCompleted,
//               onChanged: showActions
//                   ? (value) {
//                       if (value != null) {
//                         _taskController.updateTaskCompletion(task.id, value);
//                       }
//                     }
//                   : null,
//             ),
//             if (showActions)
//               IconButton(
//                 icon: Icon(Icons.delete),
//                 onPressed: () => _showDeleteConfirmation(task),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget hiển thị thống kê
//   Widget _buildStatCard(String title, String value, Color color) {
//     return Card(
//       color: color.withOpacity(0.1),
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Dialog thêm task mới
//   Future<void> _showAddTaskDialog() async {
//     final titleController = TextEditingController();
//     final emailController = TextEditingController();
//     DateTime selectedDate = DateTime.now();
//     TimeOfDay? selectedTime;

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: Text('Thêm Công Việc Mới'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: titleController,
//                   decoration: InputDecoration(labelText: 'Tên Công Việc'),
//                 ),
//                 SizedBox(height: 16),
//                 TextField(
//                   controller: emailController,
//                   decoration: InputDecoration(labelText: 'Email Người Được Giao'),
//                 ),
//                 SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final date = await showDatePicker(
//                       context: context,
//                       initialDate: selectedDate,
//                       firstDate: DateTime.now(),
//                       lastDate: DateTime(2100),
//                     );
//                     if (date != null) {
//                       setState(() => selectedDate = date);
//                     }
//                   },
//                   child: Text(
//                     'Chọn Ngày: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final time = await showTimePicker(
//                       context: context,
//                       initialTime: TimeOfDay.now(),
//                     );
//                     if (time != null) {
//                       setState(() => selectedTime = time);
//                     }
//                   },
//                   child: Text(
//                     selectedTime == null
//                         ? 'Chọn Thời Gian'
//                         : 'Thời gian: ${selectedTime!.format(context)}',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Hủy'),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (titleController.text.isNotEmpty &&
//                     emailController.text.isNotEmpty &&
//                     selectedTime != null) {
//                   final task = GroupTask(
//                     id: '',
//                     groupId: widget.groupId,
//                     title: titleController.text,
//                     date: selectedDate,
//                     time: selectedTime!,
//                     assignedToEmail: emailController.text,
//                   );
//                   _taskController.addGroupTask(task);
//                   Navigator.pop(context);
//                 }
//               },
//               child: Text('Thêm'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Dialog xác nhận xóa task
//   Future<void> _showDeleteConfirmation(GroupTask task) async {
//     return showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Xác Nhận Xóa'),
//         content: Text('Bạn có chắc muốn xóa công việc này?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Hủy'),
//           ),
//           TextButton(
//             onPressed: () {
//               _taskController.deleteTask(task.id);
//               Navigator.pop(context);
//             },
//             child: Text('Xóa'),
//           ),
//         ],
//       ),
//     );
//   }
// }