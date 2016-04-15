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

  /// Width of the stage for this area.
  final int width;

  /// Height of the stage for this area.
  final int height;

  /// The amount of food the level contains.
  ///
  /// A higher number here increases the rate that the [Hero] finds food as they
  /// explore the level.
  final num abundance;

  final List<Level> levels;

  Area(this.name, this.width, this.height, this.abundance, this.levels);

  Stage buildStage(Game game, int depth, HeroSave heroSave) {
    var level = levels[depth];

    var stage = new Stage(width, height, game);
    level.buildStage(stage);

    var heroPos = stage.findOpenTile();
    game.hero = new Hero(game, heroPos, heroSave);
    stage.addActor(game.hero);

    // Place the items.
    var numItems = rng.taper(level.numItems, 3);
    for (var i = 0; i < numItems; i++) {
      final itemDepth = pickDepth(depth);
      final drop = levels[itemDepth].floorDrop;

      drop.spawnDrop((item) {
        item.pos = stage.findOpenTile();
        stage.items.add(item);
      });
    }

    // Place the monsters.
    var numMonsters = rng.taper(level.numMonsters, 3);
    for (int i = 0; i < numMonsters; i++) {
      var monsterDepth = pickDepth(depth);

      // Place strong monsters farther from the hero.
      var tries = 1;
      if (monsterDepth > depth) tries = 1 + (monsterDepth - depth) * 2;
      var pos = stage.findDistantOpenTile(tries);

      var breed = rng.item(levels[monsterDepth].breeds);
      stage.spawnMonster(breed, pos);
    }

    game.quest = level.quest.generate(stage);
    game.quest.announce(game.log);

    // TODO: Temp. Wizard light it.
    /*
    for (var pos in stage.bounds) {
      for (var dir in Direction.all) {
        if (stage.bounds.contains(pos + dir) &&
            stage[pos + dir].isTransparent) {
          stage[pos].visible = true;
          break;
        }
      }
    }
    */

    return stage;
  }

  int pickDepth(int depth) {
    while (rng.oneIn(4) && depth > 0) depth--;
    while (rng.oneIn(6) && depth < levels.length - 1) depth++;

    return depth;
  }

  /// Selects a random [Breed] for the appropriate depth in this Area. Will
  /// occasionally select out-of-level breeds.
  Breed pickBreed(int level) {
    if (rng.oneIn(2)) {
      while (rng.oneIn(2) && level > 0) level--;
    } else {
      while (rng.oneIn(4) && level < levels.length - 1) level++;
    }

    return rng.item(levels[level].breeds);
  }
}

/// Describes one level in a [Area]. When the [Hero] enters a [Level] for an
/// area, this determines how that specific level is generated.
class Level {
  final BuildStage buildStage;
  final Drop floorDrop;
  final int numMonsters;
  final int numItems;

  /// The [Breed]s that appear in this [Level].
  final List<Breed> breeds;

  final QuestBuilder quest;

  Level(this.buildStage, this.numMonsters, this.numItems,
      this.floorDrop, this.breeds, this.quest);
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

/// Abstract class for a stage generator. An instance of this encapsulates
/// some dungeon generation algorithm. These are implemented in content.
typedef void BuildStage(Stage stage);
