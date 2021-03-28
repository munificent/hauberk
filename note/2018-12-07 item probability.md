TL;DR: Try to produce the best item of a given type under a given price.

Item generation is pretty complex. We want to tune probabilities overall. Some
monsters prefer to drop different kinds of items. Depth needs to come into play.
Then affixes add another layer of complexity.

Examples of the properties I'd like the system to support (in addition to the
stuff it already does well):

- Items that form a "chain of betterness" don't have weird probability bumps
  where their ranges overlap. For example, if balms are found from depth 1 to
  10 and salves from 11 to 40, the odds of finding some kind of healing should
  be smooth across the whole range 1 to 40, and not have a hump around 10 where
  the two overlap.

- Equipment that's relatively worse than the depth found (or monster that
  dropped it) should be more likely to have an affix. Likewise, finding a
  stronger base item than expected it should make it less likely to have an
  affix.

- Weaker equipment should become relatively rare deep in the dungeon. Even with
  affixes, you don't want to wade through a lot of knives and walking sticks.

Here's an idea that kind of combines the current system and the old data-driven
approach with some new stuff:

+ Items have a range of depths where they appear.

+ Items that form a series are given non-overlapping ranges.

+ Items are tagged and form a hiearchy so that monsters can control which kinds
  of items they drop.

- Each drop specifies a max price as well as a tag.

To generate a drop, we find all of the items that match that tag. Then we roll
a random price centered around the max price. We generate a number of items and
pick the highest-price one that's still under the random price.

If the item is equipment, we generate a number of random affixes and find the
best item/affix combination that still fits under the price.

We could conceivably take this farther and eliminate the idea of "depth" for
items completely. Items would *only* have prices and that would determine what
gets dropped.

In practice, I think that's a bad idea because we probably want to be able to
have things like worthless (or bad) items that show up later in the dungeon.

---

Conversely, we could go in the other direction and lean on depth. Each affix
has a "depth cost". When generating an item, we:

1.  Pick a random item as usual.

2.  Determine how many "depth points" are remaining. So a depth 4 item that gets
    generated at dungeon depth 12 has 8 free depth points.

3.  Try to pick an affix that uses up the remaining points.

4.  If the remaining depth points is too high, consider discarding the item
    because it's just too weak. An easier fix for this, though, is probably to
    just put an upper end on the weaker equipment.

Another way to do this might be to choose affixes based on relative depth. So
the "depth" for each affix is actually how out of the depth the item is. If we
drop a depth 5 item on depth 8, we look for a level 3 affix.

Depending on how that's tuned, that might make it impossible for high-depth
items to ever have high-depth affixes.


