There are currently 76 calls to `padLeft()`, 7 calls to `padRight()`, 185 calls
to `toString()`, 35 calls to `toStringAsFixed()`, and 15 calls to
`formatNumber()` in Hauberk. I've been thinking for a long time that a cleaner
API for formatting objects and numbers to strings would simplify a lot of that
code.

I'd also like some kind of syntax for doing terminal printing where strings can
contain escape sequences to change color. But I'm going to consider that a
separate feature from this note.

This is just about converting objects to nice strings. Here are the features I
need to support:

- Output width. If the resulting string is less than this width, then padding
  is added.
- Whether that padding is added on the left or right.
- What to pad with. I think I only ever use " " or sometimes "0" for leading
  zeroes.
- The number of digits after the decimal point if it's a floating point number.
- Whether or not to show the number as a percentage (i.e. multiply by it 100 and
  append '%').
- Whether to separate groups of digits with `,`.

I don't currently seem to do hex output anywhere, but I could see that being
useful.

## Python

Here's [Python's mini-grammar](
https://docs.python.org/3/library/string.html#formatspec):

```
format_spec:             [options][width_and_precision][type]
options:                 [[fill]align][sign]["z"]["#"]["0"]
fill:                    <any character>
align:                   "<" | ">" | "=" | "^"
sign:                    "+" | "-" | " "
width_and_precision:     [width_with_grouping][precision_with_grouping]
width_with_grouping:     [width][grouping]
precision_with_grouping: "." [precision][grouping] | "." grouping
width:                   digit+
precision:               digit+
grouping:                "," | "_"
type:                    "b" | "c" | "d" | "e" | "E" | "f" | "F" | "g"
                         | "G" | "n" | "o" | "s" | "x" | "X" | "%"
```

Alignment (padding direction) is specified using `<` for left-alignment (right
padding) and `>` for right-alignment (left padding). If omitted, defaults to
left alignment for most objects and right alignment for numbers. There is also
`^` to center.

If alignment is specified, then it can be preceded by a character that is the
padding character.

A `0` character before the width number causes numbers to be padded to the width
using leading `0` characters and takes into account a leading sign. (In other
words, it does `-000123` and not `000-123` which is what you'd get if you just
left pad with `0`. This can only be used if you don't specify alignment
explicitly.

Then there is the width, specified as a number. After the width can be `,` or
`_` to group digits. Then an optional `.` followed by another number to specify
how many decimal digits to show.

Finally, there is an optional type character. The only type I currently care
about is `%` for percent.

Some examples:

```
?<10 # Left align to 10 characters, pad on right with "?".
8    # Align to 8 characters.
6.2  # Six characters of total width, two digits after decimal point.
```

I think a subset of Python syntax seems reasonable.

## Zero padding

Actually, there are only two debug scripts that use zero padding and those uses
are kind of hacky. I think I don't need to support that at all.

## Rethink

I got this working, but I'm having second thoughts. It's effectively a funny
little dynamically typed API jammed in the middle of an otherwise pretty tightly
typed codebase. The brevity is nice, but it feels like a step backwards
otherwise. If I can make it terse enough, I'd rather a more explicitly typed
API.

To design that, first I gathered stats on which combinations of formatting
options are most common by defining a separate method for each, migrating
everything to that, and counting calls. The results:

```
fmtIntWidth               44
fmtIntCommas               6
fmtIntWidthCommas         10
fmtObjWidth                8
fmtNumWidth                0
fmtNumDigits              13
fmtNumDigitsPercent        4
fmtNumWidthDigits         14
fmtNumWidthDigitsPercent   2
padLeft                   10
```

Factoring out the different options and adding up totals:

```
on int   60
on num   33
on Obj   18 (includes String.padLeft)
width    88
commas   16
percent   6
```

For ints and num, every call that pads aligns to the right. There aren't any
that left align. For other types (`fmtObjWidth()` and `String.padLeft()`), it's
an even mix of left and right alignment.

Most of the `fmtIntWidth()` calls could likely reasonably be
`fmtIntWidthCommas()` instead. It's just that they happen to be for numbers
where they never get large enough to need the commas anyway. I don't know of
cases where I would *not* want commas to appear.

### Phased API

Looking at the implementation of `fmt()`, formatting happens in two steps:

1.  Convert the value to a string. This is where precision, commas, and percent
    are applied.

2.  Apply padding for the width and alignment.

These could be separate operations which are chained if that cuts down on the
number of combinations needed. Something like:

```
.fmtIntWidth               -> .fmt().lpad(width)
.fmtIntCommas              -> .fmt()
.fmtIntWidthCommas         -> .fmt().lpad(width)
.fmtObjWidth               -> .fmt().rpad(width)
.fmtNumWidth               -> .fmt().lpad(width)
.fmtNumDigits              -> .fmt(d: digits).lpad(width)
.fmtNumDigitsPercent       -> .fmt(d: digits, percent: true)
.fmtNumWidthDigits         -> .fmt(d: digits).lpad(width)
.fmtNumWidthDigitsPercent  -> .fmt(d: digits, percent: true).lpad(width)
.padLeft                   -> .lpad(width)
```

I don't love it.

### Named arguments

Maybe one method with named arguments for all the options:

```
.fmtIntWidth               -> .fmt(w: width)
.fmtIntCommas              -> .fmt()
.fmtIntWidthCommas         -> .fmt(w: width)
.fmtObjWidth               -> .fmt(w: width)
.fmtNumWidth               -> .fmt(w: width)
.fmtNumDigits              -> .fmt(w: width, d: digits)
.fmtNumDigitsPercent       -> .fmt(d: digits, percent: true)
.fmtNumWidthDigits         -> .fmt(w: width, d: digits)
.fmtNumWidthDigitsPercent  -> .fmt(w: width, d: digits, percent: true)
.padLeft                   -> .fmt(w: width)
```

Using the type to infer the padding direction feels a little spooky, but it
does actually do the right thing for all of my existing calls. "percent: true"
is too long. So maybe do separate operations for that:

```
.fmtIntWidth               -> .fmt(w: width)
.fmtIntCommas              -> .fmt()
.fmtIntWidthCommas         -> .fmt(w: width)
.fmtObjWidth               -> .fmt(w: width)
.fmtNumWidth               -> .fmt(w: width)
.fmtNumDigits              -> .fmt(w: width, d: digits)
.fmtNumDigitsPercent       -> .fmtPercent(d: digits)
.fmtNumWidthDigits         -> .fmt(w: width, d: digits)
.fmtNumWidthDigitsPercent  -> .fmtPercent(w: width, d: digits)
.padLeft                   -> .fmt(w: width)
```

It's simple. Seems to cover my needs. I'll go with it.
