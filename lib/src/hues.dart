import 'package:malison/malison.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import 'content/elements.dart';
import 'engine.dart';

const ash = Color(0xe2, 0xdf, 0xf0);
const lightCoolGray = Color(0x74, 0x92, 0xb5);
const coolGray = Color(0x3f, 0x4b, 0x73);
const darkCoolGray = Color(0x26, 0x2a, 0x42);
const darkerCoolGray = Color(0x14, 0x13, 0x1f);

const lightWarmGray = Color(0x84, 0x7e, 0x87);
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

class UIHue {
  // TODO: These aren't very meaningful and are sort of randomly applied. Redo.
  static const text = lightWarmGray;
  static const helpText = lightWarmGray;
  static const selection = gold;
  static const disabled = darkCoolGray;
  static const primary = ash;
  static const secondary = darkCoolGray;
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
    Elements.spirit: purple
  }[element];
}
