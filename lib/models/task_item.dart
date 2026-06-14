import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskCategory {
  personal('personal', 'Personal'),
  work('work', 'Work');

  const TaskCategory(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static TaskCategory fromStorage(String? value) {
    return TaskCategory.values.firstWhere(
      (category) => category.storageValue == value,
      orElse: () => TaskCategory.personal,
    );
  }
}

DateTime normalizeTaskDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String taskDateKeyFromDate(DateTime date) {
  final normalizedDate = normalizeTaskDate(date);
  final year = normalizedDate.year.toString().padLeft(4, '0');
  final month = normalizedDate.month.toString().padLeft(2, '0');
  final day = normalizedDate.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
    required this.scheduledDate,
  });

  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime scheduledDate;

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? scheduledDate,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }

  factory TaskItem.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    final createdAtDate = createdAt is Timestamp
        ? createdAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final scheduledDate = data['taskDate'];
    final taskDate = scheduledDate is Timestamp
        ? normalizeTaskDate(scheduledDate.toDate())
        : normalizeTaskDate(createdAtDate);

    return TaskItem(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      category: TaskCategory.fromStorage(data['category'] as String?),
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: createdAtDate,
      scheduledDate: taskDate,
    );
  }
}
