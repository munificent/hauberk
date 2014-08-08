library hauberk.content.areas;

import '../debug.dart';
import '../engine.dart';
import 'debug_area.dart';
import 'drops.dart';
import 'dungeon.dart';
import 'forest.dart';
import 'items.dart';
import 'monsters.dart';
import 'quests.dart';
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

    area('Friendly Forest', 80, 34, 7.0);
    level(() => new Forest(), monsters: 6, items: 2, breeds: [
      'butterfly',
      'field mouse',
      'vole',
      'robin',
      'garter snake',
      'frog'
    ], drop: [
      frequency(2, 'Flower'),
      frequency(1, 'magic', 1),
      frequency(1, 'Stick')
    ], quest: kill('fuzzy bunny', 1));

    level(() => new Forest(), monsters: 8, items: 3, breeds: [
      'bee',
      'giant earthworm',
      'garden spider',
      'tree snake',
      'wasp',
      'forest sprite'
    ], drop: [
      frequency(2, 'Flower'),
      frequency(1, 'magic', 2),
      frequency(1, 'equipment', 1)
    ], quest: kill('fox', 1));

    area('Training Grounds', 100, 60, 15.0);
    level(() => new TrainingGrounds(), monsters: 30, items: 6, breeds: [
      'white mouse',
      'mangy cur',
      'giant slug',
      'little brown bat',
      'stray cat',
      'giant cockroach',
      'simpering knave',
      'decrepit mage'
    ], drop: [
      frequency(3, 'magic', 2),
      frequency(1, 'treasure', 2),
      frequency(1, 'equipment', 2)
    ], quest: kill('wild dog', 3));

    level(() => new TrainingGrounds(), monsters: 32, items: 7, breeds: [
      'brown spider',
      'crow',
      'wild dog',
      'sewer rat',
      'drunken priest'
    ], drop: [
      frequency(2, 'magic', 3),
      frequency(1, 'treasure', 3),
      frequency(1, 'equipment', 3)
    ], quest: kill('giant spider'));

    level(() => new TrainingGrounds(), monsters: 34, items: 8, breeds: [
      'giant spider',
      'unlucky ranger',
      'raven',
      'tree snake',
      'giant earthworm'
    ], drop: [
      frequency(2, 'magic', 4),
      frequency(2, 'treasure', 4),
      frequency(1, 'equipment', 4)
    ], quest: kill('giant cave worm'));

    area('Goblin Stronghold', 100, 60, 25.0,
        quest: tileType('the stairs', Tiles.stairs));
    level(() => new GoblinStronghold(400), monsters: 40, items: 10, breeds: [
      'scurrilous imp',
      'vexing imp',
      'goblin peon',
      'house sprite',
      'wild dog',
      'lizard guard',
      'blood worm',
      'giant cave worm'
    ], drop: [
      frequency(1, 'item', 4)
    ]);

    level(() => new GoblinStronghold(600), monsters: 42, items: 11, breeds: [
      'green slime',
      'juvenile salamander',
      'imp incanter',
      'kobold',
      'goblin fighter',
      'lizard protector',
      'giant bat'
    ], drop: [
      frequency(1, 'item', 5)
    ]);

    level(() => new GoblinStronghold(800), monsters: 44, items: 12,
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
      frequency(1, 'item', 6)
    ]);

    level(() => new GoblinStronghold(1000), monsters: 46, items: 13, breeds: [
      'kobold priest',
      'goblin warrior',
      'smoking slime',
      'cave snake',
      'floating eye',
      'plague rat',
      'salamander',
      'scaled guardian'
    ], drop: [
      frequency(1, 'item', 7)
    ]);

    level(() => new GoblinStronghold(1200), monsters: 48, items: 14,
        quest: kill("Erlkonig, the Goblin Prince"), breeds: [
      'goblin ranger',
      'goblin mage',
      'mischievous sprite',
      'cave bat',
      'fire worm',
      'sparkling slime',
      'saurian'
    ], drop: [
      frequency(1, 'item', 7)
    ]);
  }

  static void debugAreas() {
    area('Debugland', 80, 34, 100.0);
    level(() => new DebugArea(), monsters: 3, items: 6, breeds: [
      'salamander'
    ], drop: [
      frequency(1, 'Salve of Heat Resistance')
    ], quest: tileType('the stairs', Tiles.stairs));
  }
}

void area(String name, int width, int height, num abundance,
    {QuestBuilder quest}) {
  _quest = quest;
  _area = new Area(name, width, height, abundance, []);
  Areas.all.add(_area);
}

void level(StageBuilder builder(), {
    int monsters, int items, List<String> breeds, List<Frequency> drop,
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