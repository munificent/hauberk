import '../items/affix.dart';
import '../items/item.dart';
import '../items/item_type.dart';
import '../monster/breed.dart';

/// The history of interesting events the hero has experienced.
class Lore {
  /// The number of monsters of each breed the hero has detected.
  ///
  /// (Or, more specifically, that have died.)
  final Map<Breed, int> _seenBreeds;

  /// The number of monsters of each breed the hero has killed.
  ///
  /// (Or, more specifically, that have died.)
  final Map<Breed, int> _slainBreeds;

  /// The number of items of each type that the hero has picked up.
  final Map<ItemType, int> _foundItems;

  /// The number of items with each affix that the hero has picked up or used.
  final Map<Affix, int> _foundAffixes;

  /// The number of consumable items of each type that the hero has used.
  final Map<ItemType, int> _usedItems;

  /// The breeds the hero has killed at least one of.
  Iterable<Breed> get slainBreeds => _slainBreeds.keys;

  /// The total number of monsters slain.
  int get allSlain => _slainBreeds.values.fold(0, (a, b) => a + b);

  Lore() : this.from({}, {}, {}, {}, {});

  Lore.from(this._seenBreeds, this._slainBreeds, this._foundItems,
      this._foundAffixes, this._usedItems);

  void seeBreed(Breed breed) {
    _seenBreeds.putIfAbsent(breed, () => 0);
    _seenBreeds[breed]++;
  }

  void slay(Breed breed) {
    _slainBreeds.putIfAbsent(breed, () => 0);
    _slainBreeds[breed]++;
  }

  void findItem(Item item) {
    _foundItems.putIfAbsent(item.type, () => 0);
    _foundItems[item.type]++;

    findAffix(Affix affix) {
      if (affix == null) return;

      _foundAffixes.putIfAbsent(affix, () => 0);
      _foundAffixes[affix]++;
    }

    findAffix(item.prefix);
    findAffix(item.suffix);
  }

  void useItem(Item item) {
    _usedItems.putIfAbsent(item.type, () => 0);
    _usedItems[item.type]++;
  }

  /// The number of monsters of [breed] that the hero has detected.
  int seenBreed(Breed breed) => _seenBreeds[breed] ?? 0;

  /// The number of monsters of [breed] that the hero has killed.
  int slain(Breed breed) => _slainBreeds[breed] ?? 0;

  /// The number of items of [type] the hero has picked up.
  int foundItems(ItemType type) => _foundItems[type] ?? 1;

  /// The number of items with [affix] the hero has picked up.
  int foundAffixes(Affix affix) => _foundAffixes[affix] ?? 0;

  /// The number of items of [type] the hero has used.
  int usedItems(ItemType type) => _usedItems[type] ?? 0;

  Lore clone() => Lore.from(Map.of(_seenBreeds), Map.of(_slainBreeds),
      Map.of(_foundItems), Map.of(_foundAffixes), Map.of(_usedItems));
}
