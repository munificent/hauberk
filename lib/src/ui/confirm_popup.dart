import 'package:malison/malison.dart';

import 'input.dart';
import 'popup.dart';

/// Modal dialog for letting the user confirm an action.
class ConfirmPopup extends Popup {
  final String _message;
  final Object _result;

  ConfirmPopup(this._message, this._result);

  List<String> get message => [_message];

  Map<String, String> get helpKeys =>
      const {"Y": "Yes", "N": "No", "Esc": "No"};

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop(null);
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.n:
        ui.pop(null);
        break;

      case KeyCode.y:
        ui.pop(_result);
        break;
    }

    return true;
  }
}
