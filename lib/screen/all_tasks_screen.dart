import 'package:flutter/material.dart';
import '../models/task.dart';
import '../controller/task_controller.dart';

class AllTasksScreen extends StatelessWidget {
  final TaskController taskController;

  AllTasksScreen({required this.taskController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Tasks'),
      ),
      body: StreamBuilder<Map<DateTime, List<Task>>>(
        stream: taskController.getTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks available.'));
          }

          final tasks = snapshot.data!;
          final allTasks = tasks.values.expand((taskList) => taskList).toList();

          return ListView.builder(
            itemCount: allTasks.length,
            itemBuilder: (context, index) {
              final task = allTasks[index];
              return ListTile(
                leading: Icon(Icons.work),
                title: Text(task.title),
                subtitle: Text('Giờ: ${task.time.hour}:${task.time.minute}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => taskController.deleteTask(task),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
