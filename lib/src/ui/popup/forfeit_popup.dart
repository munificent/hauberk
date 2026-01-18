import 'package:malison/malison.dart';

import '../input.dart';
import 'popup.dart';

/// Modal dialog for letting the user confirm forfeiting the level.
class ForfeitPopup extends Popup {
  final bool _isTown;

  ForfeitPopup({required bool isTown}) : _isTown = isTown;

  @override
  List<String> get message {
    if (_isTown) return const ["Return to main menu?"];

    return const [
      "Are you sure you want to forfeit the level?",
      "You will lose all items and experience gained in the dungeon.",
    ];
  }

  @override
  Map<String, String> get helpKeys => const {"Y": "Yes", "N": "No", "`": "No"};

  @override
  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop(false);
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.n:
        ui.pop(false);

      case KeyCode.y:
        ui.pop(true);
    }

    return true;
  }

  @override
  bool update() => false;
}
