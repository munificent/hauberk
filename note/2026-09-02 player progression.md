Over the past year, I've made a lot of progress revamping classes, skills,
spells, and abilities, but it's still not fully baked. I'd like to get this
mostly pinned down so that I can feel that the player progression mechanics are
mostly done, even if there is lots of content (classes, skills, etc.) left to
design.

## The current design

### Experience

Players earn experience for killing monsters. At some point, I might like for
them to earn experience for non-lethal actions too in order to support more
rogue-ish non-killing play styles, but maybe not.

### Stats and race

Players can spend experience to raise stats. Hero race scales the costs to raise
different stats.

### Skills and class

Players can spend experience to level up skills. Skills can provide passive
effects, or unlock abilities the hero can perform.

Currently, any given skill can only provide one ability and it's unlocked at
level one. That could be expanded to allow unlocking multiple abilities at
different levels.

Hero class determines the maximum level of each skill that can be attained.
Items that boost skill levels apply after this cap. In other words, an item can
boost a skill past the cap, including letting you learn a skill you otherwise
couldn't learn at all.

The experience cost to learn or level a skill is unaffected by class.

It's possible for some skills to be used at least somewhat across multiple
classes. It's unlike Diablo where each class basically defines it's own
completely separate set of progression skills.

### Abilities

Abilities are unique actions the hero can perform unlocked by learning a skill.
Things like firing arrows, axe sweep, etc.

### Spells

Spells are a special kind of ability. Each spell has "spell level" which
determines how difficult it is to learn. In order to use the spell, your level
in the skill (a spell school) associated with the spell must be at that level
or higher.

In addition, intellect determines the total number of spells you can learn, and
spells must be deliberately learned before they can be used.

So it's sort of like spells are abilities you unlock at different skill levels,
but there is also a separate action the player performs to choose which spells
to unlock because there are a finite number of slots for them.

## Race and class

I like the pairings of race with stats and class with skills. There's a nice
harmony to that. It does suggest that the two pairings should have all of the
properties of the other.

Currently, race scales stat cost but doesn't cap it. Class caps skill level but
doesn't scale the cost.

I suspect it would be better if race and class both scaled and capped stats and
skills, respectively. It feels kind of weird that you can have a fairy with 40
strength just by grinding really hard. Likewise, it feels weird that a non-mage
class with any access to some spell school can level it up as easy as a mage
can.

I'm not sure about this, though, and it's not the most pressing issue.

## Classes and skills

This is somewhat deliberate, but the set of classes is totally unbaked. It's
reasonable to want to get the core mechanics right before adding a bunch of
classes and skills which are sort of "content".

At the same time, it's really hard to design good mechanics without knowing
concretely how they will be used.

I don't have a good sense of whether the game should have a small set of
generic classes that the player customizes through development, or a larger set
of classes each with a specific flavor. Should there be a "mage" class, or only
"druid", "sorcerer", etc.?

## Creation versus development

Parts of the hero are defined at character creation time and can't change. Other
parts are chosen incrementally while playing. Some games lean more towards the
former where you spent a lot of time crafting a character and are pretty
committed to it before you start playing. Then playing is growing that character
but not fundamentally changing it. Other games lean the other way where a new
hero is sort of an unformed blob and you make choices during gameplay that
incrementally define who the hero is.

D&D leans pretty heavily on the former. Skills-based games like Sangbang are
very much the latter. I think Brogue is the latter too.

Diablo is fairly rigid but has some flexibility. Your choice of class very
strongly influences the entire play experience, but you can choose one of a
couple of skill branches in there to specialize in.

I have gone back and forth over time, but I suspect the character development
mechanics will never feel solid until I make a firm choice and accept that I
can only make one game and it must pick one point on this continuum, even if
that point is somewhere in the middle.

## Not completely unformed

I know I don't want an entirely skills focused game with no classes at all. I
want there to be an explicit character creation step. I want players to spend a
little time making a hero and I want them to have some investment in it as soon
as they start.

I also like the idea of having some attributes being chosen at creation time and
fixed. This encourages multiple playthroughs because different choices at the
beginning will lead to different play experiences.

## Not completely rigid

At the same time, I don't want the character development experience to feel like
you pick one item from a menu and after that you're fully on rails. There are
two main reasons for that:

### Responding to the world

A too rigid character path doesn't give players the freedom to respond to game
experiences. Brogue is intentionally designed to do most character development
during gameplay because it lets you choose have to grow your character in
response to what the RNG gives you. Find an amazing sword early on? Guess you're
going to be a warrior. Find a wand instead? Maybe you should be a mage.

