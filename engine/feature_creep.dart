
/// The dungeon generator used for normal dungeon levels. It works by
/// iteratively growing the dungeon from a single starting room. The basic
/// algorithm is:
///
/// 1.  Place a starting room, and add a number of connection points to it.
///
/// 2.  Select a random open connection point in the dungeon.
///
/// 3.  Try to generate a random feature (room, hallway, etc.) that can connect
///     to that point. If it fits, place it. Add any connection points on that
///     feature to the list of open connection points.
///
/// 4.  Go to 2 until enough of the dungeon is open.
///
/// Normally, this would generate tree-like dungeons that only branch off the
/// starting room. However, the hallway features are smart enough to allow
/// themselves to be placed even if they extend into an existing room. This
/// allows it to add redundant connections, yielding a more natural dungeon.
class FeatureCreep {
  int tries = 0;
  int openCount = 0;
  FeatureCreepOptions options;
  Level level;
  final List<Connector> connectors;
  Vec startPos;

  FeatureCreep()
  : connectors = <Connector>[];

  void create(Level level, /*bool isDescending, int depth, */ options) {
    this.options = options;
    this.level = level;

    // Sometimes the generator makes dud dungeons with just one or two rooms,
    // keep trying from scratch until we get one with at least a certain amount
    // of carved open area.
    do {
      tries++;

      /*
      mDungeon.Entities.Clear();
      mDungeon.Items.Clear();
      */

      tryCreate();
    } while ((100 * openCount / level.tiles.size.area < options.minimumOpenPercent)
       /* || !madeDownStair || !madeUpStair*/);
  }

  void tryCreate() {
    // Clear the grid.
    openCount = 0;
    /*
    mMadeUpStair = false;
    mMadeDownStair = false;
    */

    level.tiles.fill((pos) => new Tile());

    // Create a starting room.
    connectors.clear();
    startPos = null;
    startPos = makeStartingRoom().center;

    for (var tries = 0; (tries < options.maxTries) && (connectors.length > 0); tries++) {
      // Pull off the first unused connector.
      final connector = connectors[0];

      var success = false;

      switch (connector.from) {
        case ConnectFrom.ROOM:
          // Try to add a hall.
          success = makeHall(connector);
          break;

        case ConnectFrom.HALL:
          final choice = rng.range(100);
          if (choice < options.chanceOfRoom) {
            success = makeRoom(connector);
          } else {
            // Default to a junction.
            success = makeJunction(connector);
          }
          /*
          var feature = mDungeon.Game.Content.Features.CreateOne(depth);
          success = mFactory.CreateFeature(feature, connector);
          // one of
          //   stair (2%)
          //   room (70%)
          //   maze (3%)
          //   pit (2%)
          //   junction (23%)
          */
          break;
      }

      // The connector has been tried.
      connectors.removeRange(0, 1);

      // If we failed to connect something, move the connector to the end of
      // the list. Since it pulls connectors from the beginning, this should
      // encourage the dungeon to spread out first instead of just hammering
      // the same crowded connectors over and over again.
      if (!success) connectors.add(connector);
    }

    print('Unused connectors: ${connectors.length}, open space: $openCount / ${level.tiles.size.area}');
  }

  /// Gets whether the [rect] is empty (i.e. solid walls) and can have
  /// a feature placed in it. If [exception] is given then the tile at that
  /// position can be non-wall and still allow the room to be places. Used for
  /// the connector to a new feature.
  ///
  /// It works by simply seeing if the rect contains the level starting
  /// position, or if the outer edge of the rect touches a non-wall square. As
  /// long as the level is always connected to the starting position, this
  /// should be enough to tell if any square inside the rect is in use.
  bool isOpen(Rect rect, Vec exception) {
    // Must be totally in bounds
    if (!level.bounds.containsRect(rect)) return false;

    // And not cover the starting tile.
    if (startPos != null && rect.contains(startPos)) return false;

    // Or something connected to it
    for (Vec edge in rect.trace()) {
      // Allow the exception.
      if (exception == edge) continue;

      if (level[edge].type != TileType.WALL) return false;
    }

    return true;
  }

