I've been thinking about how the game feels kind of meandering and pointless
to play. One thing that would help is if it felt more like the player could
pick goals and work towards them.

Saving up gold to buy stuff in shops is one way. But shops turn over their
inventory and eventually you find better stuff in the dungeon. Shops are mostly
intended to be for supplies. (It's not really clear if shops are that useful at
all.)

Going into the dungeon to get loot is obviously a big part of it. But that
feels more like pulling the arm on a slot machine and less more like steadily
working towards a goal. I want the game to have both of those: rolling for
random prizes and chipping away at player-determined goals.

Of course, grinding XP to level is the obvious big one. But currently, all that
really does is raise stats. It's not super visible and the effect is
incremental.

## Experience as currency

What if instead of experience working like D&D, we made it more like Minecraft?
Instead of a monotonically increasing value that provides benefits at certain
thresholds, it becomes a currency you can spend. The hero wouldn't have an
experience level. They'd just have spendable experience points.

Killing monsters would raise it. Then they can spend it on things like:

*   Raising stats.
*   Unlocking recipes.
*   Learning spells.
*   Improving disciplines.
*   Learning rogue tricks.

Basically, almost all character development that is intrinsic to the hero
themselves would come from spending experience.

## Race and stats

If you can spend experience to raise stats, then what do races do? I think the
simplest answer is that races change the cost to raise stats. If you're a dwarf,
a point of strength is cheaper than a point of intellect, and vice versa for an
elf.

That seems mechanically simple, effective, clear, and flexible. I like it.

## Class skills

Likewise, if you spend experience to improve various class skills like spells
and disciplines, than what does the class do? The same thing: different classes
tune the experience cost (and maybe max level) of the various skills.

That's already sort of how classes and skills already work with proficiency.
It's just that right now, proficiency does different things for different kinds
of skills:

*   Lowers the training cost to level up a discipline.
*   Lowers the focus cost to cast spells and also lowers the complexity
    (intellect cost).

All three of those mechanics are basically untuned and the math is a bit
arbitrary. I certainly wouldn't find having fewer equations I have to tune in
the game.

I like the idea of proficiency lowering the cost to learn a spell. It would
probably make sense to bucket that by spell school, so that the various
spellcasting subclasses have different proficiencies for different spell
schools.

## Character specialization

Let's say that lowering the cost to learn a spell is the *only* thing that class
affects for spellcasting. If so, then once you've learned a spell, you're
exactly as good at it as any other class. Should a necromancer be able to cast
divination spells as good as a diviner if they decide to burn the larger XP to
learn the same spell?

If you can grind and earn unlimited experience, that means regardless of class
or race, you can eventually max everything out. That doesn't feel right. I want
end game heroes to be diverse and not tend to all be maxed out the same way.
Heroes should get more specialized over time, not less.

One of the nice things about experience levels and a fixed max is that whatever
happens when you level up, there is a finite number of those and then you're
done.

Let's explore a few ideas for limiting experience grinding so that you
can't (easily at least) max everything.

### Experience cap

We could just have a hard cap on how much experience you can earn in total.
That would probably feel weird though. The cap wouldn't come into play at all
until it did at which point all avenues of hero progression stop.

But it would work.

### Experience curve

We could make it a softer limit. We could have the amount of experience you get
for killing monsters depend on the total experience you have already earned.
As you kill more, you incrementally get less and less experience. So you can
keep grinding, but it becomes less effective over time.

That would also help accommodate the exponential experience curve as monsters
get stronger. (Angband compensates for that now by dividing experience earned by
the hero's level, but we'd lose that affordance if we got rid of level.)

Tuning this curve might be difficult, and I worry that it would just lead the
game to feel like it gets slower and slower as you go on.

### Oppositional pricing

We could have the experience costs for various improvements take into account
which *other* improvements the hero has already bought.

For example, we'd make the cost to raise any given stat increase as the total
number of points of *all* stats that has been raised goes up. So adding a point
of strength wouldn't just make the next strength more expensive, but intellect
and will too.

Likewise, we could say that spell cost goes up with the number of spells the
hero knows, and maybe even more based on the number of spells in other schools
or something.

Using economic incentives to encourage interesting character development does
feel sort of abstract and unrewarding, though. Players should specialize their
heroes because it's *fun* to do so, not because when they dig through all the
math they are able to determine that it's economically efficient to do so.

