import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudapp/models/todo_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controllerDescription = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('CRUD App'),
      ),
      body: ListView(
        children: [inputBar(), getTodos()],
      ),
    );
  }

  Container inputBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: const Color(0xff1D1617).withOpacity(0.11),
          blurRadius: 40,
          spreadRadius: 0.0,
        )
      ]),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(15),
          hintText: "Add your today's task here ...",
          hintStyle: const TextStyle(color: Color(0xffDDDADA), fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        textInputAction: TextInputAction.go,
        controller: controllerDescription,
        onChanged: (value) {
          // Update the UI when user types
          setState(() {});
        },
        onSubmitted: (value) {
          createTodo(description: value, isCompleted: false);
          controllerDescription.clear();
        },
      ),
    );
  }

  Widget buildTodo(Todo todo) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xff1D1617).withOpacity(0.07),
                    offset: const Offset(0, 10),
                    blurRadius: 20,
                    spreadRadius: 0)
              ]),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 100,
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Checkbox(
                                  key: UniqueKey(),
                                  value: todo.isCompleted,
                                  activeColor: Colors.green,
                                  onChanged: (val) {
                                    setState(() {
                                      todo.isCompleted = val!;
                                      markAsDone(todo.id, todo.isCompleted);
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 30,
                                ),
                                Text(
                                  todo.description,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 18,
                                    decoration: todo.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ]),
                        ),
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onTap: () {
                                  _editTodoDialog(todo);
                                },
                              ),
                              SizedBox(
                                width: 30,
                              ),
                              GestureDetector(
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onTap: () {
                                  _deleteTodoDialog(todo);
                                },
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );

  StreamBuilder<List<Todo>> getTodos() {
    return StreamBuilder<List<Todo>>(
        stream: readTodos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong!!');
          } else if (snapshot.hasData) {
            final todos = snapshot.data!;

            final filteredTodos = todos
                .where((todo) => todo.description
                    .toLowerCase()
                    .contains(controllerDescription.text.toLowerCase()))
                .toList();

            return ListView(
                shrinkWrap: true,
                children: filteredTodos.map(buildTodo).toList());
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

// Create
  Future createTodo({required String description, isCompleted}) async {
    final isDuplicated = await isDuplicatedTodo(description);

    if (description.trim().isEmpty) {
      _alertEmpty();
      return;
    }

    if (isDuplicated) {
      _alertDuplicate();
    } else {
      final docTodo = FirebaseFirestore.instance.collection('todos').doc();
      final todo = Todo(
        id: docTodo.id,
        description: description,
        isCompleted: isCompleted,
      );

      final json = todo.toJson();

      await docTodo.set(json);
    }
  }

  Future<bool> isDuplicatedTodo(String description) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('todos')
        .where('description', isEqualTo: description)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return true;
    }
    return false;
  }

  void _alertDuplicate() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Warning!!!'),
            content: const Text('Duplicate todo is not allowed'),
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          );
        });
  }

   void _alertEmpty() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Warning!!!'),
            content: const Text('Empty todo is not allowed'),
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          );
        });
  }

// Read
  Stream<List<Todo>> readTodos() => FirebaseFirestore.instance
      .collection('todos')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Todo.fromJson(doc.data())).toList());

// Update
  void updateTodo(String todoId, String newDescription) {
    FirebaseFirestore.instance
        .collection('todos')
        .doc(todoId)
        .update({'description': newDescription});
  }

  void markAsDone(String todoId, bool isCompleted) {
    FirebaseFirestore.instance
        .collection('todos')
        .doc(todoId)
        .update({'isCompleted': isCompleted});
  }

  void _editTodoDialog(Todo todo) {
    TextEditingController controller =
        TextEditingController(text: todo.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Todo'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New Description'),
          ),
          actions: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  updateTodo(todo.id, controller.text);
                  Navigator.pop(context);
                },
                child: const Text('Update')),
          ],
        );
      },
    );
  }

// Delete
  void deleteTodo(String todoId) {
    FirebaseFirestore.instance.collection('todos').doc(todoId).delete();
  }

  void _deleteTodoDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Todo'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.amber,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  deleteTodo(todo.id);
                  Navigator.pop(context);
                },
                child: const Text('Delete')),
          ],
        );
      },
    );
  }
}
