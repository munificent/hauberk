import '../../engine/action/item.dart';
import '../../engine/item/inventory.dart';
import '../../engine/item/item.dart';
import '../game/game_screen.dart';
import 'item_dialog.dart';

// TODO: It queries for a count. But if there is only a single item, the hero
// automatically picks up the whole stack. Should it do the same here?
class PickUpDialog extends ItemDialog {
  @override
  List<ItemLocation> get allowedLocations => const [ItemLocation.onGround];

  @override
  bool get needsCount => true;

  @override
  String get helpVerb => "Pick up";

  PickUpDialog(GameScreen gameScreen)
    : super(gameScreen, ItemLocation.onGround);

  @override
  String query(ItemLocation location) => 'Pick up which item?';

  @override
  String queryCount(ItemLocation location) => 'Pick up how many?';

  @override
  bool canSelect(Item item) => true;

  @override
  void selectItem(Item item, int count, ItemLocation location) {
    // Pick up item and return to the game
    gameScreen.game.hero.setNextAction(PickUpAction(item));
    ui.pop();
  }
}
