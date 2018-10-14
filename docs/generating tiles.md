I'd like to support more "styles" of dungeon features. For example, lakes that
are not just water but ice, lava, slime, etc. Room walls that are not just the
one wall tile but different kinds of stone, wood, etc. Floors of different
color and materials.

A key challenge is that the dungeon generator currently both writes to and reads
from the stage when generating. It expects certain specific tile types to mean
different things. If we use other tile types, it gets confused and breaks.

A couple of options:

- Have the generator not work with tiles at all. Instead, it uses a more
  abstract representation of "cells" with a few special states. Once that's all
  done, a separate "painting" process takes that cell grid and applies it to the
  stage.

  I've tried this and it never seems to pan out. There's a lot of functionality
  we use from Stage and reinventing all of that for a separate cell grid is a
  pain.

- Have the generator use a subset of the tile types. So it generates a "generic"
  dungeon only using Tiles.floor, Tiles.rock, etc. Then a separate painting
  process goes back and fills those in with more precise tile types.

  This could work, but I'm worried that it will be hard to persist whatever
  information we need for the later painting process to do its job. If we use
  Place and its list of tiles, is it clear which place owns the walls bordering
  two places?

  When do we add decor? Before or after painting? Is decor itself painted or
  paintable?

- Let the generator paint whatever tiles it wants. When reading from the stage,
  have helper methods that map the specific tile types to what they logically
  represent. So instead of isRock(), something like isUncarved(), etc.

  This makes it really flexible when writing. We can paint interesting tiles
  during generation, or later, or both.

  The main challenge is whether the tile types are precise enough to always be
  able to map them to a logical intent. If we want to support, say, rooms that
  use rock walls, then we can't tell if a rock tile means "uncarved" or "wall".

  We could possibly dodge that by having multiple tile types that look the same
  to the player but mean something different to the generator. But that feels
  like a hack.

  Overall, I think this is the best approach. There's an argument that we
  should be able to reliably tell what a given tile "means" in the abstract
  because that also implies that a player knows what they are looking at when
  they see the dungeon.

- Keep track of two layers, the main stage of tiles and a separate semantic
  layer of cells. The generator can write whatever tiles it wants whenever it
  wants. Whenever it writes tiles, it is also responsible for writing to the
  cells too to indicate what the tile represents.

  It cannot read from the stage at all. Any reading only comes from the cells.
  (We can put some debug code in Stage to validate this.)

  Compared to the previous approach, this makes it clearer what semantic
  information means instead of having to know what, say "grass" means "walkable
  non-room biome tile that hasn't been reached yet".

  It also lets us do things like mark tiles as prohibiting junctions or
  otherwise treating them specially for generation even though it's a normal
  tile in the dungeon.

  This feels a little like the first option, with extra complexity since tiles
  are being painted simultaneously. Given that we already have a grid for
  tracking places and junctions, maybe we should just go with the first option.
  So the dungeon generation has explicit phases where the first pass produces
  a cell grid and then that gets lowered to tiles. More like a compiler with
  distinct immutable representations instead of mucking with one big mutable
  ball of stuff.

Here's how the generator currently reads tiles from the stage:

## rock:

isRockAt()
  - lake uses to not overlap existing river/lake
    - could check for place tiles?
  - lake uses to not remove water when adding shore
  - passage uses to only turn rock edges into wall when placing
isRock()
  - river uses to not remove water when adding shore
AquaticBiome._makePlace()
  - used to find shore edge tiles to add grottoes from
    - could use isTraversable or check place tiles
AquaticBiome._erode()
  - used to only erode into solid tiles
    - could use isTraversable
RoomsBiome._tryJunction()
  - used to only use junction that points into uncarved area
RoomsBiome._tryAddJunction()
  - used to not add junction that points into door, i think?

## grass:

AquaticBiome._makePlace()
  - used to find shore edge tiles to add grottoes
- tile used for grottoes and shores
_placeBridges()
  - find shore for placing bridges
RoomsBiome._tryAddJunction()
  - used to only use junction that points into uncarved area
RoomsBiome._reachOtherBiome()
  - used to find region of other biome

## wall:

- type of room edges
- type of passage edges
- used to find edges to erode grottoes
  - i don't think this is actually used since we don't carve grottoes after
    placing rooms now
AquaticBiome._erode()
  - used to tell what tiles to erode into
BlobRoom.create()
  - used to find edge of blob room
  - used to tell where to put junctions
RoomsBiome._tryAddJunction()
  - used to only use junction that points into uncarved area

## floor:

+ tile type used for room floors
Dungeon._stain()
  + used to place stain on floors
BlobRoom.create()
  + find the edge of the blob
RoomsBiome._placePassage()
  - tile type used for passage floors
