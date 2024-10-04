import '../../engine/items/inventory.dart';
import '../../engine/items/item.dart';
import 'item_dialog.dart';

// TODO: Require confirmation when selling an item if it isn't a stack?
class SellDialog extends ItemDialog {
  final Inventory _shop;

  @override
  List<ItemLocation> get allowedLocations =>
      const [ItemLocation.inventory, ItemLocation.equipment];

  @override
  bool get needsCount => true;

  @override
  bool get showPrices => true;

  @override
  String get helpVerb => "Sell";

  SellDialog(super.gameScreen, this._shop);

  @override
  String query(ItemLocation location) => "Sell which item?";

  @override
  String queryCount(ItemLocation location) => "Sell how many?";

  @override
  bool canSelect(Item item) => item.price != 0;

  @override
  int getPrice(Item item) => (item.price * 0.75).floor();

  @override
  void selectItem(Item item, int count, ItemLocation location) {
    transfer(item, count, _shop);
  }

  @override
  void afterTransfer(Item item, int count) {
    var itemText = item.clone(count).toString();
    var price = getPrice(item) * count;
    // TODO: The help text overlaps the log pane, so this isn't very useful.
    gameScreen.game.log.message("You sell $itemText for $price gold.");
    gameScreen.game.hero.gold += price;
  }
}
