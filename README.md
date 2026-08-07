# Task Manager CLI (Dart)

Un gestionnaire de tâches en ligne de commande, écrit en **Dart pur** (sans
Flutter). Le projet illustre les concepts orientés objet du langage :
héritage, interfaces, génériques, enums améliorés, exceptions personnalisées
et persistance JSON locale.

## Fonctionnalités

- Ajouter une tâche (titre **non vide**, priorité `low` / `medium` / `high`,
  date limite **optionnelle**).
- Créer une tâche **urgente** (`UrgentTask`) dont la priorité est forcée à
  `high`.
- Lister toutes les tâches, avec choix de tri par **priorité** ou par
  **date limite**.
- Marquer une tâche comme **terminée**.
- **Supprimer** une tâche.
- **Persistance automatique** dans le fichier local `tasks.json` (à la racine
  du projet).
- Interface CLI interactive en boucle (menu console via `stdin` / `stdout`).

## Architecture

```
.
├── pubspec.yaml                     # Dépendances (path, test, lints)
├── analysis_options.yaml            # Lints officiels (package:lints)
├── README.md
├── bin/
│   └── main.dart                    # Point d'entrée CLI (menu interactif)
├── lib/
│   ├── models/
│   │   ├── priority.dart            # Enhanced enum Priority (low/medium/high)
│   │   └── task.dart                # Classe abstraite Task + sous-classes
│   ├── interfaces/
│   │   ├── storable.dart            # Interface Storable (toJson)
│   │   └── repository.dart          # Interface générique Repository<T>
│   ├── repositories/
│   │   └── json_task_repository.dart    # Repository<Task> sur fichier JSON
│   ├── services/
│   │   └── task_service.dart        # Logique métier (tri, ajout, suppression)
│   └── exceptions/
│       └── app_exceptions.dart      # Exceptions personnalisées
└── test/
    └── task_manager_test.dart       # Suite de tests unitaires (17 tests)
```

## Concepts Dart utilisés

### Héritage & polymorphisme
`Task` est une **classe abstraite** avec les propriétés `id`, `title`,
`priority`, `isCompleted` et `dueDate`. Deux sous-classes l'étendent :

- `StandardTask` : tâche classique, priorité configurable.
- `UrgentTask` : tâche urgente dont la **priorité est toujours forcée à
  `high`** et qui expose des helpers spécifiques (`daysUntilDue()`,
  `isDueTodayOrOverdue`).

Le getter abstrait `type` sert de discriminateur : la factory `Task.fromJson`
redirige vers la bonne sous-classe lors de la désérialisation.

### Interface `Storable`
```dart
abstract interface class Storable {
  Map<String, dynamic> toJson();
}
```
La classe abstraite `Task implements Storable` et fournit `toJson()`. La
désérialisation est assurée par la factory `Task.fromJson`
(helper de désérialisation).

### Génériques : `Repository<T>`
```dart
abstract interface class Repository<T> {
  Future<List<T>> load();
  Future<void> save(List<T> items);
}
```
`JsonTaskRepository implements Repository<Task>` gère la persistance via
`dart:io` (lecture/écriture de `tasks.json` avec `dart:convert`).

### Exceptions personnalisées
Toutes dérivent d'une base `AppException implements Exception` :

- `TaskNotFoundException` — tâche introuvable (marquage/suppression).
- `InvalidTaskDataException` — données invalides (titre vide, JSON mal formé,
  priorité/date inconnues...).
- `StorageException` — erreur de lecture/écriture du fichier.

### Enhanced enum
`Priority` est un enum amélioré (Dart 2.17+) avec un libellé d'affichage
(`label`), un rang de tri (`order`) et une factory `Priority.fromName` pour
l'analyse de chaînes.

## Conformité au cahier des charges

| Exigence | Implémentation |
| --- | --- |
| Ajouter une tâche (titre, priorité, date limite) | `TaskService.addTask` + menu `1` |
| Lister toutes les tâches (tri priorité/date) | `TaskService.listTasks` + menu `2` |
| Marquer une tâche terminée | `TaskService.markComplete` + menu `3` |
| Supprimer une tâche | `TaskService.deleteTask` + menu `4` |
| Persistance locale `tasks.json` | `JsonTaskRepository` |
| Classe abstraite `Task` + sous-classes | `lib/models/task.dart` |
| Interface explicite (`Storable`) | `lib/interfaces/storable.dart` |
| Interface générique `Repository<T>` | `lib/interfaces/repository.dart` |
| Implémentation `JsonTaskRepository implements Repository<Task>` | `lib/repositories/json_task_repository.dart` |
| Exceptions personnalisées | `lib/exceptions/app_exceptions.dart` |
| Tests unitaires (`test/`, package `test`) | `test/task_manager_test.dart` |
| README + commandes de lancement/tests | ce fichier |

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

Les tâches sont sauvegardées automatiquement dans `tasks.json` (créé à la
racine du projet au premier lancement).

## Exécuter les tests

```bash
dart test
```

La suite (17 tests) couvre : le contrat `Storable`, la sérialisation /
désérialisation, la validation des données, le tri par priorité et par date,
le cycle de vie des tâches (ajout, complétion, suppression) et la persistance.

## Analyse statique

```bash
dart analyze
```

Le projet suit les lints officiels `package:lints/recommended.yaml` et ne
remonte aucune alerte.
