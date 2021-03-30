import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'monsters.dart';

Spawn spawnBreed(String name) => _BreedSpawn(BreedRef(name));

Spawn spawnTag(String tag) => _TagSpawn(tag);

Spawn repeatSpawn(int min, int max, Spawn spawn) =>
    _RepeatSpawn(min, max, spawn);

Spawn spawnAll(List<Spawn> spawns) => _AllOfSpawn(spawns);

/// Spawns a monster of a given breed.
class _BreedSpawn implements Spawn {
  final BreedRef _breed;

  _BreedSpawn(this._breed);

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
  void spawnBreed(int depth, AddMonster addMonster) {
    for (var tries = 0; tries < 10; tries++) {
      var breed =
          Monsters.breeds.tryChoose(depth, tag: _tag, includeParents: false);
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

  void spawnBreed(int depth, AddMonster addMonster) {
    for (var spawn in _spawns) {
      spawn.spawnBreed(depth, addMonster);
    }
  }
}
