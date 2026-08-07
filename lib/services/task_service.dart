import '../exceptions/app_exceptions.dart';
import '../interfaces/repository.dart';
import '../models/priority.dart';
import '../models/task.dart';

/// Stratégies de tri pour [TaskService.listTasks].
enum TaskSort { priority, dueDate }

/// Logique métier construite au-dessus d'un [Repository<Task>].
///
/// Conserve la liste de tâches en mémoire et persiste chaque modification
/// via le repository injecté.
class TaskService {
  TaskService(this._repository);

  final Repository<Task> _repository;
  List<Task> _tasks = <Task>[];

  /// Instantané immuable des tâches actuellement en mémoire.
  List<Task> get tasks => List.unmodifiable(_tasks);

  /// Charge les tâches persistées (ou démarre vide au premier lancement).
  Future<void> load() async {
    _tasks = await _repository.load();
  }

  /// Crée et persiste une nouvelle tâche.
  ///
  /// Lorsque [urgent] vaut `true`, un [UrgentTask] est créé et sa priorité
  /// est forcée à [Priority.high].
  Future<Task> addTask({
    required String title,
    Priority priority = Priority.low,
    DateTime? dueDate,
    bool urgent = false,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw const InvalidTaskDataException('Task title cannot be empty.');
    }

    final Task task;
    if (urgent) {
      task = UrgentTask(
        id: _nextId(),
        title: cleanTitle,
        dueDate: dueDate,
      );
    } else {
      task = StandardTask(
        id: _nextId(),
        title: cleanTitle,
        priority: priority,
        dueDate: dueDate,
      );
    }

    _tasks.add(task);
    await _persist();
    return task;
  }

  /// Marque comme terminée la tâche identifiée par [id].
  Future<void> markComplete(int id) async {
    final task = _findOrThrow(id);
    task.isCompleted = true;
    await _persist();
  }

  /// Supprime la tâche identifiée par [id].
  Future<void> deleteTask(int id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      throw TaskNotFoundException('No task found with id $id.');
    }
    _tasks.removeAt(index);
    await _persist();
  }

  /// Renvoie une copie triée des tâches sans muter la liste source.
  ///
  /// * [TaskSort.priority] : les priorités hautes d'abord, puis par id.
  /// * [TaskSort.dueDate] : les échéances les plus proches d'abord, les
  ///   tâches sans échéance toujours en dernier, puis par id.
  List<Task> listTasks({TaskSort sortBy = TaskSort.dueDate}) {
    final result = List<Task>.of(_tasks);
    switch (sortBy) {
      case TaskSort.priority:
        result.sort((a, b) {
          final byPriority = b.priority.order.compareTo(a.priority.order);
          if (byPriority != 0) {
            return byPriority;
          }
          return a.id.compareTo(b.id);
        });
      case TaskSort.dueDate:
        result.sort((a, b) {
          final aDue = a.dueDate;
          final bDue = b.dueDate;
          if (aDue == null && bDue == null) {
            return a.id.compareTo(b.id);
          }
          if (aDue == null) {
            return 1;
          }
          if (bDue == null) {
            return -1;
          }
          final byDate = aDue.compareTo(bDue);
          if (byDate != 0) {
            return byDate;
          }
          return a.id.compareTo(b.id);
        });
    }
    return result;
  }

  int _nextId() {
    if (_tasks.isEmpty) {
      return 1;
    }
    return _tasks
            .map((task) => task.id)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Task _findOrThrow(int id) {
    for (final task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }
    throw TaskNotFoundException('No task found with id $id.');
  }

  Future<void> _persist() => _repository.save(_tasks);
}
