extension MapExtensions<K, V> on Map<K, V> {
  Iterable<(K, V)> get pairs =>
      entries.map((entry) => (entry.key, entry.value));
}
