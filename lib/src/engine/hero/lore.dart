import '../monster/breed.dart';

/// The history of interesting events the hero has experienced.
class Lore {
  /// The number of monsters of each breed the hero has detected.
  ///
  /// (Or, more specifically, that have died.)
  final Map<Breed, int> _seen;

  /// The number of monsters of each breed the hero has killed.
  ///
  /// (Or, more specifically, that have died.)
  final Map<Breed, int> _slain;

  /// The breeds the hero has killed at least one of.
  Iterable<Breed> get slainBreeds => _slain.keys;

  Lore() : this.from({}, {});

  Lore.from(this._seen, this._slain);

  void see(Breed breed) {
    _seen.putIfAbsent(breed, () => 0);
    _seen[breed]++;
  }

  void slay(Breed breed) {
    _slain.putIfAbsent(breed, () => 0);
    _slain[breed]++;
  }

  /// The number of monsters of [breed] that the hero has detected.
  int seen(Breed breed) => _seen[breed] ?? 0;

  /// The number of monsters of [breed] that the hero has killed.
  int slain(Breed breed) => _slain[breed] ?? 0;

  Lore clone() =>
      Lore.from(Map<Breed, int>.from(_seen), Map<Breed, int>.from(_slain));
}
