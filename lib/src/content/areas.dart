library dngn.content.areas;

import '../engine.dart';
import 'builder.dart';
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
    area('Friendly Forest', [
      level(() => new Forest(meadowInset: 8), numMonsters: 8, numItems: 6,
        breeds: [
          'butterfly',
          'field mouse',
          'robin',
          'garter snake',
          'frog'
        ],
        drop: [
          chanceOf(30, 'Flower'),
          chanceOf(40, 'food:1'),
          chanceOf(10, 'magic:1'),
          chanceOf(20, 'Stick')
        ],
        quest: kill('fuzzy bunny', 1)),
      level(() => new Forest(meadowInset: 6), numMonsters: 10, numItems: 8,
        breeds: [
          'bee',
          'vole',
          'tree snake',
          'giant earthworm',
          'garden spider',
          'wasp'
        ],
        drop: [
          chanceOf(20, 'Flower'),
          chanceOf(40, 'food:1'),
          chanceOf(25, 'magic:1'),
          chanceOf(15, 'Stick')
        ],
        quest: kill('fox', 1)),
    ]);

    area('Training Grounds', [
      level(() => new TrainingGrounds(), numMonsters: 12, numItems: 8,
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
          'food:1',
          'magic:1'
        ],
        quest: kill('wild dog', 3)),
      level(() => new TrainingGrounds(), numMonsters: 16, numItems: 9,
        breeds: [
          'brown spider',
          'crow',
          'wild dog',
          'sewer rat',
          'drunken priest',
        ],
        drop: [
          'food:3',
          'magic:2',
          'equipment:2'
        ],
        quest: kill('giant spider')),
      level(() => new TrainingGrounds(), numMonsters: 20, numItems: 10,
        breeds: [
          'giant spider',
          'unlucky ranger', // TODO: Move to different level?
          'raven',
          'tree snake',
          'giant earthworm'
        ],
        drop: [
          'food:4',
          'magic:3',
          'equipment:3'
        ],
        quest: kill('giant cave worm'))
    ]);

    area('Goblin Stronghold', [
      level(() => new GoblinStronghold(50), numMonsters: 20, numItems: 8,
        breeds: [
          'scurrilous imp',
          'vexing imp',
          'goblin peon',
          'wild dog',
          'maggot',
          'giant cave worm',
          'green slime'
        ],
        drop: [
          'food:3',
          'magic:3',
          'equipment:3'
        ],
        quest: tileType('the stairs', Tiles.stairs)),
      level(() => new GoblinStronghold(70), numMonsters: 24, numItems: 9,
        breeds: [
          'impish incanter',
          'goblin archer',
          'goblin warrior',
          'giant bat',
          'mongrel',
          'giant centipede'
        ],
        drop: [
          'food:4',
          'magic:4',
          'equipment:4'
        ],
        quest: tileType('the stairs', Tiles.stairs))
    ]);
  }

  Level level(StageBuilder builder(), {
      int numMonsters, int numItems, List<String> breeds, drop,
      QuestBuilder quest}) {
    final breedList = <Breed>[];

    for (final name in breeds) breedList.add(Monsters.all[name]);

    return new Level((stage) => builder().generate(stage), numMonsters,
        numItems, breedList, parseDrop(drop), quest);
  }

  Area area(String name, List<Level> levels) {
    final area = new Area(name, levels);
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
