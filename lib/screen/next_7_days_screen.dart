import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controller/task_controller.dart';
import '../models/task.dart';
import 'dart:async'; 

class Next7DaysScreen extends StatefulWidget {
  final TaskController taskController;
  Next7DaysScreen({required this.taskController});
  @override
  _Next7DaysScreenState createState() => _Next7DaysScreenState();
}

class _Next7DaysScreenState extends State<Next7DaysScreen> {
  DateTime? _expandedDay;
  Map<String, bool> _taskCompletionStatus = {};
  late Timer _timer;
  
  @override
  void initState() {
  super.initState();
  initializeDateFormatting('vi_VN', null);
  // Cập nhật mỗi phút và kiểm tra ngày mới
  _timer = Timer.periodic(Duration(minutes: 1), (timer) {
    final now = DateTime.now();
    setState(() {
      // Cập nhật lại danh sách task khi qua ngày mới
      if (_expandedDay != null && !isSameDay(now, _expandedDay!)) {
        _expandedDay = now;
        // Trigger rebuild để cập nhật danh sách ngày và task
      }
    });
  });
}

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF7C4DFF),
        title: Text(
          '7 Ngày Tới',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: StreamBuilder<Map<DateTime, List<Task>>>(
        stream: widget.taskController.getTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Color(0xFF7C4DFF).withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có việc cần làm',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data!;
          final now = DateTime.now();
          final next7Days = List.generate(7, (index) => DateTime(now.year, now.month, now.day + index));

          return AnimationLimiter(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: next7Days.length,
              itemBuilder: (context, index) {
                final day = next7Days[index];
                final dayTasks = tasks[DateTime(day.year, day.month, day.day)] ?? [];
                final isExpanded = _expandedDay != null && isSameDay(day, _expandedDay!);

                dayTasks.sort((a, b) {
                  final aCompleted = _taskCompletionStatus[a.id] ?? false;
                  final bCompleted = _taskCompletionStatus[b.id] ?? false;
                  return aCompleted ? 1 : (bCompleted ? -1 : 0);
                });

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
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            title: Text(
                              index == 0 ? 'Hôm Nay' : DateFormat('EEEE','vi_VN').format(day),//hiển thị ngày
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C4DFF),
                              ),
                            ),
                            initiallyExpanded: isExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _expandedDay = expanded ? day : null;
                              });
                            },
                            children: dayTasks.isEmpty
                                ? [
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'Hôm nay không có nhiệm vu nào',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ]
                                : dayTasks.map((task) {
                                    final isCompleted = _taskCompletionStatus[task.id] ?? false;
                                    return AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: isCompleted ? Colors.grey[100] : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: ListTile(
                                        leading: Transform.scale(
                                          scale: 1.2,
                                          child: Checkbox(
                                            value: isCompleted,
                                            activeColor: Color(0xFF7C4DFF),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                _taskCompletionStatus[task.id] = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                        title: Text(
                                          task.title,
                                          style: TextStyle(
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: isCompleted
                                                ? Colors.grey[500]
                                                : Colors.grey[800],
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${task.time.format(context)}',
                                          style: TextStyle(
                                            color: isCompleted
                                                ? Colors.grey[400]
                                                : Color(0xFF7C4DFF),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
//so sánh ngày
  bool isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year && day1.month == day2.month && day1.day == day2.day;
  }
}