  TileType getTile(Vec pos) {
    return level[pos].type;
  }

  void setTile(Vec pos, TileType type) {
    level[pos].type = type;

    // Keep track of how much dungeon we've carved.
    if (level[pos].isPassable) openCount++;

    /*
    //### bob: hackish. assumes will never get overwritten after
    if (type == TileType.StairsUp) mMadeUpStair = true;
    if (type == TileType.StairsDown) mMadeDownStair = true;
    */
  }

  /*
  void LightRect(Rect bounds, int depth)
  {
    // light the room
    if ((depth <= Rng.Int(1, 80)))
    {
      foreach (Vec pos in bounds.Inflate(1))
      {
        mDungeon.SetTilePermanentLit(pos, true);
      }
    }
  }
  */

  void addRoomConnector(Vec pos, Direction dir) {
    connectors.insertRange(rng.inclusive(connectors.length), 1,
        new Connector(ConnectFrom.ROOM, dir, pos));
  }

  void addHallConnector(Vec pos, Direction dir) {
    connectors.insertRange(rng.inclusive(connectors.length), 1,
        new Connector(ConnectFrom.HALL, dir, pos));
  }

  /*
  void Populate(Vec pos, int monsterDensity, int itemDensity, int depth)
  {
    // test every open tile
    if (mDungeon.Tiles[pos].IsPassable)
    {
      // place a monster
      if ((mDungeon.Entities.GetAt(pos) == null) && (Rng.Int(1000) < monsterDensity + (depth / 4)))
      {
        Monster.AddRandom(mDungeon, depth, pos);
      }

      // place an item
      if (Rng.Int(1000) < itemDensity + (depth / 4))
      {
        Race race = Race.Random(mDungeon, depth, false);
        race.PlaceDrop(mDungeon, pos);
      }
    }
  }

  void AddEntity(Entity entity)
  {
    mDungeon.Entities.Add(entity);
  }

  bool mMadeUpStair;
  bool mMadeDownStair;
  */

  Rect makeStartingRoom() => createRoom(null);

  /*
  public bool CreateFeature(string name, Connector connector)
  {
    switch (name)
    {
      case "stair": return MakeStair(connector);
      case "room": return MakeRoom(connector);
      case "maze": return MakeMaze(connector);
      case "pit": return MakePit(connector);
      case "junction": return MakeJunction(connector);
      default: throw new ArgumentException("Unknown feature \"" + name + "\"/");
    }
  }
  */

  bool makeHall(Connector connector) {
    final length = rng.range(options.hallLengthMin, options.hallLengthMax);

    // See if the hall doesn't cut into an existing feature.
    var bounds;
    switch (connector.direction) {
      case Direction.N:
        bounds = new Rect(connector.pos.x - 1, connector.pos.y - length, 3, length + 1);
        break;
      case Direction.S:
        bounds = new Rect(connector.pos.x - 1, connector.pos.y, 3, length + 1);
        break;
      case Direction.E:
        bounds = new Rect(connector.pos.x, connector.pos.y - 1, length + 1, 3);
        break;
      case Direction.W:
        bounds = new Rect(connector.pos.x - length, connector.pos.y - 1, length + 1, 3);
        break;
    }

    if (!isOpen(bounds, null)) return false;

    // Make sure the end corners aren't open unless the position in front of
    // the end is too. Prevents cases like:
    // ####..
    // ####..
    // ....## <- new hall ends at corner of room
    // ######
    final pos = connector.pos + (connector.direction * (length + 1));
    final leftCorner = pos + connector.direction.rotateLeft90;
    final rightCorner = pos + connector.direction.rotateRight90;

    if (!level.bounds.contains(pos)) return false;
    if (!level.bounds.contains(leftCorner)) return false;
    if (!level.bounds.contains(rightCorner)) return false;

    if ((getTile(leftCorner) != TileType.WALL) &&
        (getTile(pos) == TileType.WALL)) return false;

    if ((getTile(rightCorner) != TileType.WALL) &&
        (getTile(pos) == TileType.WALL)) return false;

    // Place the hall.
    var step = connector.pos;
    for (var i = 0; i <= length; i++) {
      setTile(step, TileType.FLOOR);
      step += connector.direction;
    }

    /*
    PlaceDoor(connector.pos);
    PlaceDoor(connector.pos + (connector.Direction.Offset * length));
    */

    // Add a connector to the end.
    addHallConnector(connector.pos + (connector.direction * length),
        connector.direction);

    /*
    Populate(bounds, 10, 10, mDepth);
    */

    return true;
  }

