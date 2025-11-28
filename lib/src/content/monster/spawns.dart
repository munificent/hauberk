import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'monsters.dart';

Spawn spawnBreed(String name) => _BreedSpawn(BreedRef(name));

Spawn spawnTag(String tag) => _TagSpawn(tag);

Spawn repeatSpawn(int min, int max, Spawn spawn) =>
    _RepeatSpawn(min, max, spawn);

Spawn spawnAll(List<Spawn> spawns) => _AllOfSpawn(spawns);

/// Converts [drop] to a JSON-like representation that describes all of the
/// data it contains.
Map<String, Object?> spawnGameData(Spawn spawn) {
  switch (spawn) {
    case _BreedSpawn breed:
      return {'type': 'breed', 'breed': breed._breed.breed.name};
    case _TagSpawn tag:
      return {'type': 'tag', 'tag': tag._tag};
    case _RepeatSpawn repeat:
      return {
        'type': 'repeat',
        'minCount': repeat._minCount,
        'maxCount': repeat._maxCount,
        'spawn': spawnGameData(repeat._spawn),
      };
    case _AllOfSpawn allOf:
      return {
        'type': 'allOf',
        'spawns': [for (var spawn in allOf._spawns) spawnGameData(spawn)],
      };
    default:
      throw ArgumentError('Unexpected spawn type $spawn.');
  }
}

/// Spawns a monster of a given breed.
class _BreedSpawn implements Spawn {
  final BreedRef _breed;

  _BreedSpawn(this._breed);

  @override
  void spawnBreed(int depth, AddMonster addMonster) {
    addMonster(_breed.breed);
  }
}

/// Drops a randomly selected breed with a given tag.
class _TagSpawn implements Spawn {
  /// The tag to choose from.
  final String _tag;

  _TagSpawn(this._tag);

  // TODO: Should the spawn be able to override or modify the depth?
  @override
  void spawnBreed(int depth, AddMonster addMonster) {
    for (var tries = 0; tries < 10; tries++) {
      var breed = Monsters.breeds.tryChoose(
        depth,
        tag: _tag,
        includeParents: false,
      );
      if (breed == null) continue;
      if (breed.flags.unique) continue;

      addMonster(breed);
      break;
    }
  }
}

/// A [Spawn] that repeats a spawn more than once.
class _RepeatSpawn implements Spawn {
  final int _minCount;
  final int _maxCount;
  final Spawn _spawn;

  _RepeatSpawn(this._minCount, this._maxCount, this._spawn);

  @override
  void spawnBreed(int depth, AddMonster addMonster) {
    var taper = 5;
    if (_maxCount > 3) taper = 4;
    if (_maxCount > 6) taper = 3;

    var count = rng.inclusive(_minCount, _maxCount) + rng.taper(0, taper);
    for (var i = 0; i < count; i++) {
      _spawn.spawnBreed(depth, addMonster);
    }
  }
}

/// A [Spawn] that spawns all of a list of child spawns.
class _AllOfSpawn implements Spawn {
  final List<Spawn> _spawns;

  _AllOfSpawn(this._spawns);

  @override
  void spawnBreed(int depth, AddMonster addMonster) {
    for (var spawn in _spawns) {
      spawn.spawnBreed(depth, addMonster);
    }
  }
}
