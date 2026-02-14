import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../../hues.dart';
import '../input.dart';
import '../widget/draw.dart';
import 'data.dart';

class HelpDialog extends Screen<Input> {
  int _chapter = 0;
  int _scrollPosition = 0;
  int _viewHeight = 30;

  final List<String> _chapterNames = helpChapters.keys.toList();

  @override
  bool get isTransparent => true;

  @override
  bool handleInput(Input input) {
    switch (input) {
      // TODO: Shift to page up/down.

      case Input.n:
        _scroll(-1);
        return true;
      case Input.s:
        _scroll(1);
        return true;
      case Input.runN:
        _scroll(-_viewHeight);
        return true;
      case Input.runS:
        _scroll(_viewHeight);
        return true;

      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (alt) return false;

    switch (keyCode) {
      case KeyCode.tab:
        _changeChapter(shift ? -1 : 1);
        return true;

      default:
        return false;
    }
  }

  @override
  void render(Terminal terminal) {
    const width = 80;
    var frameTerminal = terminal.rect(
      (terminal.width - width) ~/ 2,
      0,
      width,
      terminal.height,
    );

    _viewHeight = frameTerminal.height - 4;

    frameTerminal.clear();

    Draw.frame(
      frameTerminal,
      width: frameTerminal.width,
      height: frameTerminal.height,
      label: "Help",
      selected: true,
    );

    for (var i = 0; i < _chapterNames.length; i++) {
      var color = i == _chapter ? UIHue.highlight : UIHue.selectable;
      frameTerminal.writeAt(2, (i * 2) + 2, _chapterNames[i], color);
    }

    var helpLines = helpChapters[_chapterNames[_chapter]]!;
    for (var i = 0; i < _viewHeight; i++) {
      var lineIndex = i + _scrollPosition;
      if (lineIndex < helpLines.length) {
        var line = helpLines[lineIndex];
        frameTerminal.writeAt(26, i + 2, line.text, line.color);
      }
    }

    Draw.scrollBar(
      frameTerminal,
      x: frameTerminal.width - 2,
      y: 2,
      height: _viewHeight,
      totalRows: helpLines.length,
      visibleRows: _viewHeight,
      scrollPosition: _scrollPosition,
    );

    Draw.helpKeys(terminal, {
      "Tab": "Next Chapter",
      "↕": "Scroll",
      "`": "Exit",
    });
  }

  void _changeChapter(int offset) {
    _chapter =
        (_chapter + offset + _chapterNames.length) % _chapterNames.length;
    _scrollPosition = 0;
    dirty();
  }

  void _scroll(int offset) {
    var helpLines = helpChapters[_chapterNames[_chapter]]!;
    _scrollPosition = (_scrollPosition + offset).clamp(
      0,
      helpLines.length - _viewHeight,
    );
    dirty();
  }
}

class Block {
  final BlockType type;
  final List<String> lines;

  const Block(this.type, this.lines);
}

enum BlockType { h1, h2, h3, text }

class HelpLine {
  final Color color;
  final String text;

  const HelpLine(this.text, {this.color = UIHue.text});
}
