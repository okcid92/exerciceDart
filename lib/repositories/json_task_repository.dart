import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../exceptions/app_exceptions.dart';
import '../interfaces/repository.dart';
import '../models/task.dart';

/// Implémentation de [Repository<Task>] basée sur un fichier JSON local
/// (par défaut `data/tasks.json`).
class JsonTaskRepository implements Repository<Task> {
  JsonTaskRepository({String? directory, String? fileName}) {
    final dir = directory ?? 'data';
    final name = fileName ?? 'tasks.json';
    final resolved = File(p.normalize(p.join(dir, name)));
    resolved.parent.createSync(recursive: true);
    _file = resolved;
  }

  late final File _file;

  /// Chemin absolu du fichier JSON sous-jacent.
  String get path => _file.path;

  @override
  Future<List<Task>> load() async {
    try {
      if (!_file.existsSync()) {
        return <Task>[];
      }

      final content = await _file.readAsString();
      if (content.trim().isEmpty) {
        return <Task>[];
      }

      final decoded = jsonDecode(content);
      if (decoded is! List) {
        throw const InvalidTaskDataException(
          'Root of tasks.json must be a JSON array.',
        );
      }

      return decoded.map((element) {
        if (element is! Map<String, dynamic>) {
          throw const InvalidTaskDataException(
            'Every element of tasks.json must be a JSON object.',
          );
        }
        return Task.fromJson(element);
      }).toList();
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw StorageException('Unable to load tasks: $error');
    }
  }

  @override
  Future<void> save(List<Task> items) async {
    try {
      _file.parent.createSync(recursive: true);
      final encoded = jsonEncode(
        items.map((task) => task.toJson()).toList(),
      );
      await _file.writeAsString(encoded);
    } on Exception catch (error) {
      throw StorageException('Unable to save tasks: $error');
    }
  }
}
