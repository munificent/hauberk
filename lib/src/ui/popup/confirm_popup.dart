import 'package:malison/malison.dart';

import '../input.dart';
import 'popup.dart';

/// Modal dialog for letting the user confirm an action.
class ConfirmPopup extends Popup {
  final String _message;
  final Object _result;

  ConfirmPopup(this._message, this._result);

  @override
  List<String> get message => [_message];

  @override
  Map<String, String> get helpKeys => const {"Y": "Yes", "N": "No", "`": "No"};

  @override
  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.n:
        ui.pop();

      case KeyCode.y:
        ui.pop(_result);
    }

    return true;
  }
}
