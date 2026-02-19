import '../tiles.dart';
import 'furnishing_builder.dart';

void catacombDecor() {
  category(themes: "catacomb", cells: {"!": applyOpen(Tiles.candle)});

  // TODO: Looks kind of hokey.
  furnishing(
    template: """
    ?.?
    .!.
    ?.?""",
  );
}
