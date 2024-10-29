import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quality_task/module/models/tasks.dart';

class FireStoreService {
  String userId;
  FireStoreService() : userId = FirebaseAuth.instance.currentUser!.uid;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTask(TaskModel taskModel) async {
   return await _firestore
    .collection(userId)
    .doc(taskModel.id)
    .set(taskModel.toMap());
  }

  Future<void> updateTask(TaskModel taskModel) async {
    await _firestore
      .collection(userId)
      .doc(taskModel.id)
      .update(taskModel.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(userId).doc(taskId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> connectStreamTasks() {
    return _firestore.collection(userId).snapshots();
  }
}