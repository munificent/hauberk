import '../../engine/action/item.dart';
import '../../engine/items/inventory.dart';
import '../../engine/items/item.dart';
import 'item_dialog.dart';

class UseDialog extends ItemDialog {
  @override
  bool get needsCount => false;

  @override
  String get helpVerb => "Use";

  UseDialog(super.gameScreen);

  @override
  String query(ItemLocation location) {
    return switch (location) {
      ItemLocation.inventory || ItemLocation.equipment => 'Use which item?',
      ItemLocation.onGround => 'Pick up and use which item?',
      _ => throw AssertionError("Unreachable."),
    };
  }

  @override
  bool canSelect(Item item) => item.canUse;

  @override
  void selectItem(Item item, int count, ItemLocation location) {
    gameScreen.game.hero.setNextAction(UseAction(location, item));
    ui.pop();
  }
}
