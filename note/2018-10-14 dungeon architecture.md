At a very high level, I would like:

1.  To ensure the dungeon is connected.

2.  To allow flexibility to mix many different generation algorithms together:
    rooms and passages, caverns, cellular automata, rivers, lakes, castles, etc.

3.  To be able to apply different tile styles to any given algorithm: lakes of
    lava, wooden rooms, etc.

There is some tension here. Any over-arching system for ensuring connectivity
tends to presume or favor a certain algorithm for generating dungeons. I think a
lot of my thrashing is because I'm trying to make the one meta-dungeon generator
to rule them all, which means avoiding any constraints on the algorithms, which
prevents me from making any progress.

Ultimately, the goal is to ship one game with rich dungeons but not, like, an
infinite number of algorithms. I probably need to make some choices and be more
specific.

The junction system used by the rooms biome seems to work pretty well and can
fairly naturally extend to different kinds of "rooms", where a "room" might be
an entire region of the dungeon carved out using a different algorithm.

The current river/lake code looks nice but the fact that it relies on
*hopefully* getting connected to rooms has always been pretty dubious.

Also, the current code doesn't seem to scale well. As I try to add more
features, the complexity quickly gets overwhelming. It seems like there's a
missing abstraction preventing different pieces of the system from composing.

As far as styling and places go, there's an unsolved problem where it's not
clear which "side" owns doors and walls shared between two places. We can
probably solve that by just picking arbitrarily.

## Aquatics

Lakes aren't too hard to incorporate into the rooms-and-junctions system. We
could just generate lake "rooms" on demand and attach them. Rivers are harder
because they are so big and span the whole dungeon.

There is possibly room to improve how they look and work anyway. It could be
cool if a room could span a river with a bridge to get from one side to the
other. Or a room could open into a lake. Rivers and lakes could exist without
shores. You could imagine two rooms opening onto different sides of the same
lake -- you could see the other room, but have to find a different path to
actually reach it.

## Passages

Brian Walker's technique for carving random passages works amazingly well
(though it is kind of slow). I think there's a promising approach for connecting
natural areas (shores, caverns) to each other and to built (rooms) structures
using it. Something like:

1.  Fill the edge of the dungeon with rock and the center with some temporary
    open tile that means "maybe passage maybe filled". We'll say dirt.

2.  Place rivers and lakes as it already does. Either with or without shore
    tiles should work.

3.  Consider placing some caverns. A cellular automata with varying density
    seems to work well, that way some areas of the dungeon don't have any caves
    at all to leave room for rooms. These replace some of the fillable dirt
    tiles with guaranteed open tiles.

4.  Try to find a spot to place a starting room. If this fails, the dungeon is
    too full of natural areas. That's OK. Skip to 7.

5.  Place the room. That means setting its floor to floor but *not* filling in
    its walls. Place junctions as usual.

6.  Spreading out from those junctions try to place more rooms using the normal
    room and passage algorithm.

7.  At this point, the dungeon is fully connected because, aside from water,
    it's nothing but either dirt or floor tiles. Lakes aren't allowed too close
    to edges or rivers, so there is always room to get around them. Rivers have
    bridges.

8.  Find all of the permanent floor tiles -- cave floors, room floors, shores.
    Find all of the fillable dirt tiles. Now, use Brian Walker's technique to
    fill in as many fillable tiles as possible while still ensuring all the
    permanent floor tiles are connected.

    This will create passageways between the natural areas and rooms as needed.
    It will eventually fill in "walls" around all of the rooms too. (We don't
    do that eagerly because this lets natural areas create passageways into
    rooms wherever they need to.)

9.  Now we have a still-connected but filled in dungeon with lots of different
    regions. But it's generically tiled. Use the place/room data to go back and
    "style" things by swapping out rock and floor tiles for more interesting
    ones.
