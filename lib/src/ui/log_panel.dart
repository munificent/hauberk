import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';

class LogPanel {
  final Log _log;

  LogPanel(this._log);

  void render(Terminal terminal) {
    var y = 0;

    for (var message in _log.messages) {
      Color color;
      var messagesLength = _log.messages.length - 1;

      switch (message.type) {
        case LogType.message:
          color = ash;
          break;
        case LogType.error:
          color = brickRed;
          break;
        case LogType.quest:
          color = violet;
          break;
        case LogType.gain:
          color = gold;
          break;
        case LogType.help:
          color = peaGreen;
          break;
        case LogType.cheat:
          color = seaGreen;
          break;
      }

      if (y != messagesLength) {
        color = color.blend(Color.black, 0.5);
      }

      terminal.writeAt(0, y, message.text, color);

      if (message.count > 1) {
        terminal.writeAt(
            message.text.length, y, ' (x${message.count})', steelGray);
      }
      y++;
    }
  }

}