import '../../engine/action/toss.dart';
import '../../engine/core/combat.dart';
import '../../engine/items/inventory.dart';
import '../../engine/items/item.dart';
import '../target_dialog.dart';
import 'item_dialog.dart';

class TossDialog extends ItemDialog {
  @override
  bool get needsCount => false;

  @override
  String get helpVerb => "Toss";

  TossDialog(super.gameScreen);

  @override
  String query(ItemLocation location) {
    return switch (location) {
      ItemLocation.inventory => 'Throw which item?',
      ItemLocation.equipment => 'Unequip and throw which item?',
      ItemLocation.onGround => 'Pick up and throw which item?',
      _ => throw AssertionError("Unreachable."),
    };
  }

  @override
  bool canSelect(Item item) => item.canToss;

  @override
  void selectItem(Item item, int count, ItemLocation location) {
    // Create the hit now so range modifiers can be calculated before the
    // target is chosen.
    var hit = item.toss!.attack.createHit();
    gameScreen.game.hero.modifyHit(hit, HitType.toss);

    // Now we need a target.
    ui.goTo(
      TargetDialog(gameScreen, hit.range, (target) {
        gameScreen.game.hero.setNextAction(
          TossAction(location, item, hit, target),
        );
      }),
    );
  }
}