### Skill trees

A really brilliant thing about skill trees is that they encourage specialization
structurally and graphically. Once you've unlocked a skill, then the skills
farther along its branch will generally be more powerful than skills on
unrelated branches. So players are naturally incentivized to go deep in their
character development instead of broad.

I don't particularly want to copy Diablo-style skill trees, but maybe there's
something along these lines that could work.

### Spell school prerequisites

Let's say that every spell has a "prerequisite" number. This is the number of
spells *in the same spell school* that the hero must already know before they
are allowed to learn that spell.

This would roughly model a per-school skill tree for spells (more like a graph).
It would mean that players can't jump directly to learning the strongest spells
because they may have to learn some weaker ones just to get the prereqs.

And it means that they are encouraged to focus on one school because otherwise
they are locked out of stronger spells if they spread too thin.

Seems promising.

### Spell school level

Let's say that in addition to learning individual spells (or maybe instead of),
the hero has a level for each spell school. They can spend experience raising
that level. Each spell has a level. They can only cast a spell if they have at
least the spell's level in the spell's school.

That would encourage specialization by school. Would it actually incentivize
that? I'm not sure.

### Affinity pricing

Sort of the opposite of oppositional pricing. We could say that the experience
cost for something gets cheaper as you get better in that thing. So knowing
more spells in a school lowers the cost of learning further spells in that
school.

Raising a stat makes raising that stat again cheaper.

We would have to be careful about a positive feedback loop leading to runaway
stat spikes. Characters should be diverse but not like *super* spiky in terms
of how their stats are allocated.

For stats, at least, maybe we don't need any biasing at all (beyond what race
does). Maybe the effects that different stats have will encourage players to
specialize sufficiently. If you're not using intellect for spells, you're not
going to spend stat points improving it.

### No spell school incentive

Maybe we don't need to directly incentivize players to continue to specialize
in a spell school. The spellcasting subsclasses exist to let players choose
that specialization. Maybe we don't need anything beyond that.

### Multiple experience currencies

Maybe another way to encourage specialization is to not have a single
monolithic experience currency. Instead, different player actions would earn
one of a few different kinds of tokens. Maybe one kind per stat?

So hitting monsters earns strength tokens, while reading scrolls earns intellect
ones.

Then stat gain and learning skills would have different currency costs.

One problem with this is that it makes harder to deliberately branch out with
your character. If you currently mostly do melee but want to get into
spellcasting, you're not able to earn the intellect tokens to get there.

This feels like a dead end.

### Class specialization during character development

In this note, I've gone back and forth around whether spellcasters should be
encouraged to specialize in a spell school as they develop the character or
whether they just pick a specialization at character creation time.

How about making subclasses/titles also things you can buy with experience?
So you start out as one of the basic classes (or do you?). And then you can
buy specializations and titles later on that also sort of work like classes in
that they tweak proficiencies.

So you would roll a mage. Then in the game you luck out and stumble onto a
necromancy spellbook so decide to specialize in that. After earning enough
experience, you buy the necromancer subclass. That maybe makes it cheaper to
learn necromancy spells. Though if that's all it does, then once you've learned
a bunch of those spells already, there's no reason to get the title.

Maybe these titles have other effects? They could lower the focus cost for
spells in a school.

And it seems natural to limit the hero to having only one or maybe two of these
titles at a time, so that naturally encourages some specialization. You can't
be both a diviner and a necromancer at the same time.

Also, this gives a way to add a lot of flavor to the game with all sorts of
cool role terms: assassin, warlock, barbarian, etc.

We could also have a few levels of titles with increasingly powerful effects
but where you have to have the previous one to earn the next. Almost like a
skill tree for subclasses. Neat.

If we made the first class also work this way, then we could remove class
selection out of character creation. Every hero starts as an adventurer. Maybe
you start with enough experience to pick a base class and/or boost a stat or
two, sort of like how you have some starting money for equipment.

This is all very like Tactics Ogre, which I loved.

## Proposal

OK, tying that together, here's a concrete proposal:

### Experience

Killing monsters and maybe doing other stuff like exploring the dungeon earns
you experience. The rate that you earn it is fixed and not curved, just like
gold.

### Stats

You can spend experience to raise a stat by a point. The cost to raise the stat
depends on:

* The hero's race. Races scale the stat costs.
* The total number of stat points the hero already has. As you raise stats, any
  stat, all stats get more expensive to raise. This way, you can't be maxed at
  everything unless you really want to just pour experience in.

