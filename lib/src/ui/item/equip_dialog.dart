import '../../engine/action/item.dart';
import '../../engine/item/inventory.dart';
import '../../engine/item/item.dart';
import 'item_dialog.dart';

class EquipDialog extends ItemDialog {
  @override
  bool get needsCount => false;

  @override
  String get helpVerb => "Equip";

  EquipDialog(super.gameScreen);

  @override
  String query(ItemLocation location) {
    return switch (location) {
      ItemLocation.inventory => 'Equip which item?',
      ItemLocation.equipment => 'Unequip which item?',
      ItemLocation.onGround => 'Pick up and equip which item?',
      _ => throw AssertionError("Unreachable."),
    };
  }

  @override
  bool canSelect(Item item) => item.canEquip;

  @override
  void selectItem(Item item, int count, ItemLocation location) {
    gameScreen.game.hero.setNextAction(EquipAction(location, item));
    ui.pop();
  }
}
