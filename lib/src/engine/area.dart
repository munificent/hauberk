library hauberk.engine.area;

import 'package:piecemeal/piecemeal.dart';

import 'breed.dart';
import 'game.dart';
import 'hero/hero.dart';
import 'items/item.dart';
import 'log.dart';
import 'monster.dart';
import 'stage.dart';

class Area {
  final String name;

  /// The amount of food the level contains.
  ///
  /// A higher number here increases the rate that the [Hero] finds food as they
  /// explore the level.
  final num abundance;

  final List<Level> levels;

  Area(this.name, this.abundance, this.levels);

  Vec buildStage(Game game, int depth, HeroSave heroSave) {
    var stage = game.stage;
    var area = levels[depth];

    area.buildStage(stage);

    var heroPos = stage.findOpenTile();
    game.hero = new Hero(game, heroPos, heroSave);
    stage.addActor(game.hero);

    // Place the items.
    var numItems = rng.taper(area.numItems, 3);
    for (var i = 0; i < numItems; i++) {
      final itemDepth = pickDepth(depth);
      final drop = levels[itemDepth].floorDrop;

      drop.spawnDrop((item) {
        item.pos = stage.findOpenTile();
        stage.items.add(item);
      });
    }

    // Place the monsters.
    final numMonsters = rng.taper(area.numMonsters, 3);
    for (int i = 0; i < numMonsters; i++) {
      final monsterDepth = pickDepth(depth);

      // Place strong monsters farther from the hero.
      var tries = 1;
      if (monsterDepth > depth) tries = 1 + (monsterDepth - depth) * 2;
      final pos = stage.findDistantOpenTile(tries);

      final breed = rng.item(levels[monsterDepth].breeds);
      stage.spawnMonster(breed, pos);
    }

    stage.finishBuild();

    game.quest = area.quest.generate(stage);
    game.quest.announce(game.log);

    // TODO: Temp. Wizard light it.
    /*
    for (var pos in stage.bounds) {
      for (var dir in Direction.ALL) {
        if (stage.bounds.contains(pos + dir) &&
            stage[pos + dir].isTransparent) {
          stage[pos].visible = true;
          break;
        }
      }
    }
    */

    return heroPos;
  }

  int pickDepth(int depth) {
    while (rng.oneIn(4) && depth > 0) depth--;
    while (rng.oneIn(6) && depth < levels.length - 1) depth++;

    return depth;
  }

  /// Selects a random [Breed] for the appropriate depth in this Area. Will
  /// occasionally select out-of-depth breeds.
  Breed pickBreed(int depth) {
    if (rng.oneIn(2)) {
      while (rng.oneIn(2) && depth > 0) depth--;
    } else {
      while (rng.oneIn(4) && depth < levels.length - 1) depth++;
    }

    return rng.item(levels[depth].breeds);
  }
}

/// Describes one level in a [Area]. When the [Hero] enters a [Level] for an
/// area, this determines how that specific level is generated.
class Level {
  final BuildStage buildStage;
  final List<Breed> breeds;
  final Drop floorDrop;
  final int numMonsters;
  final int numItems;
  final QuestBuilder quest;

  Level(this.buildStage, this.numMonsters, this.numItems,
      this.breeds, this.floorDrop, this.quest);
}

abstract class QuestBuilder {
  // TODO: Kinds of quests:
  // - Get a number or set of items
  // - Explore the entire dungeon
  // - Find a certain item and use it on a certain monster
  // - Get dropped item from monster and use elsewhere.
  //
  // Restrictions that can modify the above:
  // - Complete quest within a turn limit
  // - Complete quest without killing any monsters
  // - Complete quest without using any items

  Quest generate(Stage stage);
}

abstract class Quest {
  bool _isComplete = false;
  bool get isComplete => _isComplete;

  /// Logs the goal of this quest so the player knows what to do.
  void announce(Log log);

  bool pickUpItem(Game game, Item item) {
    if (onPickUpItem(game, item)) _complete(game);
    return _isComplete;
  }

  bool onPickUpItem(Game game, Item item) => false;

  bool killMonster(Game game, Monster monster) {
    if (onKillMonster(game, monster)) _complete(game);
    return _isComplete;
  }

  bool onKillMonster(Game game, Monster monster) => false;

  bool enterTile(Game game, Tile tile) {
    if (onEnterTile(game, tile)) _complete(game);
    return _isComplete;
  }

  bool onEnterTile(Game game, Tile tile) => false;

  void _complete(Game game) {
    // Only complete once.
    if (_isComplete) return;

    _isComplete = true;
    game.log.quest(
        'You have completed your quest! Press "q" to exit the level.');
  }
}

/// Abstract class for a stage generator. An instance of this encapsulation
/// some dungeon generation algorithm. These are implemented in content.
typedef void BuildStage(Stage stage);
