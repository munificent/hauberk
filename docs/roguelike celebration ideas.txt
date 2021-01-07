Some random ideas I had during the 2018 Roguelike Celebration:

"Death as an achievement". Keep track of how each hero dies and show the player
a list of all of them. This way even death gives you some sense of "progress".
How could be which monster killed the player, at what depth, items, etc.

Monsters that spawn other monsters when they die.

Let the player decorate the hero's home to give them away to put some creativity
in and generate some attachment to the hero.

Here's an idea for a dungeon generator:

- Fill the area entirely with rooms. Could do something like BSP or some other
  technique.

- Pick a random subset of those rooms to turn into corridor regions. To do that,
  run the corridor fill algorithm Brogue uses: try to fill a tile. If doing
  so produces an unreachable area, don't fill it. Keep doing that until there
  are no more tiles that can be filled.
