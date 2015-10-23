library hauberk.content.areas;

import 'package:piecemeal/piecemeal.dart';

import '../debug.dart';
import '../engine.dart';
import 'debug_area.dart';
import 'drops.dart';
import 'forest.dart';
import 'items.dart';
import 'dungeon.dart';
import 'monsters.dart';
import 'quests.dart';
import 'room_decorator.dart';
import 'stage_builder.dart';
import 'tiles.dart';

/// The current [Area] being defined.
Area _area;

/// The default [QuestBuilder] for the current [Area].
///
/// If the [level] call doesn't specify a quest, this one is used.
QuestBuilder _quest;

/// Builder class for defining [Area] objects.
class Areas {
  static final List<Area> all = [];

  static void initialize() {
    if (Debug.ENABLED) debugAreas();

    area('Friendly Forest', 80, 34, 3.0);
    level(() => new Forest(), monsters: 14, items: 6, breeds: [
      'butterfly',
      'field mouse',
      'vole',
      'robin',
      'garter snake',
      'frog',
      'slug',
    ], drop: [
      rarity(1, 'Rock'),
      rarity(1, 'Flower'),
      rarity(1, 'treasure', 1),
      rarity(2, 'Stick'),
      rarity(3, 'magic', 1)
    ], quest: kill('fuzzy bunny', 1));

    level(() => new Forest(), monsters: 18, items: 8, breeds: [
      'white mouse',
      'bee',
      'giant earthworm',
      'garden spider',
      'tree snake',
      'wasp',
      'forest sprite'
    ], drop: [
      rarity(1, 'Rock'),
      rarity(2, 'Flower'),
      rarity(3, 'Stick'),
      rarity(1, 'treasure', 1),
      rarity(2, 'magic', 2),
      rarity(2, 'equipment', 2)
    ], quest: kill('fox', 1));

    area('Training Grounds', 79, 33, 7.0);
    level(() => new TrainingGrounds(), monsters: 40, items: 6, breeds: [
      'mangy cur',
      'giant slug',
      'brown bat',
      'stray cat',
      'giant cockroach',
      'simpering knave',
      'decrepit mage',
      'lazy eye'
    ], drop: [
      rarity(3, 'Rock'),
      rarity(3, 'magic', 2),
      rarity(1, 'treasure', 2),
      rarity(1, 'equipment', 2)
    ], quest: kill('wild dog', 3));

    level(() => new TrainingGrounds(), monsters: 46, items: 7, breeds: [
      'brown spider',
      'crow',
      'wild dog',
      'sewer rat',
      'drunken priest'
    ], drop: [
      rarity(3, 'Rock'),
      rarity(2, 'magic', 3),
      rarity(1, 'treasure', 3),
      rarity(1, 'equipment', 3)
    ], quest: kill('giant spider'));

    level(() => new TrainingGrounds(), monsters: 52, items: 8, breeds: [
      'giant spider',
      'unlucky ranger',
      'raven',
      'tree snake',
      'giant earthworm'
    ], drop: [
      rarity(3, 'Rock'),
      rarity(2, 'magic', 4),
      rarity(2, 'treasure', 4),
      rarity(1, 'equipment', 4)
    ], quest: kill('giant cave worm'));

    area('Goblin Stronghold', 85, 39, 12.0,
        quest: tileType('the stairs', Tiles.stairs));
    level(() => new GoblinStronghold(), monsters: 48, items: 12, breeds: [
      'scurrilous imp',
      'vexing imp',
      'goblin peon',
      'house sprite',
      'wild dog',
      'lizard guard',
      'blood worm',
      'giant cave worm'
    ], drop: [
      rarity(10, 'Rock'),
      rarity(1, 'item', 4)
    ]);

    level(() => new GoblinStronghold(), monsters: 50, items: 13, breeds: [
      'green slime',
      'juvenile salamander',
      'imp incanter',
      'kobold',
      'goblin fighter',
      'lizard protector',
      'giant bat'
    ], drop: [
      rarity(10, 'Rock'),
      rarity(1, 'item', 5)
    ]);

    level(() => new GoblinStronghold(), monsters: 52, items: 14,
        quest: kill("Feng"), breeds: [
      'kobold shaman',
      'mongrel',
      'giant centipede',
      'frosty slime',
      'kobold trickster',
      'imp warlock',
      'goblin archer',
      'armored lizard',
    ], drop: [
      rarity(10, 'Rock'),
      rarity(1, 'item', 6)
    ]);

    level(() => new GoblinStronghold(), monsters: 54, items: 15, breeds: [
      'kobold priest',
      'goblin warrior',
      'smoking slime',
      'cave snake',
      'floating eye',
      'plague rat',
      'salamander',
      'scaled guardian'
    ], drop: [
      rarity(10, 'Rock'),
      rarity(1, 'item', 7)
    ]);

    level(() => new GoblinStronghold(), monsters: 56, items: 16,
        quest: kill("Erlkonig, the Goblin Prince"), breeds: [
      'goblin ranger',
      'goblin mage',
      'mischievous sprite',
      'cave bat',
      'fire worm',
      'sparkling slime',
      'saurian'
    ], drop: [
      rarity(10, 'Rock'),
      rarity(1, 'item', 7)
    ]);
  }

  static void debugAreas() {
    area('Debugland', 80, 34, 100.0);

    level(() => new DebugArea(), monsters: 1, items: 20, breeds: [
      'field mouse',
    ], drop: [
      rarity(1, 'treasure', 10),
      rarity(1, 'treasure', 30),
      rarity(1, 'treasure', 50),
      rarity(1, 'treasure', 70)
    ], quest: kill('field mouse', 1));

    level(() => new DebugArea(), monsters: 6, items: 20, breeds: [
      'saurian'
    ], drop: [
      rarity(1, 'dagger', 4)
    ], quest: tileType('the stairs', Tiles.stairs));
  }
}

class TrainingGrounds extends Dungeon {
  int get numRoomTries => 60;
}

class GoblinStronghold extends Dungeon with RoomDecorator {
  int get numRoomTries => 140;
  int get windingPercent => 70;
  int get roomExtraSize => 1;

  void onDecorateRoom(Rect room) {
    if (rng.oneIn(2) && decorateRoundedCorners(room)) return;
    if (rng.oneIn(5) && decorateTable(room)) return;
    if (rng.oneIn(10) && decorateInnerRoom(room)) return;
  }
}

void area(String name, int width, int height, num abundance,
    {QuestBuilder quest}) {
  _quest = quest;
  _area = new Area(name, width, height, abundance, []);
  Areas.all.add(_area);
}

void level(StageBuilder builder(), {
    int monsters, int items, List<String> breeds, List<Rarity> drop,
    QuestBuilder quest}) {
  if (quest == null) quest = _quest;

  var breedList = <Breed>[];
  for (var name in breeds) {
    var breed = Monsters.all[name];
    if (breed == null) throw 'Could not find breed "$name".';
    breedList.add(breed);
  }

  _area.levels.add(new Level((stage) => builder().generate(stage), monsters,
      items, dropOneOf(drop), breedList, quest));
}

QuestBuilder kill(String breed, [int count = 1]) =>
    new MonsterQuestBuilder(Monsters.all[breed], count);

QuestBuilder tileType(String description, TileType type) =>
    new TileQuestBuilder(description, type);

QuestBuilder floorItem(String type) =>
    new FloorItemQuestBuilder(Items.all[type]);