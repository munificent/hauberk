import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import 'panel.dart';

class LogPanel extends Panel {
  final Log _log;

  LogPanel(this._log);

  @override
  void renderPanel(Terminal terminal) {
    terminal.clear();
    terminal.writeAt(
        0, terminal.height - 1, "─" * terminal.width, darkCoolGray);

    var y = terminal.height - 2;
    for (var i = _log.messages.length - 1; i >= 0 && y >= 0; i--) {
      var message = _log.messages[i];

      var text = message.text;
      if (message.count > 1) {
        text = '$text (x${message.count})';
      }

      var color = switch (message.type) {
        LogType.message => ash,
        LogType.error => red,
        LogType.quest => purple,
        LogType.gain => gold,
        LogType.help => peaGreen,
        LogType.cheat => aqua,
      };

      // Fade out all but the most recent message.
      if (i != _log.messages.length - 1) {
        color = color.blend(Color.black, 0.5);
      }

      var lines = Log.wordWrap(terminal.width, message.text);
      for (var j = lines.length - 1; j >= 0 && y >= 0; j--) {
        terminal.writeAt(0, y, lines[j], color);
        y--;
      }
    }
  }
}