  bool makeJunction(Connector connector) {
    final center = connector.pos + connector.direction;

    bool left = false;
    bool right = false;
    bool straight = false;

    int choice = rng.range(100);
    if ((choice -= options.chanceOfTurn) < 0) {
      if (rng.oneIn(2)) left = true; else right = true;
    } else if ((choice -= options.chanceOfFork) < 0) {
      if (rng.oneIn(2)) left = true; else right = true;
      straight = true;
    } else if ((choice -= options.chanceOfTee) < 0) {
      left = true;
      right = true;
    } else if ((choice -= options.chanceOfFourWay) < 0) {
      left = true;
      right = true;
      straight = true;
    } else {
      straight = true;
    }

    // Check to see if we can place it.
    Rect rect = new Rect(center.x - 1, center.y - 1, 3, 3);
    if (!isOpen(rect, center + connector.direction.rotate180)) return false;

    // Place the junction.
    setTile(center, TileType.FLOOR);

    // Add the connectors.
    if (left) addRoomConnector(center + connector.direction.rotateLeft90, connector.direction.rotateLeft90);
    if (right) addRoomConnector(center + connector.direction.rotateRight90, connector.direction.rotateRight90);
    if (straight) addRoomConnector(center + connector.direction, connector.direction);

    return true;
  }

  bool makeRoom(Connector connector) {
    return createRoom(connector) != null;
  }

  /*
  private bool MakeStair(Connector connector)
  {
    // check to see if we can place it
    Rect rect = new Rect(connector.pos.Offset(-1, -1), 3, 3);
    if (!IsOpen(rect, connector.pos + connector.Direction.Rotate180)) return false;

    TileType type = (Rng.Int(10) < 6) ? TileType.StairsDown : TileType.StairsUp;
    SetTile(connector.pos, type);

    return true;
  }

  private bool MakeMaze(Connector connector)
  {
    // in maze units (i.e. thin walls), not tiles
    int width = Rng.Int(Options.MazeSizeMin, Options.MazeSizeMax);
    int height = Rng.Int(Options.MazeSizeMin, Options.MazeSizeMax);

    int tileWidth = width * 2 + 3;
    int tileHeight = height * 2 + 3;
    Rect bounds = CreateRectRoom(connector, tileWidth, tileHeight);

    // bail if we failed
    if (bounds == Rect.Empty) return false;

    // the hallway around the maze
    foreach (Vec pos in bounds.Trace())
    {
      SetTile(pos, TileType.Floor);
    }

    // sometimes make the walls low
    if (Rng.OneIn(2))
    {
      foreach (Vec pos in bounds.Inflate(-1))
      {
        SetTile(pos, TileType.LowWall);
      }
    }

    // add an opening in one corner
    Vec doorway;
    switch (Rng.Int(8))
    {
      case 0: doorway = bounds.TopLeft.Offset(2, 1); break;
      case 1: doorway = bounds.TopLeft.Offset(1, 2); break;
      case 2: doorway = bounds.TopRight.Offset(-3, 1); break;
      case 3: doorway = bounds.TopRight.Offset(-2, 2); break;
      case 4: doorway = bounds.BottomRight.Offset(-3, -2); break;
      case 5: doorway = bounds.BottomRight.Offset(-2, -3); break;
      case 6: doorway = bounds.BottomLeft.Offset(2, -2); break;
      case 7: doorway = bounds.BottomLeft.Offset(1, -3); break;
      default: throw new Exception();
    }
    PlaceDoor(doorway);

    // carve the maze
    Maze maze = new Maze(width, height);
    maze.GrowTree();

    Vec offset = bounds.pos.Offset(1, 1);
    maze.Draw(pos => SetTile(pos + offset, TileType.Floor));

    LightRect(bounds, mDepth);

    // populate it
    int boostedDepth = mDepth + Rng.Int(mDepth / 5) + 2;
    Populate(bounds.Inflate(-2), 200, 300, boostedDepth);

    // place the connectors
    AddRoomConnectors(connector, bounds);

    return true;
  }

  private bool MakePit(Connector connector)
  {
    // pits use room size right now
    int width = Rng.Int(Options.RoomSizeMin, Options.RoomSizeMax);
    int height = Rng.Int(Options.RoomSizeMin, Options.RoomSizeMax);
    Rect bounds = CreateRectRoom(connector, width, height);

    // bail if we failed
    if (bounds == Rect.Empty) return false;

    // light it
    LightRect(bounds, mDepth);

    // choose a group
    IList<Race> races = Content.Races.AllInGroup(Rng.Item(Content.Races.Groups));

    // make sure we've got some races that aren't too out of depth
    races = new List<Race>(races.Where(race => race.Depth <= mDepth + 10));
    if (races.Count == 0) return false;

    // place the room
    foreach (Vec pos in bounds)
    {
      SetTile(pos, TileType.Floor);
    }

    RoomDecoration.DecorateInnerRoom(bounds, new RoomDecorator(this,
      pos => AddEntity(new Monster(pos, Rng.Item(races)))));

    return true;
  }
  */

