import 'package:daily_tasks_app/models/task_item.dart';
import 'package:daily_tasks_app/services/task_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LocalTaskService filters tasks by selected date', () async {
    final service = LocalTaskService();
    final today = DateTime(2026, 6, 13);
    final tomorrow = DateTime(2026, 6, 14);

    await service.addTask(
      title: 'Buy groceries',
      description: 'Milk, eggs, and fruit',
      category: TaskCategory.personal,
      scheduledDate: today,
    );
    await service.addTask(
      title: 'Prepare weekly report',
      description: 'Send final summary to the team',
      category: TaskCategory.work,
      scheduledDate: tomorrow,
    );

    final todayTasks = await service.watchTasksForDate(today).first;
    final tomorrowTasks = await service.watchTasksForDate(tomorrow).first;

    expect(todayTasks, hasLength(1));
    expect(todayTasks.single.title, 'Buy groceries');
    expect(todayTasks.single.description, 'Milk, eggs, and fruit');
    expect(todayTasks.single.category, TaskCategory.personal);

    expect(tomorrowTasks, hasLength(1));
    expect(tomorrowTasks.single.title, 'Prepare weekly report');
    expect(tomorrowTasks.single.category, TaskCategory.work);
  });

  test(
    'LocalTaskService keeps incomplete tasks ahead of completed ones',
    () async {
      final service = LocalTaskService();
      final selectedDate = DateTime(2026, 6, 13);

      await service.addTask(
        title: 'Call supplier',
        description: '',
        category: TaskCategory.work,
        scheduledDate: selectedDate,
      );
      await service.addTask(
        title: 'Morning walk',
        description: '',
        category: TaskCategory.personal,
        scheduledDate: selectedDate,
      );

      var tasks = await service.watchTasksForDate(selectedDate).first;
      await service.toggleTask(tasks.first);
      tasks = await service.watchTasksForDate(selectedDate).first;

      expect(tasks.first.isCompleted, isFalse);
      expect(tasks.last.isCompleted, isTrue);
    },
  );
}
