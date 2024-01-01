I want to get artifacts working.

## Representing artifacts

Mechanically, I plan to model them as affixes that are unique. Reusing the affix
code makes sense because artifacts are mostly a modifier of some more
fundamental item type. Importantly, affixes already contain the ability to
modify stats, brand attacks, etc. So building on top of affixes makes sense.

For artifacts that are one-off items like the Phial in Angband, I can just make
an ItemType for the underlying item that is otherwise never generated.

## Handling uniqueness

What does it mean for there to be only "one" of a given artifact? In particular,
if an artifact is generated in the dungeon but never found before the hero
leaves, is it gone forever? I don't like that mechanic. I always use preserve
mode in Angband. The way I think about it, an artifact is a singular but
long-lived object. If you leave the dungeon with one laying on the floor, it
doesn't disappear in a puff of smoke. It's still there in the dungeon. Some
monster or other hero may pick it up and wander off with it. They may die and
leave it elsewhere in the dungeon.

So uniqueness is less about an artifact disappearing, and more about ensuring
you never see more than one.

We could even say that if you sell an artifact to the store, someone else may
buy it and later die in the dungeon leaving it to reappear. But I think that
would be annoying in practice. If a hero deliberately sells an artifact, they
probably don't want it reappearing like a bad penny.

I think we model this by tracking each artifact in the hero's lore. An artifact
can be in one of two states:

-   **Non-existent.** This is the default state and means the artifact is
    absent from the hero's lore. It means the artifact has not been generated.

-   **Existent.** The artifact has been generated. It's in some inventory or
    equipment somewhere: on a floor tile, held by the hero, or in a shop. When
    a shop discards an artifact, it remains in this state, but will never be
    seen again.

(Note that these states are independent of the "found" bit used to track which
affixes are shown to the player in the lore page. An artifact can exist without
the hero/player knowing about it yet because it hasn't been discovered.)

When we're generating a new item and roll its random affixes, if we pick an
artifact affix whose existent bit is already set, we don't use it (either
discard the affix or re-roll the item or something). That prevents duplicates.

Otherwise, if we do generate an item with an artifact affix, we immediately set
its existent bit in the hero's lore.

Now, by default, this would mean that if a hero leaves the dungeon with some
artifact on the floor, it's gone forever. To fix that, whenever the hero leaves
a dungeon, we go through all of the items on the floor and set all of their
artifact affixes back to non-existent. That allows them to be regenerated later.

## Generating artifacts

When generating an item, we need access to the hero's lore. I can pass that in
as a parameter to `Drop.dropItem()`, but that does feel a little hacky. I'm
thinking about revamping how drops work.

While I'm at it, the way uniques generate "better" gear could maybe use some
work too. Right now, drops can just have a depth offset, so a unique drops as
if it's depth is higher than the depth it actually spawns at.

Then, when rolling affixes, we look at the item type's own depth compared to the
depth it was generated at. If an item is from a lower depth (i.e. is weaker),
then it's more likely to have affixes. Likewise, items from later depths are
less likely to have affixes.

The intended result is that random items tend to have a "goodness" taking both
item type and affixes into account that matches the generated depth. However,
for weapons, that fails to take heft into account. Later weapon types tend to
also have higher heft. So an item type from a later depth may be practically
less good to a low level player than an item type from a near depth with an
affix. Concretely, a Searing Dagger you can actually wield effectively is
better than a poleaxe you can't lift.

That suggests to me that maybe we want make "goodness" not a single
one-dimensional quantity approximated by depth used for generating items.
Instead, we could have "depth" and "quality" as inputs where depth determines
the item type and quality the chances and quality of affixes. (Rarity also
comes into play, both for item types and affixes, but that's maybe orthogonal
here.)

That would let us have uniques that drop enchanted stuff you're likely able to
use.
