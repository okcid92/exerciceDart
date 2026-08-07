import '../exceptions/app_exceptions.dart';

/// Enum amélioré représentant le niveau de priorité d'une [Task].
enum Priority {
  low(label: 'Low', order: 0),
  medium(label: 'Medium', order: 1),
  high(label: 'High', order: 2);

  const Priority({required this.label, required this.order});

  /// Libellé lisible par un humain, utilisé pour l'affichage dans la CLI.
  final String label;

  /// Rang numérique utilisé pour le tri (plus élevé = plus important).
  final int order;

  /// Analyse une chaîne brute (insensible à la casse) en un [Priority].
  ///
  /// Lève [InvalidTaskDataException] lorsque la valeur est inconnue.
  static Priority fromName(String? value) {
    if (value == null) {
      throw const InvalidTaskDataException('Priority is missing.');
    }
    switch (value.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        throw InvalidTaskDataException('Unknown priority: "$value".');
    }
  }
}
