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
      level(new Forest(), numMonsters: 10, numItems: 5,
        breeds: [
          'butterfly',
          'field mouse',
          'robin',
          'garter snake',
          'frog'
        ],
        drop: [
          chanceOf(30, 'Flower'),
          chanceOf(40, 'Edible Mushroom'),
          chanceOf(20, 'Handful of Berries'),
          chanceOf(10, 'Stick')
        ],
        quest: kill('fuzzy bunny', 1)),
    ]);
    // TODO: Garden spider in level 2.

    area('Training Grounds', [
      level(new TrainingGrounds(), numMonsters: 12, numItems: 8,
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
          'Parchment',
          'Soothing Balm',
          'Scroll of Sidestepping',
        ],
        quest: kill('wild dog', 3)),
      level(new TrainingGrounds(), numMonsters: 16, numItems: 9,
        breeds: [
          'brown spider',
          'crow',
          'wild dog',
          'sewer rat',
          'drunken priest',
        ],
        drop: [
          'Parchment',
          'Soothing Balm',
          'Robe'
        ],
        quest: kill('giant spider')),
      level(new TrainingGrounds(), numMonsters: 20, numItems: 10,
        breeds: [
          'giant spider',
          'unlucky ranger', // TODO: Move to different level?
          'raven',
          'tree snake',
          'giant earthworm'
        ],
        drop: [
          'Soothing Balm',
          'Cudgel',
          'Dagger'
        ],
        quest: kill('giant cave worm'))
    ]);

    // TODO: Better floor drops.
    area('Goblin Stronghold', [
      level(new GoblinStronghold(50), numMonsters: 20, numItems: 8,
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
          'Soothing Balm'
        ],
        quest: tileType('the stairs', Tiles.stairs)),
      level(new GoblinStronghold(70), numMonsters: 24, numItems: 8,
        breeds: [
          'impish incanter',
          'goblin archer',
          'goblin warrior',
          'giant bat'
        ],
        drop: [
          'Soothing Balm'
        ],
        quest: tileType('the stairs', Tiles.stairs))
    ]);
  }

  Level level(StageBuilder builder, {
      int numMonsters, int numItems, List<String> breeds, drop,
      QuestBuilder quest}) {
    final breedList = <Breed>[];

    for (final name in breeds) breedList.add(Monsters.all[name]);

    return new Level(builder.generate, numMonsters, numItems, breedList,
        parseDrop(drop), quest);
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
