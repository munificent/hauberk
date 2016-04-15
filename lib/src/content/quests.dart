import '../engine.dart';

/// Builds a quest for killing a certain number of a certain [Monster].
class MonsterQuestBuilder extends QuestBuilder {
  final Breed breed;
  final int count;

  MonsterQuestBuilder(this.breed, this.count);

  Quest generate(Stage stage) {
    // Make at least one "boss" one far away.
    if (count == 1) {
      var pos = stage.findDistantOpenTile(10);
      stage.spawnMonster(breed, pos);
    }

    // Scatter any others a little more freely.
    for (var i = 1; i < count; i++) {
      var pos = stage.findDistantOpenTile(3);
      stage.spawnMonster(breed, pos);
    }

    return new MonsterQuest(breed, count);
  }
}

/// A quest to kill a number of [Monster]s of a certain [Breed].
class MonsterQuest extends Quest {
  final Breed breed;
  int remaining;

  void announce(Log log) {
    log.quest("You must kill {1}.", new Quantity(remaining, breed));
  }

  MonsterQuest(this.breed, this.remaining);

  // TODO: Need to handle quest monster being killed by friendly fire.
  bool onKillMonster(Game game, Monster monster) {
    if (monster.breed == breed) {
      remaining--;

      if (remaining > 0) {
        game.log.quest("{1} await[s] death at your hands.",
            new Quantity(remaining, breed));
      }
    }

    return remaining <= 0;
  }
}

/// Builds a quest for finding an item on the ground in the [Stage].
class FloorItemQuestBuilder extends QuestBuilder {
  final ItemType itemType;

  FloorItemQuestBuilder(this.itemType);

  Quest generate(Stage stage) {
    final item = new Item(itemType);
    item.pos = stage.findDistantOpenTile(10);
    stage.items.add(item);

    return new ItemQuest(itemType);
  }
}

/// A quest to find an [Item] of a certain [ItemType].
class ItemQuest extends Quest {
  final ItemType itemType;

  ItemQuest(this.itemType);

  void announce(Log log) {
    // TODO: Handle a/an.
    log.quest("You must find a ${itemType.name}.");
  }

  bool onPickUpItem(Game game, Item item) => item.type == itemType;
}

/// Builds a quest for standing on a [TileType] on the [Stage].
class TileQuestBuilder extends QuestBuilder {
  final String description;
  final TileType tileType;

  TileQuestBuilder(this.description, this.tileType);

  Quest generate(Stage stage) {
    var pos = stage.findDistantOpenTile(5);
    stage[pos].type = tileType;

    return new TileQuest(description, tileType);
  }
}

/// A quest to stand on a tile of a certain [TileType].
class TileQuest extends Quest {
  final String description;
  final TileType tileType;

  TileQuest(this.description, this.tileType);

  void announce(Log log) {
    log.quest("You must find $description.");
  }

  bool onEnterTile(Game game, Tile tile) => tile.type == tileType;
}
