I made a new dwarven warrior character and found a leather cap in the dungeon.
As soon as I put it on, it lowered my strength which seems a little silly given
that the character had no other armor. The stats were:

* A level one human has 12 strength.
* A leather cap has weight 2.
* A walking stick has heft 10.

Maybe there's something wonky about the mechanic here. Here's how it currently
works:

## Weight

Every piece of equipment can have a weight value. Affixes can modify it. Shirts
and robes have none, but body armor goes up to 7 for scale mail. Leather cap is
2 and great helm is 8.

Elven armor affixes have negative weight to make the base armor lighter.

Weapons don't currently have any weight, but the engine supports it.

## Heft

Every weapon has a "heft" value. This is the amount of strength the hero needs
to wield that weapon effectively. If their strength is less than the heft, then
the damage of the weapon is reduced, and damage goes way down the worse the
difference is. On the other end, if their strength is greater than the heft,
they start getting a damage bonus.

## Weight strength modifier

Every point of equipped weight subtracts a point from the hero's strength. It's
an immediate negative modifier. Wearing armor basically "spends" strength.

This means that wearing heavier armor makes it harder to use heavier weapons.
That makes sense.

What else does strength do? Currently not much. It affects the range you can
throw things, and it tweaks the fury scale. The former seems to make sense with
heft. If you've got heavy armor on, you aren't going to be able to yeet stuff
as effectively.

## Stats

Overall, I think the weight and heft mechanics make sense. I like the interplay
and trade-offs between weapons and armor. It's more the stats that are weird.

There's already some problems with stats:

### Initial stats

Players start out as basically undifferentiated. Every human has the exact same
stats. It's nice for having room to grow, but it kind of makes them feel
unformed in the beginning.

### Races and class

Your stats are determined entirely by your race. At character creation, we
calculate the maximum value of every stat based on the race (with some added
extra random points) and then those are doled out at level up time.

The player has no other control over stats, aside from equipment and maybe stat
gain potions if those become a thing.

Certain classes lean more heavily on different stats, so that means that for
each class, there's a strong affinity for which race works best. You *can* make
a dwarven mage, but you'll basically be punished for doing so for the entire
game.

That means that even though we support a lot of combinations of race and class,
we don't get that much variety in return because many of those combinations are
just duds.

### No player control

In Diablo, when a character levels up, the player gets a couple of points to
allocate towards stats however they want. That gives them some agency over how
the character develops. Right now, in Hauberk, the only choice you make is an
initial race.

Last year, I wrote a note exploring using experience a currency and before I
re-read that, I went through almost the exact same entire design process in my
head again.

I think it's really promising. One idea I want to explore building on that is
around subclasses and titles. I'll start a new note for that.
