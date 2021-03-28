https://www.youtube.com/watch?v=PdCQ56UxVVE

Axes always hit all surrounding monsters.

When adding extra connections to avoid tree-like levels, it only adds an extra
connection if the open cells on either side are at least certain distance apart
in terms of pathfinding. This is a really smart way to avoid pointless redundant
doors.

Feels terrain is more interesting than monsters. Combining lots of different
kinds of terrain features gives you combinatorial options for interesting
spaces.

https://www.rockpapershotgun.com/2015/07/28/how-do-roguelikes-generate-levels/

Items are next, beyond what was already placed by machines. There's a cute trick
to decide where to place items. Imagine a raffle, in which each empty cell of
the map enters a certain number of tickets into the raffle. A cell starts with
one ticket. For every door that the player has to pass to reach the cell,
starting from the upstairs, the cell gets an extra ten tickets.

For every secret door that the player has to pass to reach the cell, the cell
gets an extra 3,000 tickets. If the cell is in a hallway or on unfriendly
terrain, it loses all of its tickets. Before placing an item, we do a raffle
draw — so caches of treasure are more likely in well hidden areas, off the
beaten path. When we place an item, we take away some of the tickets from the
nearby areas to avoid placing all of the items in a single clump.

Level generation is the heart and soul of a roguelike game. More than anything
else, the feel of the environment and its continued novelty defines the
experience. Designing it to produce exciting experiences is like building a
magical machine that can tell you stories forever. I started writing Brogue by
imagining the perfect roguelike dungeon environment that I always wanted to play
in, and I built the prototype level generator first to create that experience.
Once I had exciting environments that begged me to explore them, exploring them
became the enduring motivation for building the rest of the game.