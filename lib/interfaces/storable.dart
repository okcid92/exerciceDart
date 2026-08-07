/// Contrat pour tout objet pouvant être sérialisé vers et depuis du JSON.
abstract interface class Storable {
  /// Sérialise cet objet vers une simple map JSON.
  Map<String, dynamic> toJson();
}
