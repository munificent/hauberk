class Histogram {
  final Map<String, int> _counts = {};

  void add(String name) {
    _counts.putIfAbsent(name, () => 0);
    _counts[name]++;
  }

  int count(String name) {
    if (!_counts.containsKey(name)) return 0;
    return _counts[name];
  }

  List<String> ascending() {
    var names = _counts.keys.toList();
    names.sort((a, b) => _counts[a].compareTo(_counts[b]));
    return names;
  }

  List<String> descending() {
    var names = _counts.keys.toList();
    names.sort((a, b) => _counts[b].compareTo(_counts[a]));
    return names;
  }
}