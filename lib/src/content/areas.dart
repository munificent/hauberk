library content.areas;

import '../engine.dart';
import 'builder.dart';
import 'dungeon.dart';
import 'forest.dart';
import 'items.dart';
import 'monsters.dart';
import 'quests.dart';
import 'stage_builder.dart';

/// Builder class for defining [Area] objects.
class Areas extends ContentBuilder {
  static final List<Area> all = [];

  void build() {
    area('Friendly Forest', [
      level(new Forest(), numMonsters: 6, numItems: 2,
        breeds: [
          'white mouse',
          'robin',
          'garter snake'
        ],
        drop: [
          'Flower'
        ],
        quest: kill('fuzzy bunny', 1)),
    ]);

    area('Training Grounds', [
      level(new TrainingGrounds(), numMonsters: 12, numItems: 8,
        breeds: [
          'white mouse',
          'mangy cur',
          'giant slug',
          'little brown bat',
          'stray cat',
          'garden spider',
          'giant cockroach',
          'simpering knave'
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
        quest: floorItem('Magical Chalice')),
      level(new TrainingGrounds(), numMonsters: 20, numItems: 10,
        breeds: [
          'giant spider',
          'doddering old mage',
          'unlucky ranger', // TODO: Move to different level?
          'raven',
          'tree snake',
          'earthworm'
        ],
        drop: [
          'Soothing Balm',
          'Cudgel',
          'Dagger'
        ],
        quest: floorItem('Magical Chalice'))
    ]);

    area('Goblin Stronghold', [
      level(new GoblinStronghold(0), numMonsters: 18, numItems: 8,
        breeds: [
          'scurrilous imp',
          'impish incanter',
          'goblin peon',
          'wild dog'
        ],
        drop: [
          'Soothing Balm'
        ],
        quest: floorItem('Magical Chalice')),
      level(new GoblinStronghold(10), numMonsters: 20, numItems: 8,
        breeds: [
          'goblin warrior'
        ],
        drop: [
          'Soothing Balm'
        ],
        quest: floorItem('Magical Chalice'))
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

  QuestBuilder floorItem(String type) =>
      new FloorItemQuestBuilder(Items.all[type]);
}
