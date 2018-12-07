two things to calculate:

- chance of any affix at all
- which affix(es)

- probably want chance of affix to vary based on type
  - magic helms might generally be rarer than magic weapons, etc.
- implies we should just store "no affix" in the resource set
- that simplifies problem to

- which affix(es)

- also want item type to affect value of affix
- finding weaker item deeper in dungeon should increase odds of better affix
- likewise, finding strong out of depth item should be unlikely to also have
  affix

- implies we should do some amount of "relative depth" for choosing affix
- going too far with this could make it impossible for high level item to have
  high level affix -- you'd have to be 200 levels down to get it

- don't really want to author affixes in terms of relative depth because i
  think that would make the content code a little confusing to read

- so i think if you find a level 90 item at level 90 in the dungeon, it should
  try to have a level 90 affix

- a level 90 item at level 70 in the dungeon should have a level 50 affix

- a level 20 item at level 40 should have a level 60 affix? that seems
  gratuitous. whips and daggers will end up overpowered.

---

Equipment tend to come in series like knife -> dirk -> dagger, etc. where there
are a range of similar items with better stats that appear deeper in the
dungeon. A challenge is figuring out how that interacts with affixes.

There are two models I can think of:

*   The "total value" model. An item generated at some depth should have a
    certain total value to the player based on that depth. If we generate a
    weaker item type at a deeper depth, it should have better affixes to
    compensate for that. Conversely, a stronger item found shallower should be
    less likely to have affixes or have weaker affixes.

*   The "base quality" mode. An item's base type indicates the underlying
    quality that went into creating it. Knives should not have very powerful
    affixes, because what alchemist would bother to do that to a lowly knife?
    Likewise, stronger items are more likely to have better affixes.

    This means part of the value proposition of more elite item types is that
    they are more likely to have better affixes.

The "base quality" model feels intuitively more realistic to me. Bu I'm worried
about that model because more elite item types also tend to have greater heft
and weight. We don't want to limit the better equipment affixes to just
warriors. That's somewhat mitigated by different item categories. A rogue will
never wield the strongest sword, but they might have the best kind of knife.

I do think this makes it more complex to author item base types. It puts
pressure to define similar items that exist only to have a greater depth to
unlock better affixes. Think "dragon scale armor" that has the same stats as
"scale armor" but a higher depth and thus better affixes.

That feels tricky.

The total value model is conceptually simpler and maps more naturally to the
player's goals. They just want overall better stuff and whether that betterness
comes from the item type or affixes doesn't matter much.

I am worried that it means lower in the dungeon you'll find piles of knives with
insane affixes while the "better" items are unaffixed. That feels like it breaks
realism. But:

-   We can mitigate that putting max depths on weaker items. There's no reason
    to give knives a range all the way to 100.

-   If we're willing to assume magical items of weaker types *would* get created
    somehow, than it's reasonable to find them lower in the dungeon since
    heroes wielding them would survive farther.

OK, so let's go with that model.
