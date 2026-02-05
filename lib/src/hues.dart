import 'package:malison/malison.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import 'content/elements.dart';
import 'engine.dart';

const lighterCoolGray = Color(0xd0, 0xc3, 0xd6);
const lightCoolGray = Color(0x7d, 0x90, 0xb3);
const coolGray = Color(0x48, 0x52, 0x73);
const darkCoolGray = Color(0x29, 0x2d, 0x42);
const darkerCoolGray = Color(0x14, 0x13, 0x1f);

const lighterWarmGray = Color(0xc1, 0xb5, 0xc7);
const lightWarmGray = Color(0x7d, 0x77, 0x80);
const warmGray = Color(0x48, 0x40, 0x4a);
const darkWarmGray = Color(0x2a, 0x24, 0x2b);
const darkerWarmGray = Color(0x16, 0x11, 0x17);

const sandal = Color(0xbd, 0x90, 0x6c);
const tan = Color(0x8e, 0x52, 0x37);
const brown = Color(0x4d, 0x1d, 0x15);
const darkBrown = Color(0x24, 0x0a, 0x05);

const gold = Color(0xde, 0x9c, 0x21);
const carrot = Color(0xb3, 0x4a, 0x04);
const persimmon = Color(0x6e, 0x20, 0x0d);

const buttermilk = Color(0xff, 0xee, 0xa8);
const yellow = Color(0xe8, 0xc8, 0x15);
const olive = Color(0x63, 0x57, 0x07);
const darkOlive = Color(0x33, 0x30, 0x1c);

const mint = Color(0x81, 0xd9, 0x75);
const lima = Color(0x83, 0x9e, 0x0d);
const peaGreen = Color(0x16, 0x75, 0x26);
const sherwood = Color(0x00, 0x40, 0x27);

const lightAqua = Color(0x81, 0xe7, 0xeb);
const aqua = Color(0x0f, 0x82, 0x94);
const darkAqua = Color(0x06, 0x31, 0x4f);

const lightBlue = Color(0x40, 0xa3, 0xe5);
const blue = Color(0x15, 0x57, 0xc2);
const darkBlue = Color(0x1a, 0x2e, 0x96);

const lavender = Color(0xc9, 0xa6, 0xff);
const lilac = Color(0xad, 0x58, 0xdb);
const purple = Color(0x56, 0x1e, 0x8a);
const violet = Color(0x38, 0x10, 0x7d);

const pink = Color(0xff, 0x7a, 0x69);
const red = Color(0xcc, 0x23, 0x39);
const maroon = Color(0x54, 0x00, 0x27);

class HueSet {
  static const List<Color> dazzle = [
    darkCoolGray,
    coolGray,
    lightCoolGray,
    lighterCoolGray,
    sandal,
    tan,
    persimmon,
    brown,
    buttermilk,
    gold,
    carrot,
    mint,
    olive,
    lima,
    peaGreen,
    sherwood,
    pink,
    red,
    maroon,
    lilac,
    purple,
    violet,
    lightAqua,
    lightBlue,
    blue,
    darkBlue,
  ];

  static const List<(Color, Color)> fire = [
    (gold, persimmon),
    (buttermilk, carrot),
    (tan, red),
    (red, brown),
  ];
}

class UIHue {
  // Colors for text and items the user may interact with:

  /// Text for a currently selected thing in a list, key commands, or other
  /// UI that indicates active user focus.
  static const highlight = gold;

  /// Text that can be selected but isn't currently.
  static const selectable = lighterWarmGray;

  /// Text or UI that the user can't currently interact with but sometimes can.
  static const disabled = warmGray;

  /// Text or UI showing a place where something could be but isn't, like an
  /// empty equipment slot. This is "more disabled" than [disabled].
  static const absent = darkerCoolGray;

  // Other non-interactive text:

  /// Informative text that the user doesn't directly interact with is useful
  /// content to be read.
  static const text = lightWarmGray;

  /// Label string describing some other piece of UI or information.
  static const label = warmGray;

  /// Column header on a table or text describing a section of the UI.
  static const header = coolGray;

  /// Text that doesn't really matter but helps organize the UI.
  static const subtext = darkCoolGray;

  // Colors for lines and other non-text UI.

  /// Linework that may overlay and need to appear in front of other lines.
  static const overlayLine = coolGray;

  /// Lines that frame panels, tables, etc.
  static const line = darkCoolGray;

  /// A very faint line separating table rows.
  static const rowSeparator = darkerCoolGray;

  // TODO: Migrate everything off this.
  static const secondary = pink; // darkCoolGray;
}

Color elementColor(Element element) {
  return {
    Element.none: lightCoolGray,
    Elements.air: lightAqua,
    Elements.earth: tan,
    Elements.fire: red,
    Elements.water: darkBlue,
    Elements.acid: lima,
    Elements.cold: lightBlue,
    Elements.lightning: lilac,
    Elements.poison: peaGreen,
    Elements.dark: darkCoolGray,
    Elements.light: buttermilk,
    Elements.spirit: purple,
  }[element]!;
}
