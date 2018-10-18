import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content/stage/blob.dart';

const cellSize = 8;

html.CanvasElement canvas;
html.CanvasRenderingContext2D context;

main() {
  canvas = html.querySelector("canvas") as html.CanvasElement;
  context = canvas.context2D;

  render();

  canvas.onClick.listen((_) {
    render();
  });
}

void render() {
  context.clearRect(0, 0, canvas.width, canvas.height);

  _drawBlob(Blob.make64(), 0);
  _drawBlob(Blob.make32(), 65);
  _drawBlob(Blob.make16(), 98);
}

void _drawBlob(Array2D<bool> blob, int left) {
  for (var y = 0; y < blob.height; y++) {
    for (var x = 0; x < blob.width; x++) {
      if (blob.get(x, y)) {
        context.fillStyle = 'rgb(10, 10, 10)';
      } else {
        context.fillStyle = 'rgb(240, 240, 240)';
      }

      context.fillRect((left + x) * cellSize, y * cellSize, cellSize, cellSize);
    }
  }
}