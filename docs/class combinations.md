One way to think about building out a set of classes is by using combinations of
the four primary color classes: mage, priest, rogue, and warrior.

We could create a set of dual-classes that have a pair of those, one which is
primary and one which is secondary. Every possible pair gives us something like:

- mage/priest - witch
- mage/rogue - alchemist
- mage/warrior - warlock
- priest/mage - druid
- priest/rogue - mystic
- priest/warrior - monk
- rogue/mage - illusionist
- rogue/priest - occultist
- rogue/warrior - assassin
- warrior/mage - ranger
- warrior/priest - paladin
- warrior/rogue - mercenary

I'm not thrilled with all of those, but most sound kind of cool. Another option
is to treat the four classes as bits and do all 2^4 combinations:

- (none) - fool
- mage - mage
- priest - priest
- rogue - rogue
- warrior - warrior
- mage-priest - druid, sage, witch
- mage-rogue - alchemist, trickster, illusionist, magician
- mage-warrior - warlock, ranger
- priest-rogue - mystic, occultist
- priest-warrior - paladin
- rogue-warrior - mercenary, assassin
- mage-priest-rogue - bard
- priest-rogue-warrior - barbarian
- mage-priest-warrior - knight?
- mage-rogue-warrior - ranger
- mage-priest-rogue-warrior - adventurer

Some of the threes are a real stretch, but it works out a little better than I
expected. It might be worth considering, though I need to think about how it
interacts with the "titles" stuff I was thinking about too.
