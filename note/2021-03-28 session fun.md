Right now, you essentially wander the dungeon randomly until you stumble into an
encounter. You get through that, rest, and then keep going. There aren't really
any interesting *choices* to make around where or how to explore. Seeing the
dungeon get filled in is somewhat satisfying, but it doesn't carry the same
weight as exploring in Minecraft.

## Time spent in an area

Part of it is that the dungeon doesn't really *matter.* It's the setting for
encounters, but otherwise it's fairly inert and ephemeral. Once you've cleared a
room, you never really revisit it except to pass through. It's not like
Minecraft where a new area is rich with resources and a place where you may
settle, build, and spend significant time in.

I don't want to move to persistent dungeons or anything like that. Hauberk is
a roguelike, not 2D ASCII Minecraft. But it would be nice if lighting up the
dungeon felt more exciting and rewarding. In the past, I've assumed that having
a sufficiently rich dungeon generator would do that, but I don't think that's
true. Because even a really complex, varied dungeon doesn't matter much if
ultimately it's just a 2D box to kill monsters in once and never revisit.

Maybe a solution is to slow things down and make encounters take longer. Players
would end up spending a decent number of turns in each room and all its local
features and quirks would matter more. Imagine they enter a room with a table
and chairs. They cast a fireball that kills one monster and turns a chair to
cinders. That gives them a line of sight to another monster hiding behind it,
which leaps to attack them. Make it feel like each battle is really *in* a
place, and that the player's actions leave a real mark on it beyond just picking
up loot.

More destructibility. Chairs that can be pushed around. Chests and doors to
open. Traps.

Battles leave bloodstains and burn marks.

Also make more tiles be useful resources. Refill your waterskin from a lake.
Pick up rocks to enchant and throw. Use grass as a spell component. Uncover
hidden treasure.

Instead of a quick battle every few steps, have fewer bigger encounters more
spread out. So when the player is in an encounter, they're really in it and in
that space for a while. And when they aren't in an encounter, they have a good
amount of time creeping through eerily quiet spaces letting their anticipation
build. Let the dungeon generator's theming foreshadow the encounter they will
eventually have.

## Food

I want to rethink the food mechanic. Right now, it's an uninteresting chore. My
high level goals are:

*   Health places a limit on how big/long of an encounter you can survive.

*   But each encounter is mostly independent. Players mostly enter encounters at
    full health. In fact the definition of "encounter" is basically the series
    of turns until you're able to rest.

*   An entire session isn't a war of attrition with health slowly decreasing
    throughout. There is some attrition with other consumables.

The intent of food right now is that it accomplishes those goals by letting you
heal too slowly to use in encounters but works between them. This is because
the dungeon itself doesn't know what an encounter is. They are an emergent
property of dungeon layout and monster sleeping.

One option would be to make that more formal. Imagine that opening a door
awakens all monsters in the new room. Once they are all dead, the encounter is
over and the game knows it. Monsters never open doors and monsters in unreached
areas are asleep. Players would automatically re-heal once the encounter is
over.

Not a crazy idea, but it feels too structured. Doesn't play well with
destructibility.

The easiest change here is to just eliminate food and let players rest when they
want without having to worry about buying food. It worked like that for a while.

One property of food now is that it functions effectively as a session clock.
The amount of food you bring with you determines how *many* encounters you can
make it through before you run out. If you don't bring enough, you have to
leave the dungeon before fully exploring it.

Is choosing how much food to bring an *interesting* choice? Not really. It's
always better to be able to stay longer if you want to, so the optimal strategy
is to just bring more than enough. It's cheap and stacks, so there's little
downside to it. Running out of food is mostly not a big deal. Leaving the
dungeon early, restocking, and entering a new dungeon isn't very different from
staying in the same one.

If we want something like a session clock to be interesting, then we probably
need:

*   Some negative consequence to carrying a lot of food. Cost, weight, taking
    up multiple inventory slots.

*   Greater rewards the farther you go in a single dungeon. Maybe clearing
    bonuses.

I don't personally enjoy feeling like I'm on the clock, so maybe just eliminate
this entirely. Let the player rest whenever they want. Or maybe auto-heal when
all monsters are asleep. If the player *only* auto-heals when all monsters are
asleep then that might make for an interseting mechanic where when the player
needs to rest they have to try to figure out how to get away from monsters and
be quiet.

## Exploration incentive

One problem is that there's no real incentive to keep exploring the dungeon. If
you're between encounters and you're choosing between:

1.  Take the stairs and return to the town now, then re-enter a new dungeon.
2.  Keep exploring.

The best answer is basically always 1. Because that gives you a chance to save
your progress, sell gear, and stock up. The longer you're in the dungeon, the
more unsaved progress you have, so the game basically *punishes* you for staying
in the dungeon.

Of course, going to full permadeath solves that because then leaving doesn't
provide much benefit.

Simply not having found any stairs is a forcing function to make the player
explore. But that doesn't make them *want* to explore, it makes them *have* to.

Having more to lose as the session goes on is OK, because it feels like the
stakes are being raised. But there's no corresponding reward, except to the
degree that "keeping your stuff" is a "reward".

Ideas:

*   Level feelings which hint to players interesting stuff they may find.

*   Tweak dungeon generation so that more/better loot appears farther from the
    player.

*   Bonuses for clearing the dungeon. Letting the player pick from a couple of
    reward items would also give them a little more control over loot
    acquisition.

*   Require clearing the dungeon or reaching far into it in order to unlock
    later depths, other areas, or complete quest goals.

*   Don't grant experience until they leave, and scale it super-linearly. So
    killing monsters worth 100 XP twice in two dungeons gives you less total
    than getting 200 XP in a single one.

    It essentially turns the whole dungeon session into something like a combo
    multiplier.

*   Force the player to pay some cost (XP, gold, etc.) to enter a dungeon. So
    you need to stay long enough to cancel that out and make it profitable. This
    feels weird and punishing, but could work if we do multiple areas and make
    weaker dungeons cheaper. It might help prevent dungeon scumming too.
