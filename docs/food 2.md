The food mechanic feels like a pointless chore right now. The initial goals
were:

1. The player needs some way to recuperate the health lost during a battle.

2. It shouldn't regenerate fast enough to be helpful *during* a battle.

3. It should encourage the player to explore and not play too conservatively. In
   particular, I want to avoid the Angband play style where you always fully
   rest the second you're out of danger and you never go into battle at anything
   but full health.

4. Using some kind of items for this would give another kind of useful loot for
   the player to look for.

5. If the mechanics for managing regeneration are themselves
   interesting/fun/strategic, that could be good.

It accomplishes the first two. Now that there are shops and food is pretty
cheap, it doesn't accomplish three. We could stop selling food and force players
to find it in the dungeon, but I'm not sure that's fun.

Also, I question the goal. In Final Fantasy IV, I found the "war of attrition"
effect to be a drag. You grind through the dungeon getting whittled down by
monsters until you finally reach the boss on your last breath. (Or, in practice,
you use a bunch of heal potions right before hand.)

I think it may actually be more fun to let the player rest up before each
battle. That way, they enter each battle feeling heroic and mighty. Then, once
they've slain all of the monsters, they get a reprieve to catch their breath.
In order to make that still challenging, we just need to ensure that battles
have multiple strong monsters so that even within a single battle, the hero is
losing enough health to be threatened with death and to need to consume healing
items.

Four is nice, but not super compelling. We could turn "food" items into healing
ones so that "potion" isn't such an overloaded category. Or we could make food
work like "slow healing" potions that heal a few points each turn for a while.
That lets you use them in a battle as long as you aren't near death. It gives
players some choice about how to heal -- use the slow heal from food and hope
for enough easy rounds during the battle to regenerate, or use a faster-acting
but rarer heal potion?

In practice, regeneration didn't turn out to be fun at all. The hero is
basically in one of two states: in a battle, or not. When in a battle, each
turn counts and you can't regenerate usefully at all. Outside of a battle, you
have effectively infinite time so there's nothing mechanically interesting
about food.

Heck, we could make food items instantly heal but simply disallow using them
if there are any awake monsters, or some other rule that prohibits using them
in battle. ("It's too dangerous to eat right now!") One problem with that
specific rule is that it leaks information about whether there are monsters the
player can't see that are potential threats.

So let's try:

- Heroes can always rest and slowly regenerate when they do.
- Food items heal somewhat faster than that over a series of turns. Some might
  reduce poison too.
- Heal potions are instant, but also rarer.
