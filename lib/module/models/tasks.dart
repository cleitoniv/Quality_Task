class TaskModel {
  String id;
  String uid;
  String tarefa;
  String data;
  bool isDone;

  TaskModel({
    required this.id,
    required this.uid,
    required this.tarefa,
    required this.data,
    required this.isDone,  
  });

  TaskModel.fromMap(Map<String, dynamic> map) :
    id = map["id"],
    uid = map["uid"],
    tarefa = map["tarefa"],
    data = map["data"],
    isDone = map["isDone"] ?? false;

  Map<String, dynamic> toMap() {
    return {
     "id": id,
     "uid": uid,
     "tarefa": tarefa,
     "data": data,
     "isDone": isDone
     };
  }
}