  Rect createRoom(Connector connector) {
    final width = rng.range(options.roomSizeMin, options.roomSizeMax);
    final height = rng.range(options.roomSizeMin, options.roomSizeMax);

    final bounds = createRectRoom(connector, width, height);

    // Bail if we failed.
    if (bounds == null) return bounds;

    // Place the room.
    for (final pos in bounds) {
      setTile(pos, TileType.FLOOR);
    }

    /*
    TileType decoration = ChooseInnerWall();

    RoomDecoration.Decorate(bounds, new FeatureFactory.RoomDecorator(this,
      pos => Populate(pos, 60, 200, mDepth + Rng.Int(mDepth / 10))));

    LightRect(bounds, mDepth);
    */

    // Place the connectors.
    addRoomConnectors(connector, bounds);

    /*
    Populate(bounds, 20, 20, mDepth);
    */

    return bounds;
  }

  Rect createRectRoom(Connector connector, int width, int height) {
    var x = 0;
    var y = 0;

    // Position the room.
    if (connector == null) {
      // Initial room, so start near center.
      x = rng.triangleInt((level.width - width) ~/ 2,
                          (level.width - width) ~/ 2 - 4);
      y = rng.triangleInt((level.height - height) ~/ 2,
                          (level.height - height) ~/ 2 - 4);
    } else if (connector.direction == Direction.N) {
      // Above the connector.
      x = rng.range(connector.pos.x - width + 1, connector.pos.x + 1);
      y = connector.pos.y - height;
    }
    else if (connector.direction == Direction.E)
    {
      // To the right of the connector.
      x = connector.pos.x + 1;
      y = rng.range(connector.pos.y - height + 1, connector.pos.y + 1);
    }
    else if (connector.direction == Direction.S)
    {
      // Below the connector.
      x = rng.range(connector.pos.x - width + 1, connector.pos.x + 1);
      y = connector.pos.y + 1;
    }
    else if (connector.direction == Direction.W)
    {
      // To the left of the connector.
      x = connector.pos.x - width;
      y = rng.range(connector.pos.y - height + 1, connector.pos.y + 1);
    }

    final bounds = new Rect(x, y, width, height);

    // Check to see if the room can be positioned.
    if (!isOpen(bounds.inflate(1),
      (connector != null) ? connector.pos : null)) {
      return null;
    }

    return bounds;
  }