But that's it. There's no curve for raising a stat based on that stat's own
level or anything. But you can't raise it past some max either.

### Classes

At character creation time, the player can choose from one of a few templates
that are basically just fast forwarding through what they could do starting
from a bare character: earn a little gold and experience and buy some gear and
a base class. One of the templates is "adventurer", which doesn't pick a class
at all.

Classes (and subclasses) are ordered like a skill tree. To earn a class, you
have to already be in its parent class and spend the experience cost. You can
only have one class or subclass at a time.

Can you go *back* to a less specific class? Let's say no. Specialization is an
irrevocable choice. Gameplay should have consequences.

Classes have "proficiencies", various ways that they make the hero more
effective. Things like lowering the focus cost of certain spells or spell
schools, increasing the damage of certain attacks. I'm not sure. TBD, but
hopefully not too many different mechanics.

Classes do not effect the experience cost of anything. It should make sense to
choose a subclass even after you already have all of the skills that subclass
helps.

### Skills

I'm not totally sure how I want experience to work with skills beyond some
vague notion of spending experience to gain skills. Right now, each major class
has its own category of skill (discipline, spell, etc.) and the idea has always
been that each has its own leveling mechanics.

#### Disciplines

For what it's worth, I've never found the passive discipline leveling
particularly *fun*. It never feels very intentional. But maybe I just haven't
played enough for it to matter.

For now, let's leave disciplines alone.

This means that, compared to mages, non-spellcasting characters have fewer
things to spend experience on. That in turn implies they will spend more of it
on their stats. So warriors will be stronger, tougher, and more willful. That
makes sense. Spellcasters have basically devoted all of their time and energy
into mastering magic at the expense of their health and body.

But would warriors end up raising intellect and wisdom more then a spellcaster
would too? Probably not. Spellcasters will need to raise intellect at least.
Probably likewise for priests and wisdom.

I'll leave this alone for now, but an easy alternate option is to spend
experience leveling up disciplines instead of doing so passively.

#### Spells

Before you can learn a spell, you must find a spellbook that contains it. Then,
you can spend experience to learn it. The cost is fixed and determined by the
spell.

Each spell has a complexity level. In order to learn it, you must have equal or
greater intellect. Every spell you already know in that spell's school reduces
its complexity by 1. The most spells of a certain flavor you know, the more
easily they come to you.

Classes may adjust the focus cost of casting spells in a certain school.

#### Rogue skills

I'm not sure about these yet.

#### Priest prayers and granted powers

One idea is that you can spend experience currying favor with your diety... but
you don't get to pick what you get in return. Instead, a random granted power
or prayer is given to you.

### Separate skill categories

For many years, I've had this idea that there are four base classes and one
category of skills for each with its own mechanics. Subclasses might allow
skills from multiple categories, but there still some 1-1 association between
the four main classes and the four flavors of skills.

But that's a design choice, and one that feels a little arbitrary if we move
towards subclasses and later specialization. Maybe there should be a few
different kinds of skills in terms of mechanics, but that those aren't 100%
tied to a class.

Something like:

-   **Discipline.** Passively trained by doing the thing it improves. Levels up.
    Strongly used by warriors, but also by rogues. Could have disciplines for
    improving spellcasting in certain schools too. Basically, any kind of hero
    action that could be recognized and improved numerically is something we
    could make a discipline for.

    Some disciplines also expose an active skill, which usually requires you to
    have a certain item. These are a good fit for warriors, but for rogues too:
    lock picking, assassination, etc.

-   **Spell.** Discovered from books, learned by spending experience. Requires
    intellect to learn. Doesn't level up: you either have it or don't. Actively
    used by spending focus.

    Organized into schools. Some subclasses and affixes lower the focus cost of
    spells within a school.

-   **Power.** An innately or divinely granted power. Can be given by a deity.
    May give a passive effect or allow active use but generally can be used as
    much as the player wants: just a thing you can do.

    Priests would lean heavily on these but necromancers might also. The line
    between mage and priest gets blurry for occult-like classes.

    Could also have races grant some of these.

-   **Prayer.** The things priests do that are more powerful than granted
    powers but maybe less predictable or resource constrained in some way. Are
    these just "priest spells"? Maybe. Or maybe these use some different "piety"
    mechanic.
