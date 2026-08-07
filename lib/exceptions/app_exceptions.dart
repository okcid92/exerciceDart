/// Classe de base pour toutes les exceptions levées par l'application.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Levée lorsqu'une opération référence une tâche inexistante.
class TaskNotFoundException extends AppException {
  const TaskNotFoundException(super.message);
}

/// Levée lorsque des données ne peuvent pas être interprétées comme des
/// données de tâche valides (champs manquants, mauvais types, valeurs
/// d'enum inconnues...).
class InvalidTaskDataException extends AppException {
  const InvalidTaskDataException(super.message);
}

/// Levée lors d'un échec de lecture ou d'écriture de la couche de stockage.
class StorageException extends AppException {
  const StorageException(super.message);
}
