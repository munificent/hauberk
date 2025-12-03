I think I'm making progress, but some stuff still doesn't quite hold together.

## Slays and experience curves

I had an idea that the more of a type of monster you kill, the less experience
you should get. That should help avoid players grinding and farming to fully
max out their hero. Further, I thought I could tie that idea to slay skills. So
the higher level slaying you have for a kind of monster, the less experience you
get for it.

That is a nice-sounding mechanic. But for it to work, every monster needs to be
covered by exactly one slay skill type. That's not currently true for the slay
skills, and I don't expect it to be true going forward.

*   Some types of monsters feel pretty weird to have a dedicated slaying skill
    for them. In particular, humanoids. Feels kind of strange to have a heroic
    player really good at "slay humans" or even "slay elves".

*   Some appealing slaying skills overlap multiple types. "Slay Dragon", "Slay
    Evil", and "Slay Undead" all sound pretty valuable. But how much experience
    do you then get from killing an evil undead dragon? As far as the skills go,
    I'd want to combine them so you get the benefits of all. But for experience,
    it would I guess be the intersection or something?

Overall, it feels like tying these two mechanics together doesn't quite fit. If
I want to have experience decay, it probably makes more sense to track that on
a per-breed basis. We do already track the kills for each breed in the hero
lore, so that's definitely doable.

## Spell books and non-goal spells

I don't know if this is really a problem, but just a wrinkle in the mechanic.
I had an idea that spells are grouped by spellbook. Each spellbook is a separate
class power. Each time you level up a book, you learn the next spell in it.

Now imagine you get a spell book that has spells A, B, C, and D, in that order.
You really want D, but don't care about B and C. You're forced to level through
them anyway in order to reach D.

I think this is probably OK. It may feel kind of annoying but hopefully in a
"this is the way the world works, so fine" way.
