import 'package:piecemeal/piecemeal.dart';

// TODO: Make implement Iterable<T>?
// TODO: Combine with tags to make single unified way of choosing random stuff.
class RaritySet<T> {
  final List<_RareElement<T>> _elements = [];
  double _totalProbability;

  bool get isEmpty => _elements.isEmpty;
  bool get isNotEmpty => _elements.isNotEmpty;

  void add(T element, int rarity) {
    _elements.add(new _RareElement(rarity, element));

    // Mark it as needing updating.
    _totalProbability = 0.0;
  }

  T choose() {
    if (_elements.isEmpty) throw new StateError("Set is empty.");
    if (_totalProbability == 0.0) _calculateProbabilities();

    // Pick a point in the probability range.
    var t = rng.float(_totalProbability);

    // TODO: Use binary search instead of linear.
    var start = 0.0;
    for (var element in _elements) {
      if (t >= start && t < element.probabilityEnd) {
        return element.value;
      }

      start = element.probabilityEnd;
    }

    throw "Unreachable.";
  }

  void _calculateProbabilities() {
    // Walk the elements and give them a range along the total cumulative
    // probability of all elements.
    _totalProbability = 0.0;
    for (var element in _elements) {
      // "Commoness" is the reciprocal of rarity. An element with rarity 2 is
      // half as likely to appear compared to if it had rarity 1.
      _totalProbability += 1.0 / element.rarity;
      element.probabilityEnd = _totalProbability;
    }
  }
}

class _RareElement<T> {
  final int rarity;
  final T value;
  double probabilityEnd = 0.0;

  _RareElement(this.rarity, this.value);
}
