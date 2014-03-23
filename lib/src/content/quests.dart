library content.quests;

import '../engine.dart';

/// Builds a quest for killing a certain number of a certain [Monster].
class MonsterQuestBuilder extends QuestBuilder {
  final Breed breed;
  final int count;

  MonsterQuestBuilder(this.breed, this.count);

  Quest generate(Stage stage) {
    for (var i = 0; i < count; i++) {
      var pos = stage.findOpenTile();
      stage.spawnMonster(breed, pos);
    }

    return new MonsterQuest(breed, count);
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
    // TODO(bob): Handle a/an.
    log.quest("You must find a ${itemType.name}.");
  }

  bool onPickUpItem(Game game, Item item) => item.type == itemType;
}

/// A quest to kill a number of [Monster]s of a certain [Breed].
class MonsterQuest extends Quest {
  final Breed breed;
  int remaining;

  void announce(Log log) {
    // TODO(bob): Handle pluralization correctly.
    log.quest("You must kill $remaining ${breed.name}s.");
  }

  MonsterQuest(this.breed, this.remaining);

  bool onKillMonster(Game game, Monster monster) {
    if (monster.breed == breed) {
      remaining--;

      if (remaining > 0) {
        // TODO(bob): Handle pluralization correctly.
        game.log.quest("$remaining more ${breed.name}s await death at your hands.");
      }
    }

    return remaining <= 0;
  }
}
