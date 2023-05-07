import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/tiles.dart';
import 'package:hauberk/src/engine.dart';
import 'package:piecemeal/piecemeal.dart';
import 'package:test/test.dart';

Scenario? _scenario;

// TODO: Should this use the real game content?
Content _content = createContent();

void scenario(String name, void Function() body) {
  test(name, () {
    _scenario = Scenario();
    try {
      body();
    } finally {
      _scenario = null;
    }
  });
}

void setUpStage(String stage) => _scenario!.setUpStage(stage);

void stage(String stage) {}

void heroRun(Direction direction) => _scenario!.heroRun(direction);

void playUntilNeedsInput() => _scenario!.playUntilNeedsInput();

void expectHeroAt(int label) => _scenario!.expectHeroAt(label);

class Scenario {
  /// Numeric labels for positions on the stage.
  final Map<int, Vec> _labels = {};

  Game? _game;

  void setUpStage(String stageDescriptor) {
    // TODO: Allow optional parameter to add more types.
    var tileTypes = {
      "#": Tiles.flagstoneWall,
      ".": Tiles.flagstoneFloor,
      "@": Tiles.flagstoneFloor,
      "1": Tiles.flagstoneFloor,
      "2": Tiles.flagstoneFloor,
      "3": Tiles.flagstoneFloor,
      "4": Tiles.flagstoneFloor,
      "5": Tiles.flagstoneFloor,
      "6": Tiles.flagstoneFloor,
      "7": Tiles.flagstoneFloor,
      "8": Tiles.flagstoneFloor,
      "9": Tiles.flagstoneFloor,
    };

    assert(_game == null, "Already set up stage.");

    var lines = stageDescriptor.split("\n").map((line) => line.trim()).toList();
    if (lines.first.isEmpty) lines.removeAt(0);
    if (lines.last.isEmpty) lines.removeLast();

    assert(lines.isNotEmpty, "Need non-empty stage description.");
    var width = lines.first.length;
    for (var y = 0; y < lines.length; y++) {
      assert(lines[y].length == width,
          "Line $y doesn't have expected width $width.");
    }

    var save = _content.createHero("Test");
    var game =
        Game(_content, 1, width: lines.first.length, height: lines.length);
    _game = game;

    var stage = game.stage;
    Vec? heroPos;
    for (var y = 0; y < lines.length; y++) {
      var line = lines[y];
      for (var x = 0; x < line.length; x++) {
        var char = line[x];
        var tile = tileTypes[char];
        assert(tile != null, "Unknown tile char '$char'.");
        stage.get(x, y).type = tile!;

        // Keep track of position markers.
        switch (char) {
          case "@":
            heroPos = Vec(x, y);
          case "1":
          case "2":
          case "3":
          case "4":
          case "5":
          case "6":
          case "7":
          case "8":
          case "9":
            _labels[int.parse(char)] = Vec(x, y);
        }
      }
    }

    assert(heroPos != null, "No hero '@' character.");
    game.initHero(heroPos!, save);
  }

  void heroRun(Direction direction) {
    _game!.hero.run(direction);
  }

  void playUntilNeedsInput() {
    var game = _game!;
    while (true) {
      var result = game.update();
      if (!result.madeProgress) break;
    }
  }

  void expectHeroAt(int label) {
    var pos = _labels[label]!;
    expect(_game!.hero.pos, pos);
  }
}
