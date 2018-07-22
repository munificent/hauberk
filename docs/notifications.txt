I'm trying to think through a system to manage notifications derived from state
changes that may in turn be derived from a number of factors. For example, we
want to tell the player when the hero gains the ability to cast a new spell.
But that can happen because they equipped a helm whose intellect bonus kicks
the hero above the threshold.

Tracking all of that manually has been difficult and error-prone, so it may be
time for something more systematic. Here's some of the messages I can think of
so far:

When heft scale crosses the 1.0 threshold:
  "You are able to wield it effectively."
  "The weapon is too heavy for you to wield it effectively."
  "You are too weighed down by your armor to wield your weapon effectively."

When stat changes:
  "You feel smarter. Your intellect is ___."
  "You feel stronger. Your strength is ___."
  ...
  "You feel stupider. Your intellect is ___."
  "You feel weaker. Your strength is ___."
  ...

When level changes:
  "You have reached level ___."
  "You feel your life draining away!"

Find spellbook or change intellect:
  "You have learned the spell ___."
  "You are not wise enough to cast ___."
  "You forgot how to cast ___."

Find weapon:
  "You can begin training in ___."

See breed:
  "You are eager to learn to slay ___."

This is the primary data that comes into play and isn't derived from anything
else:

- Race
- Experience points
- Current equipment
- Lore: seen and slain
- Picked up items that expose skills

From those, we can derive:

- Level
- Stats (strength, intellect, etc.)
- Weight
- Encumbrance
- Skill levels
- Which skills are usable

I was initially thinking of some kind of observer pattern dependency graph
thing, but that set is small enough that maybe we can just refresh everything.
At that point, all we really need is a cache of the previous value so we can
tell when it changed.
