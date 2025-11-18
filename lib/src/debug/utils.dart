import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Returns a [Future] that completes after waiting an animation frame.
Future<void> waitFrame() {
  var completer = Completer<void>();
  // TODO: Is there overhead calling `toJS` every frame?
  web.window.requestAnimationFrame(
    (() {
      completer.complete();
    }).toJS,
  );

  return completer.future;
}
