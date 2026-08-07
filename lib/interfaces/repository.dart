/// Contrat générique pour une source de données capable de persister des
/// éléments de type [T].
abstract interface class Repository<T> {
  /// Charge tous les éléments persistés.
  Future<List<T>> load();

  /// Persiste les éléments donnés, en remplaçant les éventuelles données
  /// précédemment stockées.
  Future<void> save(List<T> items);
}
