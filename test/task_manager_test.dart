import 'dart:io';

import 'package:task_manager/exceptions/app_exceptions.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/repositories/json_task_repository.dart';
import 'package:task_manager/services/task_service.dart';
import 'package:test/test.dart';

void main() {
  group('StandardTask', () {
    test('serializes and deserializes without data loss', () {
      final dueDate = DateTime(2026, 8, 7, 12, 30);
      final task = StandardTask(
        id: 7,
        title: 'Write report',
        priority: Priority.medium,
        isCompleted: true,
        dueDate: dueDate,
      );

      final json = task.toJson();
      final rebuilt = Task.fromJson(json);

      expect(rebuilt, isA<StandardTask>());
      expect(rebuilt.id, 7);
      expect(rebuilt.title, 'Write report');
      expect(rebuilt.priority, Priority.medium);
      expect(rebuilt.isCompleted, isTrue);
      expect(rebuilt.dueDate, dueDate);
    });
  });

  group('UrgentTask', () {
    test('always forces high priority regardless of input', () {
      final task = UrgentTask(id: 1, title: 'Hotfix the server');

      expect(task.priority, Priority.high);
      expect(task.type, 'urgent');
    });

    test('keeps its type through a JSON round trip', () {
      final task = UrgentTask(
        id: 2,
        title: 'Deploy patch',
        dueDate: DateTime(2026, 8, 10),
      );

      final rebuilt = Task.fromJson(task.toJson());

      expect(rebuilt, isA<UrgentTask>());
      expect(rebuilt.priority, Priority.high);
      expect(rebuilt.dueDate, DateTime(2026, 8, 10));
    });
  });

  group('Task.fromJson validation', () {
    test('rejects data with an unknown type', () {
      expect(
        () => Task.fromJson(<String, dynamic>{
          'id': 1,
          'title': 'X',
          'priority': 'low',
          'isCompleted': false,
          'type': 'alien',
        }),
        throwsA(isA<InvalidTaskDataException>()),
      );
    });

    test('rejects data with an invalid due date', () {
      expect(
        () => Task.fromJson(<String, dynamic>{
          'id': 1,
          'title': 'X',
          'priority': 'low',
          'isCompleted': false,
          'dueDate': 'not-a-date',
          'type': 'standard',
        }),
        throwsA(isA<InvalidTaskDataException>()),
      );
    });

    test('rejects data with an unknown priority', () {
      expect(
        () => Task.fromJson(<String, dynamic>{
          'id': 1,
          'title': 'X',
          'priority': 'critical',
          'isCompleted': false,
          'type': 'standard',
        }),
        throwsA(isA<InvalidTaskDataException>()),
      );
    });
  });

  group('TaskService', () {
    late TaskService service;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('tm_test_');
      service = TaskService(
        JsonTaskRepository(directory: dir.path),
      );
      addTearDown(() => dir.deleteSync(recursive: true));
    });

    test('adds tasks and assigns incrementing ids', () async {
      final first = await service.addTask(title: 'First');
      final second = await service.addTask(title: 'Second');

      expect(first.id, 1);
      expect(second.id, 2);
      expect(service.tasks, hasLength(2));
    });

    test('rejects an empty title', () {
      expect(
        () => service.addTask(title: '   '),
        throwsA(isA<InvalidTaskDataException>()),
      );
    });

    test('sorts by priority (high first, then id)', () async {
      await service.addTask(title: 'Low task', priority: Priority.low);
      await service.addTask(title: 'High task', priority: Priority.high);
      await service.addTask(title: 'Medium task', priority: Priority.medium);
      await service.addTask(title: 'Urgent task', urgent: true);

      final sorted = service.listTasks(sortBy: TaskSort.priority);
      final titles = sorted.map((t) => t.title).toList();

      expect(titles, [
        'High task',
        'Urgent task',
        'Medium task',
        'Low task',
      ]);
    });

    test('sorts by due date with tasks without a deadline last', () async {
      await service.addTask(title: 'No deadline');
      await service.addTask(
        title: 'Later',
        dueDate: DateTime(2026, 12, 31),
      );
      await service.addTask(
        title: 'Sooner',
        dueDate: DateTime(2026, 8, 7),
      );

      final sorted = service.listTasks(sortBy: TaskSort.dueDate);
      final titles = sorted.map((t) => t.title).toList();

      expect(titles, ['Sooner', 'Later', 'No deadline']);
    });

    test('marks a task as completed', () async {
      final task = await service.addTask(title: 'Read a book');
      expect(task.isCompleted, isFalse);

      await service.markComplete(task.id);

      final stored = service.tasks.single;
      expect(stored.isCompleted, isTrue);
    });

    test('deletes a task and removes it from the list', () async {
      final task = await service.addTask(title: 'Throw away');
      expect(service.tasks, hasLength(1));

      await service.deleteTask(task.id);

      expect(service.tasks, isEmpty);
    });

    test('throws TaskNotFoundException for unknown ids', () async {
      await service.addTask(title: 'Only task');

      expect(
        () => service.markComplete(999),
        throwsA(isA<TaskNotFoundException>()),
      );
      expect(
        () => service.deleteTask(999),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('JsonTaskRepository', () {
    test('persists tasks to disk and reloads them', () async {
      final dir = await Directory.systemTemp.createTemp('tm_repo_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final repository = JsonTaskRepository(directory: dir.path);
      final service = TaskService(repository);

      await service.load();
      await service.addTask(
        title: 'Persisted task',
        priority: Priority.high,
        dueDate: DateTime(2026, 8, 7),
      );
      await service.addTask(title: 'Persisted urgent', urgent: true);

      final reloaded = TaskService(JsonTaskRepository(directory: dir.path));
      await reloaded.load();

      expect(reloaded.tasks, hasLength(2));
      final first = reloaded.tasks.first;
      expect(first, isA<StandardTask>());
      expect(first.title, 'Persisted task');
      expect(first.priority, Priority.high);
      expect(first.dueDate, DateTime(2026, 8, 7));
      expect(reloaded.tasks.last, isA<UrgentTask>());
    });

    test('loads an empty list when the file does not exist yet', () async {
      final dir = await Directory.systemTemp.createTemp('tm_empty_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final repository = JsonTaskRepository(directory: dir.path);
      final tasks = await repository.load();

      expect(tasks, isEmpty);
    });

    test('throws StorageException when the file is not valid JSON', () async {
      final dir = await Directory.systemTemp.createTemp('tm_bad_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final repository = JsonTaskRepository(directory: dir.path);
      File('${dir.path}/tasks.json').writeAsStringSync('{not valid json');

      expect(
        repository.load(),
        throwsA(isA<StorageException>()),
      );
    });
  });
}
