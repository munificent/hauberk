class WildernessBuilder implements LevelBuilder {
  void generate(Level level) {
    new Wilderness(level, this).generate();
  }
}

class Wilderness {
  final Level level;
  final WildernessBuilder builder;

  Wilderness(this.level, this.builder);

  TileType getTile(Vec pos) => level[pos].type;

  void setTile(Vec pos, TileType type) {
    level[pos].type = type;
  }

  void generate() {
  }

}
