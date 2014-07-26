library hauberk.web.dungeon_test;

import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/tiles.dart';

html.CanvasElement canvas;
html.CanvasRenderingContext2D context;

var content = createContent();
var area = 2;
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
      } else if (type == Tiles.grass) {
        fill = 'rgb(0, 20, 0)';
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
      } else if (type == Tiles.tree) {
        fill = 'rgb(0, 100, 0)';
      } else if (type == Tiles.treeAlt1) {
        fill = 'rgb(0, 120, 0)';
      } else if (type == Tiles.treeAlt2) {
        fill = 'rgb(0, 140, 0)';
      }

      context.fillStyle = fill;
      context.fillRect(x * size, y * size, size - 0.25, size - 0.25);

      var item = stage.itemAt(new Vec(x, y));
      if (item != null) {
        context.fillStyle = 'rgb(240, 240, 0)';
        context.fillRect(x * size + 2, y * size + 2, size - 4, size - 4);
      }

      var actor = stage.actorAt(new Vec(x, y));
      if (actor != null) {
        context.fillStyle = 'rgb(160, 0, 0)';
        context.fillRect(x * size + 1, y * size + 1, size - 2, size - 2);
      }
    }
  }
}