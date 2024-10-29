import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quality_task/module/auth/Authenticate_screen.dart';
import 'package:quality_task/module/models/tasks.dart';
import 'package:quality_task/module/services/fire_store_service.dart';
import 'package:uuid/uuid.dart';

class Task {
  bool isDone;
  Task({ this.isDone = false});
}

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  HomePageScreenState createState() => HomePageScreenState();
}

class HomePageScreenState extends State<HomePageScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  late bool isLoading;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();
  // String userImage = "https://www.webposto.com.br/assets/logos/webposto/logo-webposto-bomba-branca-01-small.webp";
  String userImage = "";
  List<TaskModel> tasks = [];
  final FireStoreService fireStoreService = FireStoreService();

  String _todayDate() {
   DateTime dataAtual = DateTime.now();
    String formattedDate = "${dataAtual.day}/${dataAtual.month}/${dataAtual.year}";
    return formattedDate;
  }
  void _addTask(String newTask) {
    String id = const Uuid().v1();
    String uid = user!.uid;
    String tarefa = newTask;
    String data = _todayDate();
    bool isDone = false;
    TaskModel task = TaskModel(id: id, uid: uid, tarefa: tarefa, data: data, isDone: isDone);
    
    fireStoreService.addTask(task).then((value) {});
  }

  void _editTask(TaskModel task, String newTitle) {
      fireStoreService.updateTask(TaskModel(
        tarefa: newTitle,
        id: task.id,
        uid: task.uid,
        data: task.data,
        isDone: task.isDone,
      )
    );
  }

  void _deleteTask(TaskModel task) async {
    fireStoreService.deleteTask(task.id).then((_) {
       tasks.remove(task);
    });
  }

  void _toggleCheckbox(TaskModel task) {
    fireStoreService.updateTask(
      TaskModel(
        tarefa: task.tarefa,
        id: task.id,
        uid: task.uid,
        data: task.data,
        isDone: task.isDone == true ? task.isDone = false : task.isDone = true
      )
    );
  }

  void _showAddTaskDialog() {
    String taskTitle = "";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Adicionar Tarefa"),
          content: TextFormField(
          onChanged: (value) {
            taskTitle = value;
            
          },
          controller: TextEditingController(text: taskTitle),
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "Escreva aqui",
            border: OutlineInputBorder(),
          ),
        ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Adicionar"),
              onPressed: () {
                if (taskTitle.isNotEmpty) {
                  _addTask(taskTitle);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(TaskModel task) { 
  String newTitle = task.tarefa;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Editar Tarefa"),
        content: TextFormField(
          onChanged: (value) {
            newTitle = value;
          },
          keyboardType: TextInputType.text,
          controller: TextEditingController(text: task.tarefa),
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "Digite a tarefa",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar", 
                style: TextStyle(
                color: Color.fromARGB(255, 20, 1, 126)
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("Salvar",
              style: TextStyle(
              color: Color.fromARGB(255, 20, 1, 126)
              ),
            ),
            onPressed: () {
              _editTask(task, newTitle);
              Navigator.of(context).pop();
            },
          ),
        ],
       );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Salvar imagem no Firebase Storage
      String fileName = 'profile_${user?.uid}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('profile_images').child(fileName);
      await ref.putFile(imageFile);

      // Obter a URL da imagem e atualizar o photoURL do usuário
      String downloadURL = await ref.getDownloadURL();
      await user?.updatePhotoURL(downloadURL);
      await user?.reload();  // Recarregar usuário para refletir a atualização

      // Atualizar a interface
      setState(() {
        userImage = downloadURL;
        user = FirebaseAuth.instance.currentUser;
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Escolha uma opção"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Tirar foto"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Escolher da galeria"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthenticateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    inspect(user);
    List<TaskModel> taskList = [];
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 20, 1, 126),
      appBar: AppBar(
        elevation: 5.0,
        toolbarHeight: 80,
        title: const Text(
          'Lista de Tarefas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            inspect(user);
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 236, 8, 0),  
                Color.fromARGB(255, 20, 1, 126)
                ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName:  Text("Olá, ${user?.displayName}",), 
              accountEmail:  Text("${(user?.email != null) ? user?.email! : ""} "),
              currentAccountPicture: GestureDetector(
              onTap: _showImageSourceDialog,
              child: 
              user?.photoURL != null ?  
              CircleAvatar(
                backgroundImage: NetworkImage(
                  user?.photoURL as String
                ) ,
                child: null,
                // user?.photoURL != null ? null : const Icon(Icons.add_a_photo_sharp, size: 25),
              ) 
              : 
              const CircleAvatar(
                child:  
                  Icon(
                    Icons.add_a_photo_sharp, 
                    size: 25
                  ),
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 236, 8, 0),  
                    Color.fromARGB(255, 20, 1, 126)
                    ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color.fromARGB(255, 20, 1, 126)),
              title: const Text("Sair", style: TextStyle(fontSize: 16)),
              onTap: () {
                _logout();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: fireStoreService.connectStreamTasks(), builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          taskList.clear();
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          for (var i in snapshot.data!.docs) {
            final data = i.data();
            taskList.add(TaskModel.fromMap(data as Map<String, dynamic>));
          }
          inspect(taskList);
          if (snapshot.connectionState != ConnectionState.active) {  
            inspect(snapshot);
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
              return
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: 
                ListView.builder(
                  itemCount: taskList.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                      ListTile( 
                        title: Text(
                            taskList[index].tarefa,
                            style: TextStyle(
                              fontSize: 18,
                              decoration: taskList[index].isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        subtitle: 
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Data da Inclusão: ${taskList[index].data}",
                            style: const TextStyle(color: Color.fromARGB(255, 71, 70, 70)), 
                          ),
                        ),
                        ),
                        ListTile(
                          title: 
                          GestureDetector(
                            onTap: () {
                              _toggleCheckbox(taskList[index]);
                              },
                            child: Container(
                              height: 35,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color.fromARGB(255, 20, 1, 126))
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      checkColor: Colors.green,
                                      activeColor: Colors.white,
                                      value: taskList[index].isDone,
                                      onChanged: (bool? value) {
                                        _toggleCheckbox(taskList[index]);
                                      },
                                    ),
                                    const Text("Concluida"),
                                    const SizedBox(width: 15,)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  print(taskList[index]);
                                  _showEditTaskDialog(taskList[index]);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteTask(taskList[index]);
                                },
                              ),
                            ],
                          ),
                        ),
                      const Divider(color: Colors.black,)
                      ],
                    );
                  },
                ),
              );
            } else {
                return
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: const Center(child: Text("Parece que você não tem tarefas a fazer! 😥"),
                  )
                );
            }
        }
      ),
      floatingActionButton: ElevatedButton(
        style: ElevatedButton.styleFrom(fixedSize: const Size(180, 34)),
        onPressed: _showAddTaskDialog,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Adicionar tarefa",
              style: TextStyle(
                color: Colors.black
              ),
              ),
            SizedBox(width: 5,),
            Icon(Icons.add, color: Color.fromARGB(255, 20, 1, 126),),
          ],
        ),
      ),
    );
  }
}