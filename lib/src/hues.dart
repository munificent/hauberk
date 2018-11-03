import 'package:malison/malison.dart';

import 'engine.dart';
// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import 'content/elements.dart';

// Basic palette.
// TODO: These names aren't great.
const midnight = Color(0x13, 0x11, 0x1c);
const steelGray = Color(0x26, 0x26, 0x38);
const slate = Color(0x3f, 0x40, 0x72);
const gunsmoke = Color(0x84, 0x7e, 0x87);
const ash = Color(0xe2, 0xdf, 0xf0);

const sandal = Color(0xbd, 0x90, 0x6c);
const persimmon = Color(142, 82, 55);
const copper = Color(0x7a, 0x2c, 0x18);
const garnet = Color(64, 31, 36);

const buttermilk = Color(0xff, 0xee, 0xa8);
const gold = Color(0xde, 0x9c, 0x21);
const carrot = Color(0xb3, 0x4a, 0x04);

const lima = Color(0x83, 0x9e, 0x0d); //0x84, 0xb8, 0x23);
const mustard = Color(0x63, 0x57, 0x07);

const mint = Color(0x81, 0xd9, 0x75);
const peaGreen = Color(0x16, 0x75, 0x26);
const sherwood = Color(0x00, 0x40, 0x27);

const seaGreen = Color(0x09, 0x5f, 0x70);

const turquoise = Color(0x81, 0xe7, 0xeb);
const cornflower = Color(0x40, 0xa3, 0xe5);
const cerulean = Color(0x15, 0x57, 0xc2);
const ultramarine = Color(0x1a, 0x2e, 0x96);

const lilac = Color(0xbd, 0x6a, 0xeb);
const violet = Color(0x56, 0x1e, 0x8a);
const indigo = Color(0x38, 0x10, 0x7d);

const salmon = Color(0xff, 0x7a, 0x69);
const brickRed = Color(0xcc, 0x23, 0x39);
const maroon = Color(0x54, 0x00, 0x27);

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
    Elements.air: turquoise,
    Elements.earth: persimmon,
    Elements.fire: brickRed,
    Elements.water: ultramarine,
    Elements.acid: lima,
    Elements.cold: cornflower,
    Elements.lightning: lilac,
    Elements.poison: peaGreen,
    Elements.dark: steelGray,
    Elements.light: buttermilk,
    Elements.spirit: violet
  }[element];
}
