import 'dart:html' as html;

import 'package:hauberk/src/content/blob.dart';

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
  var blob = Blob.make64();
  const cell = 8;

  canvas.width = blob.width * cell;
  canvas.height = blob.height * cell;
  context.clearRect(0, 0, canvas.width, canvas.height);

  for (var y = 0; y < blob.height; y++) {
    for (var x = 0; x < blob.width; x++) {
      if (blob.get(x, y)) {
        context.fillStyle = 'rgb(10, 10, 10)';
      } else {
        context.fillStyle = 'rgb(240, 240, 240)';
      }

      context.fillRect(x * cell, y * cell, cell, cell);
    }
  }
}