I think some amount of flexibility here is important. At the same time, I don't
want to go as far down that road as brogue because I want players to feel they
have more agency over who their character is. Brogue is about being resourceful
and overcoming whatever the RNG throws at you. I want Hauberk to be about
building the hero you want. With things like the crucible and the town, players
are less boxed in by random item drops.

### Combinatorial play styles

A more important aspect for me is that if most of a character's attributes are
fixed at creation time, that tends to lead towards a design where there is a
fixed list of play experiences that are basically authored by me and the player 
simply chooses one.

One of my #1 design goals above all else is that if I put N things in the game,
I want the player to get N! combinatorial gameplay experiences in return, at
least as much as possible. That's why, for example, the dungeon generator can
combine multiple dungeon styles in a single map. It's why the same skill can be
learned by different classes. It's why most classes can use most items.

If there is any strong design goal for this game, it's that.

It is still possible to attain that while having most of the character
attributes fixed at creation time. For example, every combination of race and
class can in theory provide a somewhat different play style. But in practice,
race and class combinations mostly aren't very interesting. (That's possibly
a design problem itself, but I'll think about that later.)

## Evocative hero labels

I think I want something in the middle. I want the player to pick enough
concrete attributes at creation time that they can form a clear picture of their
hero that feels evocative and lore-rich. Since there are no graphics, names and
labels become even more important, so picking a few really matters.

### Races and powers

This suggests to me a pretty long list of races, and maybe special race powers
beyond just stat effects. If all a race does is tweak stats, then for each
class, there's most likely one race that works best with the stats that class's
skills focus on. Having interesting race powers can make more varied race and
class combinations more interesting. Perhaps an orc sorceror doesn't have the
same intellect for spellcasting as an elf, but if orcs can never be confused
such that they can't cast spells, maybe it's worth it.

### Classes

This also suggests a fairly decent list of classes. There can be some basic ones
but even those should be somewhat concrete and evocative. No generic "priest".
What does that even mean given how different each deity is? More interesting
ones like hunter, conjurer, druid, etc.

I don't need to try to slot classes into some rigid hierarchy. Just make cool
classes.

## Skills

I like the idea that what classes do mechanically is mostly about determining
which skills the hero can access and at what power level. I like skills as the
unifying "stuff that gives the hero new capabilities" mechanic. (It might even
be possible to model race powers as skills, but I don't think those should go
through the whole leveling/experience system.)

I also like that the player chooses which skills to develop during gameplay. So
at a high level, the combination of classes chosen at creation time and skills
grown during gameplay is, I think, a good way to stake out a middle position.

The hard part is figuring out exactly how classes affect skill growth. Some
points in the design space I can stake out:

*   At least some skills should be usable by multiple classes. That gets back
    to aiming for combinatorial gameplay. If every skill is class-specific, then
    authoring a new skill only affects the gameplay experience of a single
    class. I want more overlap than that.

*   I'd like more skills overall than Diablo has. Since there are no graphics,
    adding skills is less effort. At the same time, I don't want a bunch of
    very similar skills, and I'd rather skills grow in power with the hero than
    be entirely replaced by more powerful versions as they develop.

*   End-game characters should diverge, not converge. I've mentioned this in
    other notes, but it's an important design goal. There should multiple very
    different end-game character build-outs that are all successful. A winning
    mage should not look like a winning warrior.

    In particular, there shouldn't be many skills that nearly every hero uses.
    While some amount of skill overlap across classes is good, I want to keep
    each class's play experience somewhat distinct too.

*   You can't have it all. No amount of grinding should let you max out every
    skill, or even every skill available to a class. Choosing to develop a skill
    should to some degree mean choosing to *not* develop others.

## Less spells more magical powers

The current design has a fairly rigid notion of "spellcasting". There are spell
school skills that grant access to spells which are things magic users do.
Heroes that aren't "magic users" feel weird if they do "spells".

I think that's too black and white. Diablo does a better job where you just have
things characters can do. Barbarian's "Roar" is certainly a magical thing, but
it's not, like, a *spell*. While it is nice to have things called "spells" in
the game because that's a strongly evocative term that helps players visualize,
I think it would be better to be more vague about skills and have more skills
that are not strictly "spells" but still magical effects.

When a druid changes into a wolf, that's not "casting a spell" with like a wand
and a spellbook. It's just a magical thing a druid does. When a paladin
beseeches their deity to smite an undead foe, that's not a spell, but it's
magic.

