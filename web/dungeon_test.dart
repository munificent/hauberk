library hauberk.web.dungeon_test;

import 'dart:html' as html;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/tiles.dart';

html.CanvasElement canvas;
html.CanvasRenderingContext2D context;

var content = createContent();
var area = 1;
var level = 0;
var heroClass = new Warrior();
var save = new HeroSave("Hero", heroClass);

main() {
  canvas = html.querySelector("canvas") as html.CanvasElement;
  context = canvas.context2D;

  canvas.onClick.listen((_) {
    render();
  });

  render();
}

render() {
  var game = new Game(content.areas[area], level, content, save);

  context.fillStyle = '#000';
  context.fillRect(0, 0, canvas.width, canvas.height);

  var size = 8;
  var stage = game.stage;
  canvas.width = stage.width * size;
  canvas.height = stage.height * size;

  for (var y = 0; y < stage.height; y++) {
    for (var x = 0; x < stage.width; x++) {
      var fill = '#f00';
      var type = stage.get(x, y).type;
      if (type == Tiles.floor) {
        fill = '#000';
      } else if (type == Tiles.wall) {
        fill = '#aaa';
      } else if (type == Tiles.table) {
        fill = 'rgb(160, 110, 60)';
      } else if (type == Tiles.lowWall) {
        fill = '#666';
      } else if (type == Tiles.openDoor) {
        fill = 'rgb(160, 110, 60)';
      } else if (type == Tiles.closedDoor) {
        fill = 'rgb(160, 110, 60)';
      }

      context.fillStyle = fill;
      context.fillRect(x * size, y * size, size - 0.25, size - 0.25);
    }
  }
}