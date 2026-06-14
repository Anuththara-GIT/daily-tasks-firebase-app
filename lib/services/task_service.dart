import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/task_item.dart';

abstract class TaskService {
  Stream<List<TaskItem>> watchTasksForDate(DateTime selectedDate);

  Stream<Set<String>> watchTaskDateKeys();

  Future<void> addTask({
    required String title,
    required String description,
    required TaskCategory category,
    required DateTime scheduledDate,
  });

  Future<void> toggleTask(TaskItem task);

  Future<void> deleteTask(String taskId);
}

class TaskServiceException implements Exception {
  const TaskServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseTaskService implements TaskService {
  FirebaseTaskService({required String userId, FirebaseFirestore? firestore})
    : _userId = userId,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;
  static const Duration _writeTimeout = Duration(seconds: 12);

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('users').doc(_userId).collection('daily_tasks');

  @override
  Stream<Set<String>> watchTaskDateKeys() {
    return _tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => (doc.data()['taskDateKey'] as String?)?.trim())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toSet();
    });
  }

  @override
  Stream<List<TaskItem>> watchTasksForDate(DateTime selectedDate) {
    final dateKey = taskDateKeyFromDate(selectedDate);
    return _tasksCollection
        .where('taskDateKey', isEqualTo: dateKey)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs.map(TaskItem.fromDocument).toList();
          return _sortTasks(tasks);
        });
  }

  @override
  Future<void> addTask({
    required String title,
    required String description,
    required TaskCategory category,
    required DateTime scheduledDate,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return;
    }

    final now = Timestamp.now();
    final normalizedDate = normalizeTaskDate(scheduledDate);
    await _runWrite(
      _tasksCollection.add({
        'title': cleanTitle,
        'description': description.trim(),
        'category': category.storageValue,
        'isCompleted': false,
        'taskDate': Timestamp.fromDate(normalizedDate),
        'taskDateKey': taskDateKeyFromDate(normalizedDate),
        'createdAt': now,
        'updatedAt': now,
      }),
      action: 'save this task',
    );
  }

  @override
  Future<void> toggleTask(TaskItem task) {
    return _runWrite(
      _tasksCollection.doc(task.id).update({
        'isCompleted': !task.isCompleted,
        'updatedAt': Timestamp.now(),
      }),
      action: 'update this task',
    );
  }

  @override
  Future<void> deleteTask(String taskId) {
    return _runWrite(
      _tasksCollection.doc(taskId).delete(),
      action: 'delete this task',
    );
  }

  List<TaskItem> _sortTasks(List<TaskItem> tasks) {
    return tasks..sort((left, right) {
      if (left.isCompleted != right.isCompleted) {
        return left.isCompleted ? 1 : -1;
      }

      if (left.category != right.category) {
        return left.category == TaskCategory.work ? -1 : 1;
      }

      return right.createdAt.compareTo(left.createdAt);
    });
  }

  Future<void> _runWrite(
    Future<void> operation, {
    required String action,
  }) async {
    try {
      await operation.timeout(_writeTimeout);
    } on TimeoutException {
      throw TaskServiceException(_timeoutMessage(action));
    } on FirebaseException catch (error) {
      throw TaskServiceException(_firebaseErrorMessage(error, action));
    } catch (_) {
      throw TaskServiceException(
        'We could not $action right now. Please try again.',
      );
    }
  }

  String _timeoutMessage(String action) {
    if (kIsWeb) {
      return 'Saving is taking too long. Your browser app is not finishing '
          'the Firestore sync yet. Check that Firestore Database is created '
          'and that the Firebase Web app configuration is correct.';
    }

    return 'We could not $action right now. Please check your connection and '
        'try again.';
  }

  String _firebaseErrorMessage(FirebaseException error, String action) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore blocked this request. Put Firestore rules in test '
            'mode or allow this app to write to the daily_tasks collection.';
      case 'failed-precondition':
        return 'Firestore is not fully ready yet. Create Firestore Database '
            'in Firebase Console and make sure this app is registered '
            'correctly for the current platform.';
      case 'unavailable':
        return 'Firestore is unavailable right now. Check your internet '
            'connection and try again.';
      default:
        return 'We could not $action right now. Firebase said: '
            '${error.message ?? error.code}.';
    }
  }
}

class LocalTaskService implements TaskService {
  final StreamController<void> _tasksController =
      StreamController<void>.broadcast();
  final List<TaskItem> _tasks = <TaskItem>[];

  @override
  Stream<Set<String>> watchTaskDateKeys() {
    return Stream<Set<String>>.multi((controller) {
      controller.add(_taskDateKeys());
      final subscription = _tasksController.stream.listen(
        (_) => controller.add(_taskDateKeys()),
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<List<TaskItem>> watchTasksForDate(DateTime selectedDate) {
    final dateKey = taskDateKeyFromDate(selectedDate);
    return Stream<List<TaskItem>>.multi((controller) {
      controller.add(_sortedTasksForDate(dateKey));
      final subscription = _tasksController.stream.listen(
        (_) => controller.add(_sortedTasksForDate(dateKey)),
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> addTask({
    required String title,
    required String description,
    required TaskCategory category,
    required DateTime scheduledDate,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return;
    }

    final now = DateTime.now();
    _tasks.add(
      TaskItem(
        id: now.microsecondsSinceEpoch.toString(),
        title: cleanTitle,
        description: description.trim(),
        category: category,
        isCompleted: false,
        createdAt: now,
        scheduledDate: normalizeTaskDate(scheduledDate),
      ),
    );
    _emitTasks();
  }

  @override
  Future<void> toggleTask(TaskItem task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      return;
    }

    _tasks[index] = _tasks[index].copyWith(
      isCompleted: !_tasks[index].isCompleted,
    );
    _emitTasks();
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    _emitTasks();
  }

  void _emitTasks() {
    _tasksController.add(null);
  }

  List<TaskItem> _sortedTasksForDate(String dateKey) {
    final tasks = _tasks
        .where((task) => taskDateKeyFromDate(task.scheduledDate) == dateKey)
        .toList();
    return tasks..sort((left, right) {
      if (left.isCompleted != right.isCompleted) {
        return left.isCompleted ? 1 : -1;
      }

      if (left.category != right.category) {
        return left.category == TaskCategory.work ? -1 : 1;
      }

      return right.createdAt.compareTo(left.createdAt);
    });
  }

  Set<String> _taskDateKeys() {
    return _tasks
        .map((task) => taskDateKeyFromDate(task.scheduledDate))
        .toSet();
  }
}
