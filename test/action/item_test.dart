import 'package:hauberk/src/engine.dart';

import '../scenario/scenario.dart';

void main() {
  scenario("pick up item", (s) {
    s.setUpStage();
    var item = s.placeItem("Dagger");
    s.heroNextAction(PickUpAction(item));
    s.playUntilNeedsInput();
    // TODO: Should test that the item is actually in the inventory now.
    // Right now, this is just a test that the noun logging works.
    s.expectLog("You pick up the Dagger.");
  });
}
