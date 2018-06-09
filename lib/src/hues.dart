import 'package:malison/malison.dart';

import 'engine.dart';
// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import 'content/elements.dart';

// Basic palette.
// TODO: Better name.
const nearBlack = const Color(0x07, 0x06, 0x12);
// TODO: These names aren't great.
const midnight = const Color(0x13, 0x11, 0x1c);
const steelGray = const Color(0x26, 0x26, 0x38);
const slate = const Color(0x3f, 0x40, 0x72);
const gunsmoke = const Color(0x84, 0x7e, 0x87);
const gunsmokeDimmed = const Color(0x52, 0x4f, 0x54);
const ash = const Color(0xe2, 0xdf, 0xf0);

const sandal = const Color(0xbd, 0x90, 0x6c);
const persimmon = const Color(142, 82, 55);
const copper = const Color(0x7a, 0x2c, 0x18);
const garnet = const Color(64, 31, 36);

const buttermilk = const Color(0xff, 0xee, 0xa8);
const gold = const Color(0xde, 0x9c, 0x21);
const goldDimmed = const Color(0x89, 0x60, 0x14);
const carrot = const Color(0xb3, 0x4a, 0x04);

const lima = const Color(0x83, 0x9e, 0x0d); //0x84, 0xb8, 0x23);
const mustard = const Color(0x63, 0x57, 0x07);

const mint = const Color(0x81, 0xd9, 0x75);
const peaGreen = const Color(0x16, 0x75, 0x26);
const peaGreenDimmed = const Color(0x19, 0x86, 0x2b);
const sherwood = const Color(0x00, 0x40, 0x27);

const seaGreen = const Color(0x09, 0x5f, 0x70);

const turquoise = const Color(0x81, 0xe7, 0xeb);
const cornflower = const Color(0x40, 0xa3, 0xe5);
const cerulean = const Color(0x15, 0x57, 0xc2);
const ultramarine = const Color(0x1a, 0x2e, 0x96);

const lilac = const Color(0xbd, 0x6a, 0xeb);
const violet = const Color(0x56, 0x1e, 0x8a);
const violetDimmed = const Color(0x56, 0x1e, 0x8a);
const indigo = const Color(0x38, 0x10, 0x7d);

const salmon = const Color(0xff, 0x7a, 0x69);
const brickRed = const Color(0xcc, 0x23, 0x39);
const brickRedDimmed = const Color(0x89, 0x18, 0x26);
const maroon = const Color(0x54, 0x00, 0x27);

class UIHue {
  static const text = gunsmoke;
  static const helpText = steelGray;
  static const selection = gold;
  static const disabled = steelGray;
  static const primary = ash;
  static const secondary = steelGray;
}

Color elementColor(Element element) {
  return {
    Element.none: gunsmoke,
    Elements.air: Color.lightAqua,
    Elements.earth: persimmon,
    Elements.fire: Color.red,
    Elements.water: Color.blue,
    Elements.acid: Color.lightGreen,
    Elements.cold: Color.lightBlue,
    Elements.lightning: Color.lightPurple,
    Elements.poison: Color.green,
    Elements.dark: Color.gray,
    Elements.light: Color.lightYellow,
    Elements.spirit: Color.purple
  }[element];
}
