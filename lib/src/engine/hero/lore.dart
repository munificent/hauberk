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
  final Map<AffixType, int> _foundAffixes;

  /// The artifact [ItemType]s whose items exist in the world. This doesn't
  /// necessarily mean that the hero has found them.
  final Set<ItemType> _createdArtifacts;

  /// The number of consumable items of each type that the hero has used.
  final Map<ItemType, int> _usedItems;

  /// The breeds the hero has killed at least one of.
  Iterable<Breed> get slainBreeds => _slainBreeds.keys;

  /// The total number of monsters slain.
  int get allSlain => _slainBreeds.values.fold(0, (a, b) => a + b);

  Lore() : this.from({}, {}, {}, {}, {}, {});

  Lore.from(
    this._seenBreeds,
    this._slainBreeds,
    this._foundItems,
    this._foundAffixes,
    this._createdArtifacts,
    this._usedItems,
  );

  void seeBreed(Breed breed) {
    _seenBreeds.putIfAbsent(breed, () => 0);
    _seenBreeds[breed] = _seenBreeds[breed]! + 1;
  }

  void slay(Breed breed) {
    _slainBreeds.putIfAbsent(breed, () => 0);
    _slainBreeds[breed] = _slainBreeds[breed]! + 1;
  }

  void findItem(Item item) {
    _foundItems.putIfAbsent(item.type, () => 0);
    _foundItems[item.type] = _foundItems[item.type]! + 1;

    for (var affix in item.affixes) {
      _foundAffixes.putIfAbsent(affix.type, () => 0);
      _foundAffixes[affix.type] = _foundAffixes[affix.type]! + 1;
    }
  }

  void useItem(Item item) {
    _usedItems.putIfAbsent(item.type, () => 0);
    _usedItems[item.type] = _usedItems[item.type]! + 1;
  }

  void createArtifact(ItemType artifact) {
    _createdArtifacts.add(artifact);
  }

  /// Forget that [artifact] was created.
  ///
  /// This is called when the hero leaves a dungeon with an artifact on the
  /// ground. This allows it to be generated again later on future dives.
  void uncreateArtifact(Item artifact) {
    _createdArtifacts.remove(artifact.type);
  }

  /// The number of monsters of [breed] that the hero has detected.
  int seenBreed(Breed breed) => _seenBreeds[breed] ?? 0;

  /// The number of monsters of [breed] that the hero has killed.
  int slain(Breed breed) => _slainBreeds[breed] ?? 0;

  /// The number of items of [type] the hero has picked up.
  int foundItems(ItemType type) => _foundItems[type] ?? 0;

  /// The number of items with [affix] the hero has picked up.
  int foundAffixes(AffixType affix) => _foundAffixes[affix] ?? 0;

  /// The number of items of [type] the hero has used.
  int usedItems(ItemType type) => _usedItems[type] ?? 0;

  /// Whether [artifact] has already been generated.
  bool createdArtifact(ItemType artifact) =>
      _createdArtifacts.contains(artifact);

  Lore clone() => Lore.from(
    {..._seenBreeds},
    {..._slainBreeds},
    {..._foundItems},
    {..._foundAffixes},
    {..._createdArtifacts},
    {..._usedItems},
  );
}
