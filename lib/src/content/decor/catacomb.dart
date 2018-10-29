import '../tiles.dart';
import 'furnishing_builder.dart';

void catacombDecor() {
  category(themes: "catacomb dungeon", cells: {
    "!": applyOpen(Tiles.candle),
  });

  // TODO: Looks kind of hokey.
  furnishing(template: """
    ?.?
    .!.
    ?.?""");
}
