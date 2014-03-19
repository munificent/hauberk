library content;

import 'engine.dart';

import 'content/areas.dart';
import 'content/items.dart';
import 'content/monsters.dart';
import 'content/recipes.dart';
import 'content/skills.dart';
import 'content/tiles.dart';

Content createContent() {
  // Note: The order is significant here. For example, monster drops will
  // reference items, which need to have already been created.
  new TileBuilder().build();
  new SkillBuilder().build();
  new ItemBuilder().build();
  new MonsterBuilder().build();
  new AreaBuilder().build();
  new RecipeBuilder().build();

  // The items that a new hero starts with.
  final heroItems = [
    items['Mending Salve'],
    items['Scroll of Sidestepping']
  ];

  return new Content(areas, breeds, items, recipes, skills, heroItems);
}
