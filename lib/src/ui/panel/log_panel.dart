import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import 'panel.dart';

class LogPanel extends Panel {
  final Log _log;

  LogPanel(this._log);

  @override
  void renderPanel(Terminal terminal) {
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height);
    terminal.writeAt(2, 0, " Messages ", UIHue.text);

    var y = terminal.height - 2;
    for (var i = _log.messages.length - 1; i >= 0 && y > 0; i--) {
      var message = _log.messages[i];

      Color color;

      switch (message.type) {
        case LogType.message:
          color = ash;
        case LogType.error:
          color = red;
        case LogType.quest:
          color = purple;
        case LogType.gain:
          color = gold;
        case LogType.help:
          color = peaGreen;
        case LogType.cheat:
          color = aqua;
      }

      if (i != _log.messages.length - 1) {
        color = color.blend(Color.black, 0.5);
      }

      terminal.writeAt(1, y, message.text, color);

      if (message.count > 1) {
        terminal.writeAt(
            message.text.length + 1, y, ' (x${message.count})', darkCoolGray);
      }

      y--;
    }
  }
}
