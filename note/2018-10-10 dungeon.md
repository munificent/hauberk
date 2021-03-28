1.  Place water, if any. Likewise other natural features.

2.  Choose a default room "architecture". An architecture is a ResourceSet that
    determines the probability of different room types, corridor tuning
    parameters, and style. Style determines how a logical structure is mapped
    to specific wall and floor tiles. It lets us have a single rectangular room
    that can be used for wooden walls, stone, etc.

    There is a ResourceSet of architectures so that we can have different ones
    that appear at different probabilities at different depths. It includes more
    clearly distinct themes like goblin lairs and caverns as well as a range of
    more generic rooms-and-corridors.

3.  Grow rooms. Includes regular rooms as well as any special rooms that have
    interesting sizes or shapes. When placing rooms at this stage, we mainly
    care about carving out the open area and the walls so that other rooms don't
    overlap.

    Corridors and doors can sometimes create cycles here. To prevent unnatural
    entrances to certain special areas, we can mark junctions as not allowing
    a cycle. If a corridor or door connects to that, it doesn't create a
    junction.

    We keep track of which type each room has in case it needs to do decorating
    later.

    Each step is:

    1.  Pick a random junction and use its architecture. Randomly consider
        changing it, with a relatively small probability. Otherwise, keep it.

        This leads to regions of rooms of the same architecture but also allows
        some variety. So once you get one goblin warren room, most rooms leading
        off that will be goblin warrens too.

        Use the architecture to decide whether or not to place a corridor. Then
        pick a random room type from the architecture and try to place it.

4.  Find all of the connectivity between the places. Now we know the graph of
    what's next to each other and which tiles are choke points.

5.  Paint and spread themes. Some places like water have built-in themes. Some
    rooms do too, like a crypt. Some of these bleed to adjacent rooms.

6.  Apply historic events. Cave-ins, earthquakes, explosions, erosion and other
    things that apply changes to the dungeon.

6.  For each place:

    1.  Paint it using the architecture. (Up to this point, it has been carved
        using generic wall and floor tiles, mainly to prevent overlapping other
        places.)

    1.  Apply any decor. Most normal places apply random decor based on the
        place's themes. Some specialized ones might not.

    2.  Populate with monsters and items. Again, some (pits, zoos) may have
        special rules, but others pick randomly taking themes into account.

todo: still vague about how boss monsters interact with themes. how does placing
a dragon affect nearby rooms?

todo: is each architecture a style, or can the same architecture be used with
multiple styles?

architecture:
- corridor params
- resourceset of room types (better name?)

room type:
- code to generate grid of tiles and junctions
- default theme(s) to use for decor, monsters, etc.
- optional special code to populate with monsters and items

room place:
- specific grid of generated tiles
