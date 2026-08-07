# Task Manager CLI (Dart)

Un gestionnaire de tâches en ligne de commande, écrit en **Dart pur** (sans
Flutter). Il illustre les concepts orientés objet du langage : héritage,
interfaces, génériques, enums améliorés, exceptions personnalisées et
persistance JSON locale.

## Fonctionnalités

- Ajouter une tâche (titre, priorité `low` / `medium` / `high`, date limite
  optionnelle).
- Créer une tâche **urgente** (`UrgentTask`) dont la priorité est forcée à `high`.
- Lister les tâches, triées par **priorité** ou par **date limite**.
- Marquer une tâche comme terminée.
- Supprimer une tâche.
- Sauvegarde automatique dans le fichier local `data/tasks.json`.
- Interface CLI interactive en boucle (menu console via `stdin` / `stdout`).

## Architecture

```
.
├── pubspec.yaml
├── bin/
│   └── main.dart                 # Point d'entrée CLI (menu interactif)
├── lib/
│   ├── models/
│   │   ├── priority.dart         # Enhanced enum Priority
│   │   └── task.dart             # Classe abstraite Task + sous-classes
│   ├── interfaces/
│   │   ├── storable.dart         # Interface Storable (toJson)
│   │   └── repository.dart       # Interface générique Repository<T>
│   ├── repositories/
│   │   └── json_task_repository.dart  # Repository<Task> sur fichier JSON
│   ├── services/
│   │   └── task_service.dart     # Logique métier (tri, ajout, suppression)
│   └── exceptions/
│       └── app_exceptions.dart   # Exceptions personnalisées
└── test/
    └── task_manager_test.dart    # Suite de tests unitaires
```

## Concepts Dart utilisés

### Héritage & polymorphisme
`Task` est une **classe abstraite** (champs `id`, `title`, `priority`,
`isCompleted`, `dueDate`). Deux sous-classes l'étendent :

- `StandardTask` : tâche classique, priorité configurable.
- `UrgentTask` : tâche urgente dont la **priorité est toujours forcée à
  `high`** et qui expose des helpers spécifiques (`daysUntilDue()`,
  `isDueTodayOrOverdue`).

Le champ `type` (getter abstrait) sert de discriminateur : la factory
`Task.fromJson` redirige vers la bonne sous-classe lors de la désérialisation.

### Interface `Storable`
Contract de sérialisation (`Map<String, dynamic> toJson()`), implémenté par
`Task`. La désérialisation est assurée par la factory `Task.fromJson`
(helper de désérialisation).

### Génériques : `Repository<T>`
Interface générique de persistance :

```dart
abstract interface class Repository<T> {
  Future<List<T>> load();
  Future<void> save(List<T> items);
}
```

`JsonTaskRepository implements Repository<Task>` implémente la persistance
via `dart:io` (lecture/écriture du fichier `tasks.json` avec `dart:convert`).

### Exceptions personnalisées
Toutes dérivent d'une base `AppException implements Exception` :

- `TaskNotFoundException` — tâche introuvable.
- `InvalidTaskDataException` — données JSON invalides.
- `StorageException` — erreur de lecture/écriture du fichier.

### Enhanced enum
`Priority` est un enum amélioré (Dart 2.17+) avec un label d'affichage, un
rang de tri (`order`) et une factory `Priority.fromName` pour le parsing.

## Prérequis

- Dart SDK **3.0+** (testé sous 3.12).
  Vérifiez avec : `dart --version`

## Installation

```bash
dart pub get
```

## Lancer l'application

```bash
dart run bin/main.dart
```

Suivez ensuite le menu interactif :

```
    1. Add a task
    2. List tasks
    3. Mark a task as completed
    4. Delete a task
    5. Exit
```

Les tâches sont sauvegardées automatiquement dans `data/tasks.json`.

## Exécuter les tests

```bash
dart test
```

La suite couvre la sérialisation, la désérialisation, la validation des
données, le tri, la gestion du cycle de vie des tâches et la persistance.
