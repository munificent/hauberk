From top to bottom (in terms of rendering and roughly spatially):

Right now, it's:

- Actor - the actor occupying this tile, if any. Actors are "live" and get
  processing time according to their energy.

- Items - the list of items currently sitting on this tile, if any. Items are
  passive. The game loop doesn't do anything per-round with items sitting on
  the ground.

- Tile type - the fundamental kind of tile this is: floor, wall, lake, etc.
  Totally passive. Has a set of motilities that determine which actors are able
  to enter the tile, and also how the tile affects visibility.

For things like slime stains, we replace the tile type with a totally different
type. It no longer "knows" that it used to be floor versus grass or whatever.

I'd like the work to feel richer, more interactive and more responsive. As you
play the game, the dungeon should progressively visually show the history of
your presence and of the monsters on it (and it should also hint at the
dungeon's history before you arrived). Stuff like:

- Slimes leave stains as they move.
- Fire continues to burn for a while and can spread or burn out.
- Decor tiles like chairs and tables can be burned or pushed.
- Water can be frozen. Maybe evaporated?
- Glyphs of warding, traps, and spikes can be placed.
- Different styles of stone, walls, floors, etc.
- Spiderwebs.

Some of this can be expressed using the existing actor, item, and tile objects,
but not all. If, for example, you push a chair over stone and grass, how does
it know what to set the type back to? So movable decor shouldn't be a tile type.
Fire is pretty useless if monsters can't run into it, so it shouldn't be an
actor since two actors can't occupy the same tile.

Consider more interesting cases: You push a chair on top of a slime stain, set
it on fire, and then move the (flaming) chair. Ideally, the slime stain would
remain behind and the fire would move with the chair. Unless, I suppose,
something on the ground itself is on fire (maybe it's a bridge?), in which case
probably both the chair and the tile should be burning.

Maximum generality could make this pretty complex for little practical benefit,
so we'll probably want to apply a few constraints. Here's a pitch:

- Actor - the actor occupying this tile, if any. Actors are "live" and get
  processing time according to their energy.

  Movable objects like chairs are actors. They can be hit, destroyed, and have
  their location changed, so that seems reasonable.

  One of the conditions an actor can be in is "on fire". Most actors aren't
  actively flammable, they just get hurt by fire. Things like chairs and some
  monsters like, I dunno, mummies, can actually be set on fire. When on fire,
  the game renders them differently, like fire tiles.

- State (needs a better name) - if some active thing is going on on the tile
  itself, it is stored here. This may get processing time every game tick.
  Stuff like the tile is on fire. Anything else?

- Items - the list of items currently sitting on this tile, if any. Items are
  passive. The game loop doesn't do anything per-round with items sitting on
  the ground.

- Decoration - a stain, theme, or other mostly-aesthetic modifier to the tile.
  Most don't affect gameplay. Some, like spiderwebs do. A tile can only have one
  decoration. Applying one replaces any previous one or fails to be applied.
  (Maybe there is some sort of prioritzation or something). A tile may have no
  decoration.

- Tile type - the fundamental kind of tile this is: floor, wall, lake, etc.
  Totally passive. Has a set of motilities that determine which actors are able
  to enter the tile, and also how the tile affects visibility.

Questions:

1. Are there other interesting active states than "on fire"?
2. Should we use decorations to model doors? Can doors be burned?
3. Should spiderwebs be decorations or state?
4. How does this interact with AI? We don't want pathfinding and stuff (which
   live in the engine) to be aware of all the decoration types (which are in
   content).
5. How does water work in this? Can lakes be evaporated? Are there puddles that
   can be evaporated and other water that can't?
6. Do we want more interesting properties for fire, water, etc? Flow? Physics?
   Do we need to consider some kind of depth field? How does water know where
   to pool and flow?
