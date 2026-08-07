import 'dart:io';

import 'package:task_manager/exceptions/app_exceptions.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/repositories/json_task_repository.dart';
import 'package:task_manager/services/task_service.dart';

Future<void> main() async {
  final service = TaskService(JsonTaskRepository());

  try {
    await service.load();
    await _runLoop(service);
  } on AppException catch (error) {
    stdout.writeln('\n  Fatal error: ${error.message}');
    exitCode = 1;
  }
}

Future<void> _runLoop(TaskService service) async {
  var running = true;
  while (running) {
    _printMenu();
    final input = _readLine('  Your choice: ');
    if (input == null) {
      running = false;
      stdout.writeln('\n  Goodbye!');
      continue;
    }
    final choice = input.trim();
    switch (choice) {
      case '1':
        await _addTask(service);
      case '2':
        _listTasks(service);
      case '3':
        await _markComplete(service);
      case '4':
        await _deleteTask(service);
      case '5':
        running = false;
        stdout.writeln('\n  Goodbye!');
      default:
        stdout.writeln('\n  Unknown option. Please retry.');
    }
  }
}

void _printMenu() {
  stdout.writeln('''
  =========================================
        TASK MANAGER - Dart CLI
  =========================================
    1. Add a task
    2. List tasks
    3. Mark a task as completed
    4. Delete a task
    5. Exit
  -----------------------------------------''');
}

Future<void> _addTask(TaskService service) async {
  stdout.writeln('\n  --- Add a task ---');
  final titleInput = _readLine('  Title: ');
  if (titleInput == null) {
    stdout.writeln('  Cancelled: end of input.');
    return;
  }
  final title = titleInput.trim();
  if (title.isEmpty) {
    stdout.writeln('  Cancelled: title cannot be empty.');
    return;
  }

  final urgent = _confirm('  Create as urgent task (high priority)? ');
  Priority priority = Priority.low;
  if (!urgent) {
    stdout.writeln(
      '  Priority (${Priority.values.map((p) => p.name).join('/')}):',
    );
    final rawInput = _readLine('  > ');
    if (rawInput == null) {
      stdout.writeln('  Cancelled: end of input.');
      return;
    }
    final raw = rawInput.trim();
    try {
      priority = Priority.fromName(raw.isEmpty ? 'low' : raw);
    } on AppException catch (error) {
      stdout.writeln('  ${error.message}');
      return;
    }
  }

  DateTime? dueDate;
  stdout.writeln('  Due date (YYYY-MM-DD, or leave empty):');
  final rawDateInput = _readLine('  > ');
  if (rawDateInput == null) {
    stdout.writeln('  Cancelled: end of input.');
    return;
  }
  final rawDate = rawDateInput.trim();
  if (rawDate.isNotEmpty) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      stdout.writeln('  Cancelled: invalid date format.');
      return;
    }
    dueDate = parsed;
  }

  try {
    final task = await service.addTask(
      title: title,
      priority: priority,
      dueDate: dueDate,
      urgent: urgent,
    );
    stdout.writeln('  Added ${task.type} task #${task.id} "$title".');
  } on AppException catch (error) {
    stdout.writeln('  ${error.message}');
  }
}

void _listTasks(TaskService service) {
  stdout.writeln('\n  --- List tasks ---');
  stdout.writeln(
    '  Sort by (1: priority, 2: due date) [default: 2]:',
  );
  final raw = _readLine('  > ')?.trim() ?? '';
  final sortBy = raw == '1' ? TaskSort.priority : TaskSort.dueDate;

  final tasks = service.listTasks(sortBy: sortBy);
  if (tasks.isEmpty) {
    stdout.writeln('  No tasks yet.');
    return;
  }

  stdout.writeln();
  for (final task in tasks) {
    final status = task.isCompleted ? '[x]' : '[ ]';
    final due = task.dueDate == null
        ? 'no deadline'
        : _formatDate(task.dueDate!);
    final urgency = task is UrgentTask ? ' (URGENT)' : '';
    stdout.writeln(
      '  $status #${task.id} ${task.priority.label.padRight(6)} '
      '${task.title}$urgency | due: $due',
    );
  }
}

Future<void> _markComplete(TaskService service) async {
  stdout.writeln('\n  --- Mark as completed ---');
  final raw = _readLine('  Task id: ')?.trim() ?? '';
  final id = int.tryParse(raw);
  if (id == null) {
    stdout.writeln('  Cancelled: id must be a number.');
    return;
  }
  try {
    await service.markComplete(id);
    stdout.writeln('  Task #$id marked as completed.');
  } on AppException catch (error) {
    stdout.writeln('  ${error.message}');
  }
}

Future<void> _deleteTask(TaskService service) async {
  stdout.writeln('\n  --- Delete a task ---');
  final raw = _readLine('  Task id: ')?.trim() ?? '';
  final id = int.tryParse(raw);
  if (id == null) {
    stdout.writeln('  Cancelled: id must be a number.');
    return;
  }
  if (!_confirm('  Delete task #$id? ')) {
    stdout.writeln('  Cancelled.');
    return;
  }
  try {
    await service.deleteTask(id);
    stdout.writeln('  Task #$id deleted.');
  } on AppException catch (error) {
    stdout.writeln('  ${error.message}');
  }
}

bool _confirm(String prompt) {
  final answer = _readLine(prompt)?.trim().toLowerCase() ?? '';
  return answer == 'y' || answer == 'yes';
}

String? _readLine(String prompt) {
  stdout.write(prompt);
  return stdin.readLineSync();
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
