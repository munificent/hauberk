I've been thinking about revamping how classes and skills work. The current
system is quite mechanically complex with different mechanics for different
kinds of skills.

I had an idea that different skill mechanics would lead to different play
styles, which would in turn appeal to different players. The idea with
disciplines for warriors is that those kinds of players don't want to spend a
lot of time fiddling with a long list of skills.

That's a good idea, but it's not the only way to cater to different play styles
and it means a lot of extra mechanics to figure out and tune. If warriors don't
want to mess with a lot of very narrow skills, one option is to simply give them
fewer skills to choose from.

So instead of different skill mechanics for different classes, here's a sketch
for a simpler design.

## Class powers

Each class has access to a list of powers. Each power can be leveled up by
spending experience. Leveling up a power can do one of a few things:

*   Improve some capability passively. For example, "Slay Animals" will
    increase the damage inflicted on animal-typed monsters. "Archery" makes
    ranged attacks more effective.

*   Grant access to one or more usable skills (see below).

### Class power list

What defines a class is essentially the list of powers it has access to. If you
think of each power as similar to a skill in Diablo, then it's very similar to
that mechanic.

I haven't decided if powers have prerequisites like Diablo where it forms
something like a skill *tree* or whether it's just a flat list.

### Class play styles

The way we vary play styles by class is by which powers they have access to and
how many. Warriors get a less fiddly play style by having fewer powers, and
having more of them grant passive capabilities instead of skills.

However, even warriors can have powers that offer skills.

### Spell schools

For magic-using classes, each spell is not a separate power. Instead, each spell
school is. Leveling up a spell school grants access to higher-level spells in
that school.

We could make each spell a separate power. That works for Diablo where mages
have relatively few spells. That in turn makes sense in a real-time game where
selecting spells needs to be very fast. But for Hauberk, I want mages to have a
pretty long list of spells since they have more time to choose between them.

### Shared powers

An open question is whether each class (and/or subclass) has its own entirely
disjoint list of powers or whether some or all of them are shared across
classes.

I like the idea of classes being pretty distinct so that each one has its own
feel and play style. That seems good for replayability. So I wouldn't want *too*
much overlap across classes. It would suck if the only thing different between
a rogue and a warlock is slightly different experience costs to train stuff.

At the same time, some skills seem general enough that I can see multiple
classes having access to them, like weapon skills or slaying.

Also, the more overlap there is, the more likely an ego item that boosts a power
will be useful to the hero. Highly disjoint hero needs mean any random item is
less likely to be useful.

Compared to a game like Diablo where each skill needs a lot of custom art and
animation, adding powers and skills is fairly cheap in Hauberk, as long as I can
come up with a good name and use for it. If it seems like two classes should
both be able to do a thing X, it's feasible to give each of them their own power
or skill that provides their own take on X. We don't *have* to have shared
powers to enable that. For example, mages might have a healing spell while
druids have some sort of herbal medicine thing.

### No primary classes

We get rid of the notion of "primary" classes, warrior, mage, priest, and rogue.
It never really held together anyway.

Instead, we simply design classes that are cool and give them powers that make
sense.

There can be various flavors of magic-using classes that have their own sets of
spells. Rogues are pretty much warrior-like, but with powers that enable them to
do better outside of melee: sneaking, improving monster drops, etc.

There's no general notion of a "priest". Instead, there are separate classes
who each derive power from various supernatural entities in different ways.
Those powers can be a mixture of granted powers, prayers, or whatever. In
practice, they are all still simply modeled as passive boosts or skills the
user can perform.

We can explore piety as a mechanic, but for now, discard it.

## Ego items

One of the main thing ego items can do is boost the level of various powers.
This works uniformly across classes since they all use the same leveled
power mechanic.

There's an interesting question of whether an ego item that gives you levels in
a power your class otherwise doesn't let you access should still work. That
could be an interesting way to widen the play experience and create
semi-dual-class characters.

## Skills

A skill is an action the hero can perform. Each spell is a skill, as are things
like "Shield Bash", "Lock-picking", etc.

Skills are not levelable. You either have them or you don't. But maybe some
powers can boost some of their numbers.

### Focus

Most skills spend focus.

We eliminate the mechanic where taking damage lowers focus. Instead, focus works
pretty much like mana but is thematically not intrinsically "magical" and works
for any skill that uses brainpower and needs to be rate limited.

We combine intellect and will into one mental stat whose name is TBD. Maybe
"discipline". The stat determines maximum focus in the same way that fortitude
determines max health. It's sort of "mental capacity and fortitude".

Mage players will do most of their damage from spells which consume a lot of
focus, so they'll need to train that stat up more than other classes. That in
turn means they'll have less room to train physical stats, so will still be
incentivized to stay out of melee.

Warriors will have some skills that use focus, but fewer of them and using less
focus, so they can afford to be more hot-headed and dumb.

### Focus attacks

Most attacks from monsters harm you physically and drain health. But we also add
mental attacks that drain focus.

## Class sketches

OK, given that, here's a stab at sketching out some classes and their
powers:

### Warrior

Won't have a lot of powers or skills and most are working now:

*   Weapon masteries. Makes weapon more effective and grants things like
    sweep or short-range attacks like we currently have.
*   Slaying. Improves damage for monsters of certain kinds.
*   Something like stone skin that passively raises armor.

The main difference is that players deliberately train these instead of them
passively training.

### Mage

Not sure if I want a "general" magic using class. But if so, then a power for
each spell school.

### Elementalist

A mage focused on elemental spells. Is it really just one spell school? Any
other powers? Maybe we subdivide spells in a school a little further
like "fire spells", "water spells", etc?

Likewise other magic-using classes for sorceror, necromancer, etc.

### Warlock

A sort of "battle mage" that has some spells and some melee ability.

*   A couple of spell school powers. The experience cost to raise them
    is higher than for a direct magic using class. Maybe the level is capped.

*   A couple of the warrior skills.

### Rogue

*   Some warrior skills.
*   Sneak. Reduces sound when walking.
*   Backstabbing. Reduces sound and increases damage when attacking sleeping
    monster.
*   Looting. Increases drop rates.
*   See in shadows. Increases visibility in low light.

### Priest

A Christian-adjacent worshipper. Has prayers that work much like spells. Also
some powers for granted powers like awareness of evil.

### Druid

A nature worshipper/magician. Bunch of nature-related spells. Maybe passive
abilities to tame animals or make them less aggressive.
