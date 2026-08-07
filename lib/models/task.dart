import '../exceptions/app_exceptions.dart';
import 'priority.dart';

/// Classe abstraite de base pour toutes les tâches.
abstract class Task {
  Task({
    required this.id,
    required this.title,
    this.priority = Priority.low,
    this.isCompleted = false,
    this.dueDate,
  });

  final int id;
  final String title;
  Priority priority;
  bool isCompleted;
  DateTime? dueDate;

  /// Discriminateur utilisé lors de la sérialisation JSON pour savoir
  /// quelle sous-classe doit être reconstruite.
  String get type;

  /// Sérialise la tâche vers une simple map JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'priority': priority.name,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'type': type,
    };
  }

  /// Désérialise une [Task] depuis une map JSON, en redirigeant vers la
  /// bonne sous-classe en fonction du champ `type`.
  factory Task.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'standard':
        return StandardTask.fromJson(json);
      case 'urgent':
        return UrgentTask.fromJson(json);
      default:
        throw const InvalidTaskDataException(
          'Unknown or missing task type.',
        );
    }
  }

  /// Analyse partagée et défensive des champs communs.
  static (int, String, Priority, bool, DateTime?) parseCommonFields(
    Map<String, dynamic> json,
  ) {
    final rawId = json['id'];
    final rawTitle = json['title'];
    final rawPriority = json['priority'];
    final rawCompleted = json['isCompleted'];
    final rawDueDate = json['dueDate'];

    if (rawId is! int) {
      throw const InvalidTaskDataException('Task "id" must be an integer.');
    }
    if (rawTitle is! String || rawTitle.trim().isEmpty) {
      throw const InvalidTaskDataException(
        'Task "title" must be a non-empty string.',
      );
    }
    if (rawPriority is! String) {
      throw const InvalidTaskDataException(
        'Task "priority" must be a string.',
      );
    }
    if (rawCompleted is! bool) {
      throw const InvalidTaskDataException(
        'Task "isCompleted" must be a boolean.',
      );
    }

    DateTime? parsedDueDate;
    if (rawDueDate != null) {
      if (rawDueDate is! String) {
        throw const InvalidTaskDataException(
          'Task "dueDate" must be an ISO-8601 string.',
        );
      }
      parsedDueDate = DateTime.tryParse(rawDueDate);
      if (parsedDueDate == null) {
        throw InvalidTaskDataException(
          'Task "dueDate" is not a valid date: "$rawDueDate".',
        );
      }
    }

    return (
      rawId,
      rawTitle,
      Priority.fromName(rawPriority),
      rawCompleted,
      parsedDueDate,
    );
  }
}

/// Une tâche classique avec une priorité configurable.
class StandardTask extends Task {
  StandardTask({
    required super.id,
    required super.title,
    super.priority,
    super.isCompleted,
    super.dueDate,
  });

  factory StandardTask.fromJson(Map<String, dynamic> json) {
    final (id, title, priority, completed, dueDate) =
        Task.parseCommonFields(json);
    return StandardTask(
      id: id,
      title: title,
      priority: priority,
      isCompleted: completed,
      dueDate: dueDate,
    );
  }

  @override
  String get type => 'standard';
}

/// Une tâche urgente.
///
/// Logique spécifique : une tâche urgente se voit toujours attribuer la
/// plus haute priorité [Priority.high], quelle que soit la demande, et
/// expose des helpers pour raisonner sur la proximité de l'échéance.
class UrgentTask extends Task {
  UrgentTask({
    required super.id,
    required super.title,
    super.isCompleted,
    super.dueDate,
  }) {
    priority = Priority.high;
  }

  factory UrgentTask.fromJson(Map<String, dynamic> json) {
    final (id, title, _, completed, dueDate) = Task.parseCommonFields(json);
    return UrgentTask(
      id: id,
      title: title,
      isCompleted: completed,
      dueDate: dueDate,
    );
  }

  @override
  String get type => 'urgent';

  /// Nombre de jours pleins restants avant l'échéance (0 ou négatif lorsque
  /// l'échéance est passée). Renvoie `null` lorsqu'aucune échéance n'est fixée.
  int? daysUntilDue() {
    if (dueDate == null) {
      return null;
    }
    return dueDate!.difference(DateTime.now()).inDays;
  }

  /// Indique si l'échéance est aujourd'hui ou déjà passée.
  bool get isDueTodayOrOverdue {
    if (dueDate == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
    );
    return !deadline.isAfter(today);
  }
}
