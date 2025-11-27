The design in the previous note doesn't quite hold together.

## Problems

### Warrior powers

Right now, warriors have a lot of pretty specific disciplines. There is a slay
for more types of monsters, and a mastery for each kind of weapon, plus a few
others.

That works because they all train automatically in parallel. In fact, they can
double dip. If a warrior kills an orc with a axe, they'll train both axe
mastery and slay orc with the same kill.

But if they have to spend experience on each of those, then it's zero-sum and
they have to make trade-offs. That means those powers need to either be really
cheap so they can train a bunch of them, or I need to winnow down the power
list a lot.

Part of what makes warriors enjoyable to play right now is the way that
disciplines feel like free rewards.

### Mage powers

Meanwhile, the plan in this doc is that there is a single power for each spell
school. If you are a specialist mage subclass, that means you have literally
only one power to spend experience on.

This feels backwards where now warriors are fiddly and require micromanaging
when spending experience but magic users don't. (But magic users are more fiddly
when playing and selecting spells.)

I have a few ideas that might help.

## Slay disciplines

The mechanic for disciplines where they automatically train is actually kind of
fun and would nice to keep around. It also feels like something that all classes
can experience at least a little of.

So let's say we make monster slays not be a warrior class power. Instead, they
are their own separate mechanic that applies to all classes. Each slay type is
trained automatically by killing monsters of that type.

When making experience a currency, one worry I have is that without an
experience level cap, they can just grind indefinitely to max everything out.
An idea I had to address that is to have killing monsters provide diminishing
returns. We can marry that mechanic to slays. We you level up slaying a monster
kind, it also reduces how much experience you get for killing those kinds of
monsters. This helps taper off experience over time. It also makes sense: the
more slay levels you have the easier those monsters are to kill.

## Warrior masteries

Then most of a warriors powers are weapon masteries and there aren't an
overwhelming number of them. That feels about right to me.

There can be a few other warrior skills too, but they'll probably put most
points into stats and a mastery.

I do think all players should be able to use bows without needing an achery
power.

## Mage spellbooks

For mages, the way we avoid them only having a single power to pour levels into
is by breaking spells down into spell books, not spell schools. Each spell book
has, I don't know, maybe half a dozen spells. So even within a given theme of
spells, there can be a few different books that the player has to level up.

Each level in a spell book grants you access to the next spell in the book. Once
you know them all, you've maxed out the power's level.

## Power level caps

As noted in the previous section, powers can have a maximum level. We can share
some powers across classes while still making the classes different by giving
each different level caps. Maybe rogues can learn some dagger mastery, but not
as good as a warrior can. (We can also do this by tuning the experience cost,
but I suspect that a hard cap makes for a clearer mechanic.)

## Subclasses

Level caps play into another idea. We could introduce subclasses as a choice
the player can make part way through character progression. You can pick one
subclass of the hero's main class. Once you've picked it, that's the only one
you can pick and you're stuck with it.

What a subclass does is raise the level cap on some powers or possibly grant
access to other powers.

So, for example, a mage might specialize in one spell school by choosing a
subclass. That gives them access to either the strongest spells in a couple of
books (by raising the level cap) or possibly giving them access to a book they
otherwise can't level at all.

For warriors, a subclass like archer raises the level cap for that mastery.

### Do you have to pick a subclass?

I'm not sure if the mechanics should be set up that players *always* pick a
subclass at some point during development, or whether they can choose to finish
the game just as a main generalist class.

I lean towards the latter. That implies that subclasses shouldn't just be a pure
positive that adds levels and powers without cost. It should be a trade-off so
that remaining a generalist still has value. Ways that could work:

*   Maybe picking a subclass *lowers* the caps on some other powers. So you can
    go further in some directions but not as far in others.

*   Maybe choosing a subclass itself requires spending a significant amount of
    experience.

*   Perhaps subclasses have other play style restrictions like you can't use
    certain equipment or items, kind of like how clerics in D&D can't use
    blades.
