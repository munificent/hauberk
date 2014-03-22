library content.forest;

import 'dart:math' as math;

import '../engine.dart';
import '../util.dart';
import 'stage_builder.dart';
import 'tiles.dart';

class Forest extends StageBuilder {
  /// A forest is a collection of grassy meadows surrounded by trees and
  /// connected by passages.
  int get numMeadows => 10;

  /// How for the meadows are positioned from the edge of the stage. Larger
  /// numbers mean a smaller dungeon centered in the stage.
  int get meadowInset => 7;

  /// The number of iterations of Lloyd's algorithm to run on the points.
  ///
  /// Fewer results in clumpier, less evenly spaced points. More results in
  /// more evenly spaced but can eventually look too regular.
  int get voronoiIterations => 4;

  void generate(Stage stage) {
    bindStage(stage);

    fill(Tiles.tree);

    // Randomly position the meadows.
    var meadows = [];
    for (var i = 0; i < numMeadows; i++) {
      var x = rng.range(meadowInset * 2, stage.width - meadowInset * 2);
      var y = rng.range(meadowInset, stage.height - meadowInset);
      meadows.add(new Vec(x, y));
    }

    // Space them out more evenly by moving each point to the centroid of its
    // cell in the Voronoi diagram of the points. In other words, for each
    // point, we find the (approximate) region of the stage where that point
    // is the closest one. Then we move the point to the center of that region.
    // http://en.wikipedia.org/wiki/Lloyd%27s_algorithm
    for (var i = 0; i < voronoiIterations; i++) {
      // For each cell in the stage, determine which point it's nearest to.
      // TODO: Using every tile on the stage may be overkill. Could iterate by
      // farther than 1 to get a looser approximation.
      var regions = new List.generate(numMeadows, (i) => [meadows[i]]);
      for (var y = meadowInset; y < stage.height - meadowInset; y++) {
        for (var x = meadowInset * 2; x < stage.width - meadowInset * 2; x++) {
          var cell = new Vec(x, y);

          var nearest;
          var nearestDistanceSquared = 99999999;
          for (var i = 0; i < numMeadows; i++) {
            var offset = meadows[i] - cell;
            if (offset.lengthSquared < nearestDistanceSquared) {
              nearestDistanceSquared = offset.lengthSquared;
              nearest = i;
            }
          }

          regions[nearest].add(cell);
        }
      }

      // Now move each point to the centroid of its region. The centroid is
      // just the average of all of the cells in the region.
      meadows = regions.map((region) {
        return region.reduce((a, b) => a + b) ~/ region.length;
      }).toList();
    }

    // Connect all of the points together.
    var connected = [meadows.removeLast()];
    while (meadows.isNotEmpty) {
      var bestFrom;
      var bestToIndex;
      var bestDistance;
      for (var from in connected) {
        for (var i = 0; i < meadows.length; i++) {
          var distance = (from - meadows[i]).lengthSquared;
          if (bestDistance == null ||
              distance < bestDistance) {
            bestFrom = from;
            bestToIndex = i;
            bestDistance = distance;
          }
        }
      }

      var to = meadows.removeAt(bestToIndex);
      connected.add(to);
      carvePath(bestFrom, to);
    }

    // Carve out the meadows.
    for (var point in connected) {
      carveCircle(point, 3);
    }

    erodeWalls(2000, floor: Tiles.grass, wall: Tiles.tree);

    // Randomly vary the tree type.
    var trees = [Tiles.tree, Tiles.treeAlt1, Tiles.treeAlt2];
    for (var pos in stage.bounds) {
      if (getTile(pos) == Tiles.tree) {
        setTile(pos, rng.item(trees));
      }
    }
  }

  void carvePath(Vec from, Vec to) {
    // TODO: A slightly random walk would be cool here.
    for (var pos in new Los(from, to)) {
      // TODO: Have option in Los to stop at endpoint.
      if (pos == to) break;

      // Make slightly wider passages.
      setTile(pos, Tiles.grass);
      setTile(pos.offsetX(1), Tiles.grass);
      setTile(pos.offsetY(1), Tiles.grass);
    }
  }

  void carveCircle(Vec center, int radius) {
    // TODO: Kind of biased and gross.
    for (var x = math.max(1, center.x - radius);
        x < math.min(center.x + radius, stage.width - 1);
        x++) {
      for (var y = math.max(1, center.y - radius);
          y < math.min(center.y + radius, stage.height - 1);
          y++) {
        var pos = new Vec(x, y);
        if ((pos - center) < radius) {
          setTile(pos, Tiles.grass);
        }
      }
    }
  }
}
