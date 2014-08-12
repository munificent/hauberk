library hauberk.engine.action.detection;

import 'action.dart';
import '../game.dart';

/// An [Action] that marks all tiles containing [Item]s explored.
class DetectItemsAction extends Action {
  ActionResult onPerform() {
    var numFound = 0;
    for (var item in game.stage.items) {
      // Ignore items already found.
      if (game.stage[item.pos].isExplored) continue;

      numFound++;
      game.stage[item.pos].isExplored = true;
      addEvent(EventType.DETECT, pos: item.pos);
    }

    if (numFound == 0) {
      return succeed('The darkness holds no secrets.');
    }

    return succeed('{1} sense[s] the treasures held in the dark!', actor);
  }
}
