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
    area('Debugland', [
      level(() => new DebugArea(), numMonsters: 10, numItems: 1,
        breeds: [
          'floating eye'
        ],
        drop: [frequency(1, 'item', 10)],
        quest: tileType('the stairs', Tiles.stairs))
    ]);
    */

    area('Friendly Forest', 7.0, [
      level(() => new Forest(meadowInset: 8), numMonsters: 6, numItems: 2,
        breeds: [
          'butterfly',
          'field mouse',
          'vole',
          'robin',
          'garter snake',
          'frog'
        ],
        drop: [
          frequency(2, 'Flower'),
          frequency(1, 'magic', 1),
          frequency(1, 'Stick')
        ],
        quest: kill('fuzzy bunny', 1)),
      level(() => new Forest(meadowInset: 6), numMonsters: 8, numItems: 3,
        breeds: [
          'bee',
          'tree snake',
          'giant earthworm',
          'garden spider',
          'wasp',
          'forest sprite'
        ],
        drop: [
          frequency(2, 'Flower'),
          frequency(1, 'magic', 2),
          frequency(1, 'equipment', 1)
        ],
        quest: kill('fox', 1)),
    ]);

    area('Training Grounds', 6.0, [
      level(() => new TrainingGrounds(), numMonsters: 12, numItems: 4,
        breeds: [
          'white mouse',
          'mangy cur',
          'giant slug',
          'little brown bat',
          'stray cat',
          'giant cockroach',
          'simpering knave',
          'decrepit mage'
        ],
        drop: [
          frequency(3, 'magic', 2),
          frequency(1, 'treasure', 2),
          frequency(1, 'equipment', 2)
        ],
        quest: kill('wild dog', 3)),
      level(() => new TrainingGrounds(), numMonsters: 16, numItems: 5,
        breeds: [
          'brown spider',
          'crow',
          'wild dog',
          'sewer rat',
          'drunken priest',
        ],
        drop: [
          frequency(2, 'magic', 3),
          frequency(1, 'treasure', 3),
          frequency(1, 'equipment', 3)
        ],
        quest: kill('giant spider')),
      level(() => new TrainingGrounds(), numMonsters: 20, numItems: 6,
        breeds: [
          'giant spider',
          'unlucky ranger',
          'raven',
          'tree snake',
          'giant earthworm'
        ],
        drop: [
          frequency(2, 'magic', 4),
          frequency(2, 'treasure', 4),
          frequency(1, 'equipment', 4)
        ],
        quest: kill('giant cave worm'))
    ]);

    area('Goblin Stronghold', 5.0, [
      level(() => new GoblinStronghold(50), numMonsters: 20, numItems: 5,
        breeds: [
          'scurrilous imp',
          'vexing imp',
          'goblin peon',
          'house sprite',
          'wild dog',
          'blood worm',
          'giant cave worm',
          'green slime',
          'salamander'
        ],
        drop: [
          frequency(1, 'item', 4)
        ],
        quest: tileType('the stairs', Tiles.stairs)),
      level(() => new GoblinStronghold(70), numMonsters: 22, numItems: 6,
        breeds: [
          'imp incanter',
          'kobold',
          'goblin fighter',
          'giant bat',
          'mongrel',
          'giant centipede',
          'blue slime',
          'lizard guard',
        ],
        drop: [
          frequency(1, 'item', 5)
        ],
        quest: tileType('the stairs', Tiles.stairs)),
      level(() => new GoblinStronghold(90), numMonsters: 24, numItems: 7,
        breeds: [
          'imp warlock',
          'goblin archer',
          'goblin warrior',
          'red slime',
          'lizard protector',
          'floating eye',
          'plague rat'
        ],
        drop: [
          frequency(1, 'item', 6)
        ],
        quest: tileType('the stairs', Tiles.stairs)),
      level(() => new GoblinStronghold(110), numMonsters: 26, numItems: 8,
        breeds: [
          'armored lizard',
          'goblin mage',
        ],
        drop: [
          frequency(1, 'item', 7)
        ],
        quest: tileType('the stairs', Tiles.stairs))
    ]);
  }

  Level level(StageBuilder builder(), {
      int numMonsters, int numItems, List<String> breeds, List<Frequency> drop,
      QuestBuilder quest}) {
    var breedList = <Breed>[];

    for (var name in breeds) {
      var breed = Monsters.all[name];
      if (breed == null) throw 'Could not find breed "$name".';
      breedList.add(breed);
    }

    return new Level((stage) => builder().generate(stage), numMonsters,
        numItems, breedList, dropOneOf(drop), quest);
  }

  Area area(String name, num abundance, List<Level> levels) {
    var area = new Area(name, abundance, levels);
    Areas.all.add(area);
    return area;
  }

  QuestBuilder kill(String breed, [int count = 1]) =>
      new MonsterQuestBuilder(Monsters.all[breed], count);

  QuestBuilder tileType(String description, TileType type) =>
      new TileQuestBuilder(description, type);

  QuestBuilder floorItem(String type) =>
      new FloorItemQuestBuilder(Items.all[type]);
}
