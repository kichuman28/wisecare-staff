import 'package:flutter/material.dart';

class TaskProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _tasks = [];
  
  List<Map<String, dynamic>> get tasks => _tasks;
  
  int get pendingTasksCount => _tasks.where((task) => task['status'] == 'pending').length;
  int get inProgressTasksCount => _tasks.where((task) => task['status'] == 'in_progress').length;
  int get completedTasksCount => _tasks.where((task) => task['status'] == 'completed').length;

  void addTask(Map<String, dynamic> task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTaskStatus(String taskId, String status) {
    final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex]['status'] = status;
      notifyListeners();
    }
  }
} 