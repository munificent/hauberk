import 'dart:js_interop';

import 'package:hauberk/src/content/stage/blob.dart';
import 'package:web/web.dart' as web;

const cellSize = 8;

final sizeSelect = web.document.querySelector("#size") as web.HTMLSelectElement;
final canvas = web.document.querySelector("canvas") as web.HTMLCanvasElement;
final context = canvas.context2D;

void main() {
  for (var i = 4; i <= 128; i++) {
    sizeSelect.append(
      web.HTMLOptionElement()
        ..text = i.toString()
        ..value = i.toString()
        ..selected = i == 16,
    );
  }

  sizeSelect.onChange.listen((event) {
    render();
  });

  canvas.onClick.listen((_) {
    render();
  });

  render();
}

void render() {
  var blob = Blob.make(int.parse(sizeSelect.value));
  canvas.width = blob.width * cellSize;
  canvas.height = blob.height * cellSize;
  context.clearRect(0, 0, canvas.width, canvas.height);

  for (var y = 0; y < blob.height; y++) {
    for (var x = 0; x < blob.width; x++) {
      if (blob.get(x, y)) {
        context.fillStyle = 'rgb(10, 10, 10)'.toJS;
      } else {
        context.fillStyle = 'rgb(240, 240, 240)'.toJS;
      }

      context.fillRect(x * cellSize, y * cellSize, cellSize, cellSize);
    }
  }
}