## Skill number and levels

Before thinking about organizing skills and allocating them to classes, I need
to have a sense of how many there are in the game.

*   Is it a relatively small number of skills where players spend a lot of time
    leveling each one up and where a single skill may provide multiple abilities
    at different levels?

*   Or is it a larger number of more atomic skills?

*   If the former, do we level skills at all?

A goal I know I have is that I want to avoid a hero "outgrowing" a skill or
spell completely. Even if you have other stronger spells, Magic Missile should
still be useful. That implies that at least spells grow in power.

I don't know if that means that they do so because players continue to level
the skill/spell, or because the skill/spell's power tracks some other property
like Intellect that is itself growing.

Some thoughts:

*   If there are a lot of fine-grained skills, then having to level all of them
    individually to make them grow in power could be really tedious. In
    particular, if mages have a lot of spells, it would be a chore to level them
    all.

*   I need some kind of mechanism where equipment like wands and staves can
    empower a number of related skills.

    *   One option for this is to tag skills the way that breeds are tagged.

*   For some skills, it's hard to define what it means to make them more
    powerful. You either do the thing or don't.

*   It's probably more fun to learn a new skill (even if it's mechanically just
    a stronger version of an existing skill) than just incrementally leveling
    up some existing skill.

*   If skills don't support levels directly, I can get similar results by having
    multiple skills like "Bloodlust I", "Bloodlust II", etc. That does suggest
    something like prequisites are important, though, to prevent you from
    getting "II" before "I".

*   Alternatively, if skills are leveled, I can accommodate skills where that
    doesn't make sense by giving them a level 1 cap.

*   If equipment can grant/level skills, I have to figure out how that interacts
    with prequisites.

## How skills are organized

So I guess the fundamental question here is which skills a hero can develop. In
particular:

*   Which skills can the hero learn?
*   What is the experience cost to learn them?
*   What is the maximum level of the skill?
*   Are there are any other prerequisites to learning the skill?

And then:

*   How does class affect those answers?
*   How does equipment affect them?

And a meta-question:

*   Is there a way to categorize or organize skills such that all of those
    questions don't have to be answered individually for every single skill?

## Idea 1: Arcana, arcana limits, and prerequisites

All skills are grouped into one of a number of "arcana" which are sort of
thematic groupings kind of like spell schools but not just for spells. Arcana
could be things like "martial arts", "necromancy", "nature", or a particular
deity.

Further, skills within an arcana are organized into a Diablo-like skill tree.
Before you can gain some skill, you must already have at least one level in its
prequisites.

Each class defines which arcana it can learn skills in, and for each one, the
total number of skills it can learn. The skill trees are deliberately designed
to have long prequisite chains so that for the strongest skills, only the
classes that emphasize that arcana have a high enough limit to reach them all.

### Idea 1a: Flat experience

To keep things somewhat simpler, class doesn't affect the experience cost to
learn/level a skill. So you need both enough experience to learn a skill and
a free slot in its arcana if it's a new skill.

### Idea 2a: Bought arcana slots

You spend experience to buy an arcana point. Each class determines the cost of
points for different arcana. Classes that specialize in some arcana buy it more
cheaply. Class also places a hard limit on the total arcana points you can ever
have.

Once you buy an arcana point, you can spend it to learn a new skill or level a
skill in that arcana.

### Idea 2: Monolithic skill graph

All skills are organized into one big prerequisite graph. You can learn a skill
if you have *any* of its prereqs, not all. In other words, there can be multiple
paths to unlocking a skill.

Each class gives you a couple of starter skills, which are entrypoints to that
graph. Since you can only reach skills that have a path from a starter skill,
classes and the shape of the graph then control which skills a class can never
attain.

Some skills might have a short path to one class's starter skill and a long path
to another. That reflects that you *can* get the skill with the latter class,
but not as easily.

Could go even further and say that the experience cost to learn a skill is
attached to an *edge* on the graph and not a node, so learning a skill can cost
more or less depending on how you reach it.

It looks like this is sort of how Path of Exile works:

https://www.pathofexile.com/passive-skill-tree

But note that many nodes on that tree are not really interesting "skills" but
just waypoints that have some effect and get you one step closer to a goal.
Many just have a small effect. They also aren't invidually leveled.

I definitely don't want something that huge and crazy.

Maybe I should just sit down and come up with a big list of skill and class
ideas and then start seeing how they hang together?
