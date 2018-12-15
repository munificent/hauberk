import 'package:malison/malison.dart';

import 'input.dart';
import 'popup.dart';

/// Modal dialog for letting the user confirm forfeiting the level.
class ForfeitPopup extends Popup {
  final bool _isTown;

  ForfeitPopup({bool isTown}) : _isTown = isTown ?? false;

  List<String> get message {
    if (_isTown) return const ["Return to main menu?"];

    return const [
      "Are you sure you want to forfeit the level?",
      "You will lose all items and experience gained in the dungeon."
    ];
  }

  Map<String, String> get helpKeys =>
      const {"Y": "Yes", "N": "No", "Esc": "No"};

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop(false);
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.n:
        ui.pop(false);
        break;

      case KeyCode.y:
        ui.pop(true);
        break;
    }

    return true;
  }

  bool update() => false;
}
