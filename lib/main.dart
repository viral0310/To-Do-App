import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MyApp(),
  );
}

class Task {
  String title;
  bool completed;

  Task(this.title, {this.completed = false});
}

class TaskViewModel extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  TaskViewModel() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? taskTitles = prefs.getStringList('tasks');
    if (taskTitles != null) {
      _tasks.addAll(taskTitles.map((title) => Task(title)));
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> taskTitles = _tasks.map((task) => task.title).toList();
    await prefs.setStringList('tasks', taskTitles);
  }

  void addTask(String title) {
    _tasks.add(Task(title));
    _saveTasks();
    notifyListeners();
  }

  void toggleTask(int index) {
    _tasks[index].completed = !_tasks[index].completed;
    _saveTasks();
    notifyListeners();
  }

  void deleteTask(int index) {
    _tasks.removeAt(index);
    _saveTasks();
    notifyListeners();
  }

  void editTask(int index, String newTitle) {
    _tasks[index].title = newTitle;
    _saveTasks();
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskViewModel(),
      child: MaterialApp(
        title: 'To-Do List',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        home: ToDoListPage(),
      ),
    );
  }
}

class ToDoListPage extends StatelessWidget {
  final TextEditingController _taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final taskViewModel = Provider.of<TaskViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'To-Do List',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: taskViewModel.tasks.length,
                  itemBuilder: (context, index) {
                    final task = taskViewModel.tasks[index];
                    return ListTile(
                      onTap: () {
                        _showEditTaskDialog(context, taskViewModel, index);
                      },
                      leading: Checkbox(
                        value: task.completed,
                        onChanged: (_) => taskViewModel.toggleTask(index),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => taskViewModel.deleteTask(index),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: const InputDecoration(
                        hintText: 'Enter task',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final value = _taskController.text;
                      if (value.isNotEmpty) {
                        taskViewModel.addTask(value);
                        _taskController.clear();
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(
      BuildContext context, TaskViewModel taskViewModel, int index) {
    final TextEditingController _editTaskController =
        TextEditingController(text: taskViewModel.tasks[index].title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: _editTaskController,
            decoration: const InputDecoration(hintText: 'Enter new task title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = _editTaskController.text;
                if (newValue.isNotEmpty) {
                  taskViewModel.editTask(index, newValue);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
