import '../../engine/action/item.dart';
import '../../engine/items/inventory.dart';
import '../../engine/items/item.dart';
import 'item_dialog.dart';

class DropDialog extends ItemDialog {
  @override
  List<ItemLocation> get allowedLocations => const [
    ItemLocation.inventory,
    ItemLocation.equipment,
  ];

  @override
  bool get needsCount => true;

  @override
  String get helpVerb => "Drop";

  DropDialog(super.gameScreen);

  @override
  String query(ItemLocation location) {
    return switch (location) {
      ItemLocation.inventory => "Drop which item?",
      ItemLocation.equipment => "Unequip and drop which item?",
      _ => throw AssertionError("Unreachable."),
    };
  }

  @override
  String queryCount(ItemLocation location) => 'Drop how many?';

  @override
  bool canSelect(Item item) => true;

  @override
  void selectItem(Item item, int count, ItemLocation location) {
    gameScreen.game.hero.setNextAction(DropAction(location, item, count));
    ui.pop();
  }
}
