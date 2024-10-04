import '../../engine/items/inventory.dart';
import '../../engine/items/item.dart';
import 'item_dialog.dart';

abstract class _PutDialog extends ItemDialog {
  @override
  List<ItemLocation> get allowedLocations =>
      const [ItemLocation.inventory, ItemLocation.equipment];

  @override
  bool get needsCount => true;

  @override
  String get helpVerb => "Put";

  _PutDialog(super.gameScreen);

  @override
  String query(ItemLocation location) => "Put which item?";

  @override
  String queryCount(ItemLocation location) => "Put how many?";

  @override
  bool canSelect(Item item) => true;
}

class PutCrucibleDialog extends _PutDialog {
  final void Function() _onTransfer;

  PutCrucibleDialog(super.gameScreen, this._onTransfer);

  @override
  void selectItem(Item item, int count, ItemLocation location) {
    transfer(item, count, gameScreen.game.hero.save.crucible);
  }

  @override
  void afterTransfer(Item item, int count) {
    gameScreen.game.log
        .message("You place ${item.clone(count)} into the crucible.");
    _onTransfer();
  }
}

class PutHomeDialog extends _PutDialog {
  PutHomeDialog(super.gameScreen);

  @override
  void selectItem(Item item, int count, ItemLocation location) {
    transfer(item, count, gameScreen.game.hero.save.home);
  }

  @override
  void afterTransfer(Item item, int count) {
    gameScreen.game.log
        .message("You put ${item.clone(count)} safely into your home.");
  }
}
