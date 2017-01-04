import 'action.dart';
import '../game.dart';

/// An [Action] that marks all tiles containing [Item]s explored.
class DetectItemsAction extends Action {
  ActionResult onPerform() {
    var numFound = 0;

    game.stage.forEachItem((item, pos) {
      // Ignore items already found.
      if (game.stage[pos].isExplored) return;

      numFound++;
      game.stage[pos].isExplored = true;
      addEvent(EventType.detect, pos: pos);
    });

    if (numFound == 0) {
      return succeed('The darkness holds no secrets.');
    }

    return succeed('{1} sense[s] the treasures held in the dark!', actor);
  }
}
