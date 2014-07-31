library hauberk.content.areas;

import '../engine.dart';
import 'builder.dart';
import 'debug_area.dart';
import 'dungeon.dart';
import 'forest.dart';
import 'items.dart';
import 'monsters.dart';
import 'quests.dart';
import 'stage_builder.dart';
import 'tiles.dart';

/// Builder class for defining [Area] objects.
class Areas extends ContentBuilder {
  static final List<Area> all = [];

  void build() {
    /*
    area('Debugland', 80, 40, 100.0, breeds: [
      'green slime'
    ], levels: [
      level(() => new DebugArea(), monsters: 2, items: 1,
        drop: [frequency(1, 'item', 10)],
        quest: tileType('the stairs', Tiles.stairs))
    ]);
    */

    area('Friendly Forest', 80, 34, 7.0, breeds: [
      'butterfly',
      'field mouse',
      'vole',
      'robin',
      'garter snake',
      'frog',
      'bee',
      'tree snake',
      'giant earthworm',
      'garden spider',
      'wasp',
      'forest sprite'
    ], levels: [
      level(() => new Forest(), monsters: 6, items: 2, drop: [
        frequency(2, 'Flower'),
        frequency(1, 'magic', 1),
        frequency(1, 'Stick')
      ], quest: kill('fuzzy bunny', 1)),
      level(() => new Forest(), monsters: 8, items: 3, drop: [
        frequency(2, 'Flower'),
        frequency(1, 'magic', 2),
        frequency(1, 'equipment', 1)
      ], quest: kill('fox', 1)),
    ]);

    area('Training Grounds', 100, 60, 15.0, breeds: [
      'white mouse',
      'mangy cur',
      'giant slug',
      'little brown bat',
      'stray cat',
      'giant cockroach',
      'simpering knave',
      'decrepit mage',
      'brown spider',
      'crow',
      'wild dog',
      'sewer rat',
      'drunken priest',
      'giant spider',
      'unlucky ranger',
      'raven',
      'tree snake',
      'giant earthworm'
    ], levels: [
      level(() => new TrainingGrounds(), monsters: 30, items: 6, drop: [
        frequency(3, 'magic', 2),
        frequency(1, 'treasure', 2),
        frequency(1, 'equipment', 2)
      ], quest: kill('wild dog', 3)),
      level(() => new TrainingGrounds(), monsters: 32, items: 7, drop: [
        frequency(2, 'magic', 3),
        frequency(1, 'treasure', 3),
        frequency(1, 'equipment', 3)
      ], quest: kill('giant spider')),
      level(() => new TrainingGrounds(), monsters: 34, items: 8, drop: [
        frequency(2, 'magic', 4),
        frequency(2, 'treasure', 4),
        frequency(1, 'equipment', 4)
      ], quest: kill('giant cave worm'))
    ]);

    area('Goblin Stronghold', 120, 70, 25.0, breeds: [
      'scurrilous imp',
      'vexing imp',
      'goblin peon',
      'house sprite',
      'wild dog',
      'blood worm',
      'giant cave worm',
      'green slime',
      'salamander',
      'imp incanter',
      'kobold',
      'goblin fighter',
      'giant bat',
      'mongrel',
      'giant centipede',
      'frosty slime',
      'lizard guard',
      'imp warlock',
      'goblin archer',
      'goblin warrior',
      'smoking slime',
      'lizard protector',
      'floating eye',
      'plague rat',
      'armored lizard',
      'goblin mage',
    ], levels: [
      level(() => new GoblinStronghold(500), monsters: 40, items: 10, drop: [
        frequency(1, 'item', 4)
      ], quest: tileType('the stairs', Tiles.stairs)),
      level(() => new GoblinStronghold(70), monsters: 42, items: 11, drop: [
        frequency(1, 'item', 5)
      ], quest: tileType('the stairs', Tiles.stairs)),
      level(() => new GoblinStronghold(90), monsters: 44, items: 12, drop: [
        frequency(1, 'item', 6)
      ], quest: tileType('the stairs', Tiles.stairs)),
      level(() => new GoblinStronghold(110), monsters: 46, items: 13, drop: [
        frequency(1, 'item', 7)
      ], quest: tileType('the stairs', Tiles.stairs))
    ]);
  }

  Level level(StageBuilder builder(), {
      int monsters, int items, List<Frequency> drop,
      QuestBuilder quest}) {
    return new Level((stage) => builder().generate(stage), monsters,
        items, dropOneOf(drop), quest);
  }

  void area(String name, int width, int height, num abundance,
      {List<String> breeds, List<Level> levels}) {
    var breedList = <Breed>[];
    for (var name in breeds) {
      var breed = Monsters.all[name];
      if (breed == null) throw 'Could not find breed "$name".';
      breedList.add(breed);
    }

    Areas.all.add(new Area(name, width, height, abundance, breedList, levels));
  }

  QuestBuilder kill(String breed, [int count = 1]) =>
      new MonsterQuestBuilder(Monsters.all[breed], count);

  QuestBuilder tileType(String description, TileType type) =>
      new TileQuestBuilder(description, type);

  QuestBuilder floorItem(String type) =>
      new FloorItemQuestBuilder(Items.all[type]);
}