  void addRoomConnectors(Connector connector, Rect bounds) {
    addRoomEdgeConnectors(connector, new Rect(bounds.left, bounds.top - 1, bounds.width, 1), Direction.N);
    addRoomEdgeConnectors(connector, new Rect(bounds.right, bounds.top, 1, bounds.height), Direction.E);
    addRoomEdgeConnectors(connector, new Rect(bounds.left, bounds.bottom, bounds.width, 1), Direction.S);
    addRoomEdgeConnectors(connector, new Rect(bounds.left - 1, bounds.top, 1, bounds.height), Direction.W);
  }

  void addRoomEdgeConnectors(Connector connector, Rect edge, Direction dir) {
    bool skip = rng.oneIn(2);

    for (final pos in edge) {
      // Don't place connectors close to the incoming connector.
      if (connector != null && ((connector.pos - pos).kingLength <= 1)) {
        continue;
      }

      if (!skip && (rng.range(100) < options.chanceOfRoomConnector)) {
        addRoomConnector(pos, dir);
        skip = true;
      } else {
        skip = false;
      }
    }
  }

  /*
  private void PlaceDoor(Vec pos)
  {
    int choice = Rng.Int(100);
    if (choice < Options.ChanceOfOpenDoor)
    {
      SetTile(pos, TileType.DoorOpen);
    }
    else if (choice - Options.ChanceOfOpenDoor < Options.ChanceOfClosedDoor)
    {
      SetTile(pos, TileType.DoorClosed);
    }
    else
    {
      SetTile(pos, TileType.Floor);
    }
    //### bob: add locked and secret doors
  }

  private void Populate(Rect bounds, int monsterDensity, int itemDensity, int depth)
  {
    // test every open tile
    foreach (Vec pos in bounds)
    {
      Populate(pos, monsterDensity, itemDensity, depth);
    }
  }

  private TileType ChooseInnerWall()
  {
    return Rng.Item(new TileType[] { TileType.Wall, TileType.LowWall });
  }

  public class RoomDecorator : IRoomDecorator
  {
    public RoomDecorator(FeatureFactory factory, Action<Vec> insideRoom)
    {
      mInsideRoom = insideRoom;
      mFactory = factory;
      mDecoration = mFactory.ChooseInnerWall();
    }

    public void AddDecoration(Vec pos)
    {
      mFactory.SetTile(pos, mDecoration);
    }

    public void AddInsideRoom(Vec pos)
    {
      mInsideRoom(pos);
    }

    public void AddDoor(Vec pos)
    {
      mFactory.PlaceDoor(pos);
    }

    private FeatureFactory mFactory;
    private Action<Vec> mInsideRoom;
    private TileType mDecoration;
  }

  private readonly int mDepth;
  */
}

class ConnectFrom {
  static final ROOM = const ConnectFrom(0);
  static final HALL = const ConnectFrom(1);

  final int _value;

  const ConnectFrom(this._value);
}

class Connector {
  ConnectFrom from;
  Direction direction;
  Vec pos;

  Connector(this.from, this.direction, this.pos);
}

/// Parameters that tune how the [FeatureCreepGenerator] generates dungeons.
/// Changing these values will affect the overall look of the dungeon,
/// sometimes drastically.
class FeatureCreepOptions {
  int maxTries = 5000;
  int minimumOpenPercent = 30;

  // Room.
  int roomSizeMin = 3;
  int roomSizeMax = 7;
  int chanceOfRoomConnector = 30; // 13;

  /*
  int mazeSizeMin = 4;
  int mazeSizeMax = 12;
  */

  // Feature.
  int chanceOfRoom = 80;

  // Hall.
  int hallLengthMin = 1;
  int hallLengthMax = 1;

  // Junction.
  int chanceOfTurn = 30;
  int chanceOfFork = 50;
  int chanceOfTee = 20;
  int chanceOfFourWay = 0;

  // Door.
  int chanceOfOpenDoor = 20;
  int chanceOfClosedDoor = 10;
}
