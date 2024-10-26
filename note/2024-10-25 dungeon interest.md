I think one of the things really holding back the game in terms of fun is that
levels aren't that interesting to explore. There's a decent amount of variety
in there: dungeons, keeps, caverns, rivers, etc.

But in practice, most levels feel pretty same-y. Part of that is that the most
common level is simply a Dungeon that covers the whole level. But that is the
bread and butter generator and should be interesting on its own.

## Scale

One reason I think it gets boring is that every fraction of the dungeon is
similar to others. Most rooms are around the same size and layout, so as you
work through the dungeon, each room feels pretty much the same as the others.
No two dungeons are the same, but that's true in the way that no two bowls of
cereal have the same arrangement Cheerios. They are random, but essentially
uniform.

Part of that might be that rooms are mostly the same size. In both nature and
architecture, a variety of scales is an important design element. A space is
interesting when different regions of the space have different scales, usually
a small number of large things and a larger number of smaller ones.

So maybe the Dungeon generator needs to generate a wider range of room sizes,
and not have all sizes equally probable. That's an easy thing to try.

## Non-uniform distribution

Related to that is how we place monsters and floor drops. Right now, it has a
fairly complex mechanism where every time something is placed, it reduces the
chances of placing more stuff nearby. That has the effect of making stuff
pretty uniformly distributed. Kind of like blue noise.

That was the goal when I implemented that... but I think maybe it's not the
right goal. It makes rooms more uniform and thus less interesting.

It would probably be better to distribute more randomly so that some rooms are
empty and sometimes you stumble into one packed with trouble. That way, you
have to really decide which areas are worth going into.

## Informed exploration

This is something I've written about before. The dungeon doesn't generally give
you hints about what you haven't explored in ways that make explortion choices
somewhat informed and meaningful. You're basically just opening doors randomly
and seeing what you get. Then you do that over and over again.

Exploring the dungeon more or less feels like exploring a hundred tiny
independent dungeons.

It would be great if paying attention would reward you by giving you hints
like "I should definitely avoid this, but going over here is more likely to
give me that magic item I'm looking for."

In other words, the parts of the dungeon you have already explored should teach
you about the parts yet to come.

Some existing ideas I've had around that:

*   Spawning minions spread out around the main boss so that when you start
    seeing weaker monsters of a certain kind, you get a clue that you are
    heading towards a boss.

*   Likewise, we could place stains on the ground or other hoard items that
    indicate what might be there.

*   Associating monsters with decor and tile styles so that the way a room
    looks hints at what you might find.

*   Symmetry in room placement so that when you explore one side, you know
    what the layout of the other side will be.

*   Spacing out rooms predictably enough so that if you see a big empty
    unexplored patch, you know there is likely to be some kind of room or space
    in there. Angband tends to do this well.

*   Level feelings and room descriptions as you explore. "You smell the stench
    of decay."

## Machines and narrative

In games with hand-authored content, a lot of time is spent in the narrative
flow of a level. You have to kill a mini-boss to get a key to open a door to a
treasure to get an item that you need to reach the final boss. That kind of
stuff.

I don't want levels to be *too* mechanical because otherwise I worry it will
feel like the same couple of tasks over and over again.

But a little more structure like that would be good. Better treasure should be
behind stronger monsters. The level should feel like you're *going somewhere*.

I can probably take some ideas from Brogue's machines.

## Other stuff

Some other stuff about the current generator that doesn't do it for me:

### Lighting

I really like how evocative the lighting engine can be. It really adds a lot of
textural variety to levels. And it works with the game mechanics too, which is
cool. It's not just flavor.

But I hate the brazier tiles. They were thrown in and they are just annoying and
dumb looking. Candles on tables are better, but don't provide much light. It
would look better if the braziers were embedded in walls, but then they would
leak through the other side when two rooms are adjacent.

I like the idea of diagetic lighting, but maybe I'm trying to hard for realism.

Also, when you encounter a lake or river, it loses much of the impact because
you can't actually *see* much of it. Maybe they should give off a soft glow.

### Octagon and diamond room shapes

They're just kind of arbitrary looking. They aren't interestingly different,
just different.

### Water

Since rivers and lakes don't have shorelines, you sort of stumble onto them,
can't see them much, and they don't do very much.

Also, using the reachability corridor algorithm for bridges makes for really
silly looking meandering bridges.

I added little stream decor in rooms, which is kind of neat looking. But it's
also totally random. It would be really cool if the streams separating rooms
were meaningfully connected to some hidden underwater water source so that you
would expect to see the stream continue across other rooms.

### Starting room and stairs

The hero just starts in a totally random tile. It would be good if it felt like
you began in something like an antechamber.

Likewise, stairs are totally randomly sprinkled on the floor. They should be
somewhere that seems meaningful.
