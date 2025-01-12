// import 'package:do_an/controller/group_controller.dart';
// import 'package:do_an/models/group_task.dart';
// import 'package:flutter/material.dart';

// class UserGroupTasksList extends StatelessWidget {
//   final String userEmail;
//   // final GroupTaskController controller;

//   UserGroupTasksList({
//     required this.userEmail,
//     required this.controller,
//   });



//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<List<GroupTask>>(
//       stream: controller.getUserAssignedTasks(userEmail),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(child: Text('Không có công việc nào'));
//         }

//         return ListView.builder(
//           itemCount: snapshot.data!.length,
//           itemBuilder: (context, index) {
//             final task = snapshot.data![index];
//             return Card(
//               child: ListTile(
//                 title: Text(task.title),
//                 subtitle: Text(
//                   '${task.date.day}/${task.date.month}/${task.date.year} ${task.time.format(context)}'
//                 ),
//                 trailing: Checkbox(
//                   value: task.isCompleted,
//                   onChanged: (bool? value) {
//                     if (value != null) {
//                       controller.updateTaskCompletion(task.id, value);
//                     }
//                   },
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }