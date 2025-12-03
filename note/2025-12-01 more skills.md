## Currencies and motivation

There are two main currencies in the game: experience and gold. Each is
connected to a family of capabilities. For experience, it's stats and class
powers. For gold, it's items and equipment.

Why have both? We could just unify them. Since you tend to get gold from
exploring the dungeon and killing monsters, it's also a decent proxy for
experience. We could simply sell stat potions and class power upgrades in the
town and have one unified mechanic.

That would work, but I think there's merit in having both if they tickle
different pleasure centers. For experience, it's the reward of methodically
saving up and earning a purchase. Killing monsters reliably provides XP, the
experience costs are known and fixed, and the "experience shop" (the screen
where you spend experience) always has the same goods for sale. This gives the
player an arena where there is enough stability and control to feel that they
can slowly save up for something over time and then purchase it.

Meanwhile, gold and good items are dropped randomly and unpredictably. Even the
shops randomize what they sell. So gold and items scratch the "slot machine"
itch. Every time you kill a monster and it drops something, you're hoping to
strike big. But that also means accepting that you may get nothing.

Those two feelings are distinct and important enough to the roguelike play
experience that I think it's worth having both. I also think this suggests
keeping them fairly separate from each other. I've been considering whether you
need to find spellbooks or other special items to unlock class powers that you
can then spend experience to purchase. The above line of thought suggests the
answer should be "no". Otherwise, if we do, it means the experience shop is also
stochastic and subject to the roll of the dice.

## Class power acquisition mechanics

The previous observation is helpful because maybe it can help me resolve the
open design questions about spell discovery and other class power discovery
mechanics. This suggests that whatever we do, they shouldn't be randomly
determined. That in turn means they shouldn't depend on finding items like
spellbooks.

So, to make them entirely deterministic, they need to be either:

*   Immediately known to the hero at creation time.

*   Discovered and unlocked by some other deterministic mechanic. Since most of
    the rest of the game (dungeons and items) are pretty random, that suggests
    only previous things in the experience store can unlock others.

In other words, something like a skill tree where you have a set of immediately
available powers/skills/whatever that you can spend experience to purchase. And
some of those might unlock later ones.

That sounds pretty cool to me. It means the dungeon and items are a part of the
world and character development that leans heavily on chance that being
opportunistic. Meanwhile, there is a parallel world of experience-driven
character development that the player has full control over where they go. I
think this could help the problem I've observed where the game doesn't feel
"sticky" because you have so little control over how things will go.

## Class power trees

The next step (which is the hard part) is figuring out what those class power
trees look like:

*   What are the set of classes?
*   What are the initial accessible powers for each class?
*   What other powers can be unlocked and what do they depend on?
*   How do those powers map to passive capabilities and usable skills the player
    can perform like spells and weapon special attacks?

The only mechanic you have for powers is spending experience to level them up.
(You can think of initially gaining a power as leveling it from zero to one.)
That implies that skills and other dependent powers are always unlocked by
leveling a power.

## Mapping powers to skills 

The next question is how powers maps to passive boosts and usable skills. Some thoughts:

*   It kind of feels weird that leveling a power could grant both some improved
    passive ability *and* access to a new skill, so it sort of feels like those
    effects should be kept separate.

*   At the same time, for something like "axe mastery", I don't know if it makes
    sense to have a separate power for "doing more damage with axes" and "the
    special axe swing action".

*   I like the idea of having powers for a spell school or spell type that boost
    all spells of that type. That makes it easier to have ego items that help a
    range of spells.

*   We could also support spells being individually leveled, but that feels a
    little strange. It seems like it would be annoying to have to choose between
    making one spell better or all of the spells of a type.

*   Giving players some control over which specific spells in a type they learn
    could be nice, versus them just unlocking in some specific level order.

*   I'd rather players not have to spend experience on "dead end" powers or
    skills that they need to level up to survive the early game but which then
    become entirely useless later. (This is also a good reason for spells to
    grow in power so they don't get aged out.)

## Powers, skills, and hero actions

OK, here's a pitch for how to map skills to things the hero can do:

For the usable weapon skills like using a bow or doing axe sweep, I think they
should just be globally accessible actions that all players can do regardless of
skill. The weapon skills may improve their effectiveness, but let's just make it
a core mechanic for combat.

Dual wield is a passive skill. All players can dual wield, but the passive skill
makes you better at it (by reducing the heft penalty).

Aside from those, spells are the only other "skills" in the game that provide
usable actions. That suggests to me that instead of some unifying notion of
"usable" skill which still doesn't encompass things like walking and melee, we
should have a hardcoded list of things the hero can do like:

*   Walk
*   Melee
*   Toss item
*   Axe sweep
*   Spear stab
*   Fire arrow
*   Cast spell

Then hero actions are not directly coupled to specific class powers / skills.
There's no "use skill" UI. Instead, each of those things gets it's own key
command. This is already true for most things on that list, so it's just adding
dedicateds input for casting spells, weapon special attacks, and ranged attacks.

Casting spells is a separate mechanic built directly into the UI and not a
subset of using a skill. (This also conveniently frees up "skill" to refer
exclusively to the trainable thing you can spend experience on.)

## Spells

*   For spells, the mechanical questions are:
*   What determines whether a hero knows a spell exists at all?
*   What determines whether they "know" it and can cast it?
*   How do skills effect spell power?
*   How do "spell schools" work?

There's another question around rate-limiting use of spells, but for that, I
think it's just "use focus like mana".

### Spell discovery

I know I said earlier that spell acquisition should be entirely deterministic.
But I do think spellbooks and discovering weird rare spells could be a fun
mechanic. The important part is probably making sure that the bread and butter
spells are in spellbooks that are reliably available. Let's keep that mechanic
around at least for now. So spells are discovered by finding the right spell
book. Using the spell book adds its spells to your list of known spells. You
don't need to keep the spell book on hand to use the spell.

### Spell acquisition idea 1

In addition to skills for each spell school, there is another separate
"Spellcasting" skill. Each spell has a level and in order to use the spell, your
spellcasting skill must be at least at that level. So you level Spellcasting to
access more powerful spells. And you level the spell school skills to make those
kinds of spells more powerful.

No, that doesn't hang together. If we don't limit spell power by school in some
way, then you can access the strongest spells of all schools. I'd like the skill
system to be tuned such that stronger characters are forced to specialize.

### Spell acquisition idea 2

Could just keep the current mechanic where you need a high enough intellect to
learn a spell. That also has the same problem where a high intellect character
can access powerful spells of all schools.

### Spell acquisition idea 2.1

Could keep the current mechanic where you need a high enough intellect to learn
a spell. But leveling up a spell school skill lowers the complexity of spells in
that school making them easier to attain.

This is probably just the next idea but with extra steps.

### Spell acquisition idea 3

Each spell has a school and a level. To use the spell, your level in that school
needs to be at least at the spell's level.

I've hesitated about this design because I think leveling up the school should
also make spells in that school more powerful. It feels a little weird for the
school to have a double effect in that way. But it does encourage players to
specialize and makes it much less likely that a character can access the
strongest spells of all schools unless they really grind.

### Spell acquisition idea 4

In addition to schools for each flavor of spell, schools are further subdivided
into a couple of power levels. So each school has like a weak and strong
subschool and those are separate skills. Each school grants access to all of the
spells in that school. We make having a certain level of the weaker school a
prerequisite for unlocking the stronger school.

The problem here is that points spent in the weaker school don't benefit spells
in the strong one and vice versa.

### Spell acquisition idea 5

Here's a more radical idea. No spell schools. Instead, every spell is its own
individually levelable skill. Spells form a skill tree where you must level
weaker spells to unlock more powerful ones.

This encourages players to specialize because the cost to reach high level
spells is the cost to train the entire set of spells along the branch to it.

By itself, this isn't great because points spent on a weaker spell become wasted
if you end up primarily using a stronger one. Also, it's hard to make ego items
that affect a number of spells.

But we could also do something like Diablo's
["synergy"](https://www.d2tomb.com/synergies.shtml) system where points in some
skills benefit other skills too. I definitely don't want to hardcode a long list
of arbitrary synergy pairs. This feels like a dead end.

### Spell acquisition idea 6

More powerful spells have higher experience cost. So they're harder to get
because you have to save up more for them. That could discourage players from
getting weak spells at all. To avoid that, the experience you spent learning
other spells in the same school acts as a discount to that cost.

Hmm, I think the math for that doesn't work out when you think about how that
would work across multiple spells in the same school. You could double dip a
discount.

### Spell acquisition idea 7

You spend experience to learn a spell.

Each spell has a prerequisite for how many other spells in the same school you
need to learn before you can learn it. There is always at least one spell in the
school with no prereqs to get it started. But the most powerful spells will
require you learn most of the other spells in the school first. Since that's
costly, this will also encourage specialization.

This could work. But it could be annoying if you have a spellbook for some
powerful spell you want but it needs one more random weak prequisite before you
can get it, and you don't happen to have a spell book for that prereq.

### Spell acquisition idea 8

As today, every spell has a "complexity" that determines the intellect the hero
must have to be able to cast the spell.

There is a skill for each spell school. Leveling up the skill makes spells in
that school more powerful. But it also lowers the complexity of spells in that
school.

Some spells have a complexity so high that the only way to access it is by
having leveled up the corresponding spell school to put the complexity in range.

I don't generally like a skill having two powers, but I think this one
works. It's always useful to level a spell school because it makes existing
spells more powerful. But also it separately acts as a threshold to access more
powerful spells. I don't generally dig thresholds like this, but in this case
since the skill also has a separate incremental effect, it might hold together.

I do like that this approach doesn't require spending experience points on
spells. I like the idea of experience being focused on stats and skills. I
think this could work.

## Summary

OK, so the changes I have in mind are:

*   Take the weapon special attacks and archery out of skills and make them
    actions the hero can directly perform, like tossing or walking.

*   Take the slay disciplines and pretty much eliminate them. I think slaying
    should be a modifier that items can have but not probably not worth making
    them a trainable skill.

*   Turn rest of the auto-training disciplines into skills where you level them
    up by spending experience.

*   Add skills for each spell school. Make spell complexity take their level
    into account.

*   Put each spell in a school, and tweak its effect to depend on spell school
    skill level. Turn spells into a separate thing from skills.
