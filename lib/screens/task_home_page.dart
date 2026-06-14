import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({
    super.key,
    required this.taskService,
    required this.currentUser,
    required this.onSignOut,
  });

  final TaskService taskService;
  final User currentUser;
  final Future<void> Function() onSignOut;

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  late DateTime _selectedDate = normalizeTaskDate(DateTime.now());

  DateTime get _today => normalizeTaskDate(DateTime.now());

  Future<void> _signOut() async {
    try {
      await widget.onSignOut();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is AuthServiceException
          ? error.message
          : 'Could not log out right now. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showCalendar(Set<String> taskDateKeys) async {
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return _TaskCalendarDialog(
          selectedDate: _selectedDate,
          firstDate: _today,
          lastDate: DateTime(_today.year + 5, 12, 31),
          taskDateKeys: taskDateKeys,
        );
      },
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDate = normalizeTaskDate(selectedDate);
      });
    }
  }

  Future<void> _showCreateTaskSheet() async {
    final createdTaskDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddTaskSheet(
          initialDate: _selectedDate,
          onCreateTask: (title, description, category, scheduledDate) async {
            await widget.taskService.addTask(
              title: title,
              description: description,
              category: category,
              scheduledDate: scheduledDate,
            );
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task saved to your planner.')),
            );
          },
        );
      },
    );

    if (createdTaskDate != null && mounted) {
      setState(() {
        _selectedDate = normalizeTaskDate(createdTaskDate);
      });
    }
  }

  Future<void> _showTaskDetails(TaskItem task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _TaskDetailSheet(
          task: task,
          onToggleTask: () async {
            await _toggleTask(task);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          onDeleteTask: () async {
            await _deleteTask(task);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _toggleTask(TaskItem task) async {
    try {
      await widget.taskService.toggleTask(task);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_userMessage(error))));
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    try {
      await widget.taskService.deleteTask(task.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${task.title}" deleted.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_userMessage(error))));
    }
  }

  String _userMessage(Object error) {
    if (error is TaskServiceException) {
      return error.message;
    }

    return 'Could not complete that task action right now.';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDate(_selectedDate, _today);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskSheet,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add task'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4EBDC), Color(0xFFE9F3E5), Color(0xFFD5E3D0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<Set<String>>(
                  stream: widget.taskService.watchTaskDateKeys(),
                  initialData: const <String>{},
                  builder: (context, snapshot) {
                    final taskDateKeys = snapshot.data ?? const <String>{};
                    return _TaskHeader(
                      currentUser: widget.currentUser,
                      selectedDate: _selectedDate,
                      isToday: isToday,
                      onJumpToToday: isToday
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = _today;
                              });
                            },
                      onShowCalendar: () => _showCalendar(taskDateKeys),
                      onSignOut: _signOut,
                    );
                  },
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: StreamBuilder<List<TaskItem>>(
                    stream: widget.taskService.watchTasksForDate(_selectedDate),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _StatusPanel(
                          icon: Icons.sync_problem_rounded,
                          title: 'Firestore connection issue',
                          message:
                              'We could not load tasks for ${_longDateLabel(_selectedDate)}. '
                              'Check your Firebase setup and internet connection, then try again.',
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _LoadingPanel();
                      }

                      final tasks = snapshot.data ?? const <TaskItem>[];
                      final completedCount = tasks
                          .where((task) => task.isCompleted)
                          .length;

                      return Column(
                        children: [
                          _TaskSummaryCard(
                            selectedDate: _selectedDate,
                            totalTasks: tasks.length,
                            completedTasks: completedCount,
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: tasks.isEmpty
                                ? _StatusPanel(
                                    icon: Icons.task_alt_rounded,
                                    title: isToday
                                        ? 'No tasks planned for today'
                                        : 'No tasks planned for ${_monthDayLabel(_selectedDate)}',
                                    message:
                                        'Use Today or Calendar above, then add personal or work tasks for that date.',
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 110),
                                    itemCount: tasks.length,
                                    separatorBuilder: (context, _) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final task = tasks[index];
                                      return _TaskTile(
                                        task: task,
                                        onOpen: () => _showTaskDetails(task),
                                        onToggle: () => _toggleTask(task),
                                        onDelete: () => _deleteTask(task),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({
    required this.currentUser,
    required this.selectedDate,
    required this.isToday,
    required this.onJumpToToday,
    required this.onShowCalendar,
    required this.onSignOut,
  });

  final User currentUser;
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback? onJumpToToday;
  final VoidCallback onShowCalendar;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final userName = currentUser.displayName?.trim();
    final greetingName = (userName != null && userName.isNotEmpty)
        ? userName
        : (currentUser.email ?? 'there');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFEDF5E8),
                      foregroundColor: const Color(0xFF2F6B45),
                      child: Text(
                        greetingName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $greetingName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUser.email ?? 'Signed in account',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF596A60)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Log out',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: onJumpToToday,
              icon: const Icon(Icons.today_rounded),
              label: const Text('Today'),
            ),
            FilledButton.tonalIcon(
              onPressed: onShowCalendar,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Calendar'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 18,
                color: Color(0xFF355644),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _longDateLabel(selectedDate),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF355644),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Daily Tasks',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF203126),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isToday
              ? 'Pick a day, plan ahead, and open any task for the full details.'
              : 'Viewing tasks planned for ${_monthDayLabel(selectedDate)}.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.4,
            color: const Color(0xFF405247),
          ),
        ),
      ],
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  const _TaskSummaryCard({
    required this.selectedDate,
    required this.totalTasks,
    required this.completedTasks,
  });

  final DateTime selectedDate;
  final int totalTasks;
  final int completedTasks;

  @override
  Widget build(BuildContext context) {
    final remainingTasks = totalTasks - completedTasks;
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final dateReference = _dateReference(selectedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6B45), Color(0xFF5D8E5A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            remainingTasks == 0 && totalTasks > 0
                ? 'All clear for $dateReference'
                : '$remainingTasks tasks left for $dateReference',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Completed $completedTasks of $totalTasks tasks',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFE8F3E5)),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0x40FFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF6C56D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onOpen,
    required this.onToggle,
    required this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      decoration: task.isCompleted
          ? TextDecoration.lineThrough
          : TextDecoration.none,
      color: task.isCompleted
          ? const Color(0xFF6F7D74)
          : const Color(0xFF203126),
    );

    final supportingText = task.description.isNotEmpty
        ? task.description
        : task.isCompleted
        ? 'Completed'
        : 'Tap to open full details';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: task.isCompleted
              ? const Color(0xFFC4D0C6)
              : const Color(0xFFE5D9CA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.filledTonal(
            tooltip: task.isCompleted ? 'Mark as active' : 'Mark as done',
            onPressed: onToggle,
            icon: Icon(
              task.isCompleted
                  ? Icons.check_rounded
                  : Icons.radio_button_unchecked_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(task.title, style: titleStyle)),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      supportingText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5E6D64),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TaskCategoryChip(category: task.category),
                        _TaskMetaChip(
                          icon: Icons.calendar_today_rounded,
                          label: _monthDayLabel(task.scheduledDate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Delete task',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _TaskCategoryChip extends StatelessWidget {
  const _TaskCategoryChip({required this.category});

  final TaskCategory category;

  @override
  Widget build(BuildContext context) {
    final isWork = category == TaskCategory.work;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isWork ? const Color(0xFFE7EEF9) : const Color(0xFFEBF5E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isWork ? const Color(0xFF2E4E78) : const Color(0xFF2F6B45),
        ),
      ),
    );
  }
}

class _TaskMetaChip extends StatelessWidget {
  const _TaskMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5E6D64)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5E6D64),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailSheet extends StatelessWidget {
  const _TaskDetailSheet({
    required this.task,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  final TaskItem task;
  final Future<void> Function() onToggleTask;
  final Future<void> Function() onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Color(0xFFF7F2E8)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _TaskCategoryChip(category: task.category),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TaskMetaChip(
                      icon: Icons.calendar_month_rounded,
                      label: _longDateLabel(task.scheduledDate),
                    ),
                    _TaskMetaChip(
                      icon: task.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.timelapse_rounded,
                      label: task.isCompleted ? 'Completed' : 'Pending',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    task.description.isNotEmpty
                        ? task.description
                        : 'No extra description was added for this task.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: const Color(0xFF425349),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onToggleTask,
                        icon: Icon(
                          task.isCompleted
                              ? Icons.restart_alt_rounded
                              : Icons.check_rounded,
                        ),
                        label: Text(
                          task.isCompleted ? 'Mark active' : 'Mark done',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onDeleteTask,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCalendarDialog extends StatefulWidget {
  const _TaskCalendarDialog({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.taskDateKeys,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<String> taskDateKeys;

  @override
  State<_TaskCalendarDialog> createState() => _TaskCalendarDialogState();
}

class _TaskCalendarDialogState extends State<_TaskCalendarDialog> {
  late DateTime _visibleMonth = DateTime(
    widget.selectedDate.year,
    widget.selectedDate.month,
  );

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = (screenSize.width - 32).clamp(280.0, 720.0).toDouble();
    final cellAspectRatio = dialogWidth >= 680
        ? 1.15
        : dialogWidth >= 520
        ? 1.0
        : 0.82;
    final days = _calendarCellsForMonth(_visibleMonth);
    final canGoBack = _isMonthBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month),
      _visibleMonth,
    );
    final canGoForward = _isMonthBefore(
      _visibleMonth,
      DateTime(widget.lastDate.year, widget.lastDate.month),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: screenSize.height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: canGoBack
                          ? () {
                              setState(() {
                                _visibleMonth = DateTime(
                                  _visibleMonth.year,
                                  _visibleMonth.month - 1,
                                );
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '${_monthLabels[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: canGoForward
                          ? () {
                              setState(() {
                                _visibleMonth = DateTime(
                                  _visibleMonth.year,
                                  _visibleMonth.month + 1,
                                );
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: _weekdayLabels.map((weekday) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          weekday.substring(0, 3),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF68776E),
                              ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: cellAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    if (day == null) {
                      return const SizedBox.shrink();
                    }

                    final normalizedDay = normalizeTaskDate(day);
                    final isDisabled =
                        normalizedDay.isBefore(widget.firstDate) ||
                        normalizedDay.isAfter(widget.lastDate);
                    final isSelected = _isSameDate(
                      normalizedDay,
                      widget.selectedDate,
                    );
                    final isToday = _isSameDate(
                      normalizedDay,
                      normalizeTaskDate(DateTime.now()),
                    );
                    final hasTasks = widget.taskDateKeys.contains(
                      taskDateKeyFromDate(normalizedDay),
                    );

                    Color backgroundColor = Colors.transparent;
                    Color foregroundColor = const Color(0xFF203126);
                    Border? border;

                    if (hasTasks) {
                      backgroundColor = const Color(0xFFE0F1DE);
                      foregroundColor = const Color(0xFF2F6B45);
                    }

                    if (isToday) {
                      border = Border.all(
                        color: const Color(0xFF5D8E5A),
                        width: 1.5,
                      );
                    }

                    if (isSelected) {
                      backgroundColor = const Color(0xFF2F6B45);
                      foregroundColor = Colors.white;
                      border = null;
                    }

                    return InkWell(
                      onTap: isDisabled
                          ? null
                          : () => Navigator.of(context).pop(normalizedDay),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? Colors.black.withValues(alpha: 0.04)
                              : backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: border,
                        ),
                        child: Center(
                          child: Text(
                            '${normalizedDay.day}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDisabled
                                      ? const Color(0xFFAFB7B1)
                                      : foregroundColor,
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _CalendarLegend(
                      color: Color(0xFFE0F1DE),
                      label: 'Has tasks',
                    ),
                    _CalendarLegend(
                      color: Color(0xFF2F6B45),
                      label: 'Selected date',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: const Color(0xFF5E6D64)),
        ),
      ],
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({required this.initialDate, required this.onCreateTask});

  final DateTime initialDate;
  final Future<void> Function(
    String title,
    String description,
    TaskCategory category,
    DateTime scheduledDate,
  )
  onCreateTask;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late DateTime _selectedDate = normalizeTaskDate(widget.initialDate);
  TaskCategory _selectedCategory = TaskCategory.personal;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTaskDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: normalizeTaskDate(DateTime.now()),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      helpText: 'Choose the task day',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = normalizeTaskDate(selectedDate);
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a task title first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onCreateTask(
        title,
        _descriptionController.text.trim(),
        _selectedCategory,
        _selectedDate,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_selectedDate);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_userMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _userMessage(Object error) {
    if (error is TaskServiceException) {
      return error.message;
    }

    return 'Could not save your task right now.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Color(0xFFF7F2E8)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a new task',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Plan personal errands and work tasks with clear details and a target day.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF56655D),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'Example: Review the client proposal',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 4,
                  maxLength: 180,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText:
                        'Add notes, meeting context, shopping details, or next steps',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Task type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: TaskCategory.values.map((category) {
                    final isSelected = category == _selectedCategory;
                    return ChoiceChip(
                      label: Text(category.label),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _pickTaskDate,
                  borderRadius: BorderRadius.circular(22),
                  child: Ink(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          color: Color(0xFF2F6B45),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task date',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _longDateLabel(_selectedDate),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xFF56655D)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_calendar_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_task_rounded),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Loading your tasks...'),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: const Color(0xFF2F6B45)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF56655D),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _isMonthBefore(DateTime left, DateTime right) {
  return left.year < right.year ||
      (left.year == right.year && left.month < right.month);
}

List<DateTime?> _calendarCellsForMonth(DateTime visibleMonth) {
  final firstDayOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
  final daysInMonth = DateTime(
    visibleMonth.year,
    visibleMonth.month + 1,
    0,
  ).day;
  final leadingEmptyCells = firstDayOfMonth.weekday - 1;
  final totalVisibleCells = ((leadingEmptyCells + daysInMonth + 6) ~/ 7) * 7;

  return List<DateTime?>.generate(totalVisibleCells, (index) {
    final dayNumber = index - leadingEmptyCells + 1;
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return null;
    }

    return DateTime(visibleMonth.year, visibleMonth.month, dayNumber);
  });
}

String _dateReference(DateTime date) {
  return _isSameDate(normalizeTaskDate(DateTime.now()), date)
      ? 'today'
      : _monthDayLabel(date);
}

String _monthDayLabel(DateTime date) {
  final month = _monthLabels[date.month - 1];
  return '$month ${date.day}';
}

String _longDateLabel(DateTime date) {
  final weekday = _weekdayLabels[date.weekday - 1];
  final month = _monthLabels[date.month - 1];
  return '$weekday, $month ${date.day}';
}

const List<String> _weekdayLabels = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _monthLabels = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
