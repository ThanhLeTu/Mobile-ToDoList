import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/group_task.dart';

class GroupController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  GroupController(this.userId);

  // Create a new group
  Future<void> createGroup(String name, List<String> memberEmails) async {
       final docRef = _firestore.collection('tasks').doc();
                 final groupId = docRef.id;  
    final group = Group(
      id: groupId,
      name: name,
      leaderId: userId,
      memberEmails: memberEmails,
    );

    await _firestore.collection('groups').add(group.toMap());
  }

  // Get groups where user is leader or member
  Stream<List<Group>> getUserGroups(String userEmail) {
    return _firestore
        .collection('groups')
        .where('memberEmails', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Add group task
  Future<void> addGroupTask(GroupTask task) async {
    try {
      await _firestore.collection('groupTasks').add(task.toMap());
      print("Group task added successfully.");
    } catch (e) {
      print("Failed to add group task: $e");
    }
  }

  // Get group tasks for a specific user
  Stream<List<GroupTask>> getGroupTasksForUser(String userEmail) {
    return _firestore
        .collection('groupTasks')
        .where('assignedToEmail', isEqualTo: userEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupTask.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Update task completion status
  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    await _firestore
        .collection('groupTasks')
        .doc(taskId)
        .update({'isCompleted': isCompleted});
  }

  // Delete group task
  Future<void> deleteGroupTask(String taskId) async {
    await _firestore.collection('groupTasks').doc(taskId).delete();
  }

  
}

