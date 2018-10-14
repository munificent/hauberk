// TODO: Define different ones of this to have different styles.
import '../../engine.dart';
import 'room_type.dart';

class Architecture {
  static final ResourceSet<Architecture> _all = ResourceSet();

  static Architecture choose(int depth) {
    if (_all.isEmpty) _initialize();

    return _all.tryChoose(depth, "architecture");
  }

  static void _initialize() {
    _all.defineTags("architecture");

    // TODO: Make a nicer API.
    // Default.
    var architecture = Architecture._();
    architecture.roomTypes
        .addUnnamed(RectangleRoom("room", 10), 1, 1.0, "room");
    _all.addUnnamed(architecture, 1, 1.0, "architecture");

    // Goblin warren.
    architecture = Architecture._(passageTries: 0);
    architecture.roomTypes.addUnnamed(RectangleRoom("room", 6), 1, 1.0, "room");
    _all.addUnnamed(architecture, 1, 1.0, "architecture");

    // Caverns.
    architecture = Architecture._(
        passageTurnPercent: 60,
        passageBranchPercent: 50,
        passageMinLength: 3,
        passageMaxLength: 10,
        passageTries: 10);
    architecture.roomTypes.addUnnamed(BlobRoom("room"), 1, 1.0, "room");
    _all.addUnnamed(architecture, 1, 1.0, "architecture");
  }

  final int passageTurnPercent;
  final int passageBranchPercent;
  final int passageMinLength;
  final int passageMaxLength;
  final int passageTries;

  /// A passage that connects to an existing place, by definition, adds a cycle
  /// to the dungeon. We don't want to do that if there is always a similar
  /// path between those two points. A cycle should only be added if it connects
  /// two very disparate regions (in terms of reachability).
  ///
  /// To get that, we only place a cyclic passage if the shortest existing
  /// route between the two points is longer than the new passage's length times
  /// this scale. Making this smaller adds more cycles.
  final int passageShortcutScale = 10;

  final int junctionMaxTries = 3;

  final ResourceSet<RoomType> roomTypes = ResourceSet();

  Architecture._(
      {int passageTurnPercent,
      int passageBranchPercent,
      int passageMinLength,
      int passageMaxLength,
      int passageTries})
      : passageTurnPercent = passageTurnPercent ?? 30,
        passageBranchPercent = passageBranchPercent ?? 40,
        passageMinLength = passageMinLength ?? 5,
        passageMaxLength = passageMaxLength ?? 80,
        passageTries = passageTries ?? 20 {
    roomTypes.defineTags("room");
  }
}
