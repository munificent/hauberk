import 'package:piecemeal/piecemeal.dart';

import 'breed.dart';
import 'game.dart';
import 'hero/hero.dart';
import 'items/item.dart';
import 'log.dart';
import 'monster.dart';
import 'stage.dart';

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
