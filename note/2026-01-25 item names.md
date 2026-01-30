I find especially as you get deeper and find better gear with affixes that item
names are cut off in the UI much more often than I would like.

For example, going fullscreen on my 16" laptop with a nice font size, the
inventory shows 34 characters of text after the item glyph. For a typical
weapon, 3 of those are taken up by the damage info on the right.

31 still sounds like a lot but "Poisonous Baselard of Slaying" is 29 and doesn't
fit unless I cut out the damage info. "2 Scrolls of Sidestepping" is 25
characters and is a basic item with no affixes.

I have a "Large Leather Shield of Protection from Acid". That's 44 characters.
In the equipment sidebar, it just shows up as "Large Leather Shield of Protec".
Even when you open the equipment panel to do something and it expands, that only
gives you "Large Leather Shield of Protection from ".

So maybe the inspector will help? No, even worse: "a Large Leather Shield of
Prot". In fact, I only know it's protection from acid from looking at the
resistances table. The only place I can see the full name is in the fullscreen
equipment about page.

And this is an item that only has one affix. It could potentially be a "High
Elved Large Leather Shield of Protection from Lightning". That's... a lot.

This will probably get worse as I add more affixes for skill boosts. Some ideas
to fix:

## Shorten base names

I pulled a lot of equipment names from Angband which seems to presume more UI
space for names. "Large Leather Shield" is just long. It's probably worth going
through and shortening some of those.

## Shorten affix names

The list of [Diablo II affixes][] are mostly pretty short. One of the longest I
can find is "Life Everlasting". Most are a single word. I think they strike a
good balance of at least suggesting what the affix does but not feeling like
they need to be completely self-explanatory to the point of verbosity. You can
guess that "Noxious" probably has something to do with poison, but it doesn't
completely clarify that it boosts poison and bone skills.

[diablo ii affixes]: https://diablo-archive.fandom.com/wiki/Affixes_(Diablo_II)

I like the idea of affix names that are a little more obscure. It makes them
more evocative. They read like lore and less like a tax form.

## More ad hoc affixes

There is one suffix to add resistance for each of the 11 elements. It's hard to
come up with short names for those that aren't just "of Resist (Element)". I
can try to come up with antonyms for each element, but, like, what's the
opposite of earth?

I know I have a tendency when authoring content to just mindlessly grind through
the lists and combinations. Maybe I should avoid that here. Instead of having
one affix for each element, just pick a few interesting combinations that have
good names. I already have some of those like "Resist Evil" and "Resist Nature".
So maybe lean in that direction harder.

## Limit affix combining

The longest names come from a single item with both a prefix and suffix. I
really like the combinatorial richness we get from allowing affixes to be
combined. But we could possibly limit combinations that yield particularly long
names.

I considered having this literally work by disallowing two affixes if the result
is above a certain character length. But that means renaming an affix would
affect its probability. That sounds like a tuning nightmare, so I'd like to
avoid this.

## Don't show stats in item lists

For weapons, item lists usually show their damage. Likewise armor amount for
armor items. That's useful info, but it takes up space. Now that we have the
inspector, it's not really necessary. Maybe that should only be shown on the
inspector and lore screens and not in item lists.

## Remove "Scroll of" and "Potion of"

Equipment item names really needs to show the base name because there are
multiple different pieces of equipment that share the same glyph. But we waste a
decent amount of character space on "scroll" and "potion" for those items and it
doesn't convey that much.

We could possibly not show that in the item list and just show what the scroll
or potion does. So just "Sidestepping".

I don't love this. I suspect it would make item lists harder to read. And, in
practice while potion and scroll names can be kind of long, they're rarely the
worst offenders since they don't support affixes.

As with affixes, though, it's worth thinking about using shorter but more
evocative names. "Salve of Lightning Resistance" is a lot. Perhaps simply
"Salve of Insulation". Likewise "Scroll of Sense Nearby Monsters" could be
"Scroll of Sense Threat".

## Avoid "Pairs of"

For gloves, footwear, pants, the name includes "Pair(s) of". That's useful if
you are carrying a stack: "3 Pairs of Boots". But it doesn't really add anything
in the very common case where you just have one. "Boots" and "Pair of Boots" are
about equally clear and the former is much shorter.

The game already supports custom pluralization, so I think I can tweak it such
that a single item is "Boots" and a stack is "2 Pairs of Boots". Actually, now
that I look at the items, none of the items that are paired even support
stacking.

## Make the expanded item list width larger

There's the size of an item list when it's just sitting in the sidebar when
you play the game. Then when you go to perform an action that needs you to
select an item, the list expands some. The expanded width is hardcoded.

I'm not sure where that number came from. I think it was to minimize overlap
when you're on a town screen and there are two item lists next to each other?
Even so, I could probably widen that without causing too much trouble. I just
have to check how it looks when you're at the minimum screen size.

The shop and hero item lists *do* overlap when the screen is small, so that
preferred size isn't completely eliminating overlap anyway. So this seems like
an easy tweak.

Perhaps the best UI here is where the width scales to fit the length of the
items. That way we cover as little of the game screen as possible while still
trying to show the items fully.

I tried bumping it up to 64 and it definitely helps show more of the item. But
it also covers a lot of the game screen with mostly empty space which is a
little annoying when you're trying to quickly pick an item to use without
breaking your flow.

### Inspector

Oh, right. I think part of the limitation here is making sure there is still
room next to the item list to show the inspector. If I make the item list 64
characters wide, then the inspector creeps off the edge of the screen when the
game is at its smallest size.

(Also, the inspector could really stand to be wider too.)

In practice, though, I think players will usually have a bigger screen size.
That suggests that the item list should grow to fit the items but stay limited
by the screen size.

For shop item lists, the UI already supports moving the inspector under the
item list if there isn't room on the right. We could use that same capability
for hero item lists too if there isn't room on the left. That would also
probably imply always showing the item list at the top of the screen and not
under the log like it currently does. Otherwise there isn't reliably enough
room below the inventory list either.

(Having a smaller maximum inventory size would help here too.)

## Summary

OK, I think I want to in the data:

* Shorten base item names and possibly ditch a few base items entirely.
* Shorten affix names and make them more evocative but less explanatory.
* Likewise shorten some magic item names.
* Remove weapon and armor stats from item lists.
* Maybe eliminate some of the single-element affixes and have fewer of them but
  with more interesting combinations and cool short names.
* Don't show "Pair of" if it's a single item.

And in the UI:

* Make item lists more adaptable to item name length and screen size.
* Make the inspector wider and have the UI show it under the item list if
  needed to not go off screen.

I don't want to restrict affix combinations based on name length.
