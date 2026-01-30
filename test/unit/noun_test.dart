import 'package:hauberk/src/engine/core/thing.dart';
import 'package:test/test.dart';

void main() {
  const prefixes = ["hot", "spicy"];
  const suffixes = ["of cold", "'Fred'"];

  var sword = NounBuilder("sword");
  var axe = NounBuilder("axe");
  var unicycle = NounBuilder("a unicycle");
  var homage = NounBuilder("an homage");
  var stilleto = NounBuilder("stilleto[es]");
  var staff = NounBuilder("sta[ff|ves]");
  var sting = NounBuilder("Sting", category: NounCategory.proper);
  var phial = NounBuilder("Phial", category: NounCategory.definite);
  var pants = NounBuilder("(pair[s] of )pants");
  var something = NounBuilder.something;

  group('short', () {
    testShort(
      String description,
      NounBuilder builder, {
      required String single,
      required String singleAffixed,
      required String plural,
      required String pluralAffixed,
    }) {
      test(description, () {
        expect(builder.build(1).short, single);
        expect(
          builder.build(1, prefixes: prefixes, suffixes: suffixes).short,
          singleAffixed,
        );
        expect(builder.build(3).short, plural);
        expect(
          builder.build(3, prefixes: prefixes, suffixes: suffixes).short,
          pluralAffixed,
        );
      });
    }

    testShort(
      "simple noun",
      sword,
      single: "sword",
      singleAffixed: "hot spicy sword of cold 'Fred'",
      plural: "3 swords",
      pluralAffixed: "3 hot spicy swords of cold 'Fred'",
    );

    testShort(
      "noun that starts with a vowel and gets \"an\"",
      axe,
      single: "axe",
      singleAffixed: "hot spicy axe of cold 'Fred'",
      plural: "3 axes",
      pluralAffixed: "3 hot spicy axes of cold 'Fred'",
    );

    testShort(
      "noun that starts with a vowel and gets \"a\"",
      unicycle,
      single: "unicycle",
      singleAffixed: "hot spicy unicycle of cold 'Fred'",
      plural: "3 unicycles",
      pluralAffixed: "3 hot spicy unicycles of cold 'Fred'",
    );

    testShort(
      "noun that starts with a consonant and gets \"an\"",
      homage,
      single: "homage",
      singleAffixed: "hot spicy homage of cold 'Fred'",
      plural: "3 homages",
      pluralAffixed: "3 hot spicy homages of cold 'Fred'",
    );

    testShort(
      "irregular plural",
      stilleto,
      single: "stilleto",
      singleAffixed: "hot spicy stilleto of cold 'Fred'",
      plural: "3 stilletoes",
      pluralAffixed: "3 hot spicy stilletoes of cold 'Fred'",
    );

    testShort(
      "irregular plural",
      staff,
      single: "staff",
      singleAffixed: "hot spicy staff of cold 'Fred'",
      plural: "3 staves",
      pluralAffixed: "3 hot spicy staves of cold 'Fred'",
    );

    testShort(
      "named proper noun",
      sting,
      single: "Sting",
      singleAffixed: "hot spicy Sting of cold 'Fred'",
      plural: "3 Stings",
      pluralAffixed: "3 hot spicy Stings of cold 'Fred'",
    );

    testShort(
      "titled proper noun",
      phial,
      single: "Phial",
      singleAffixed: "hot spicy Phial of cold 'Fred'",
      plural: "3 Phials",
      pluralAffixed: "3 hot spicy Phials of cold 'Fred'",
    );

    testShort(
      "paired noun",
      pants,
      single: "pants",
      singleAffixed: "hot spicy pants of cold 'Fred'",
      plural: "3 pairs of pants",
      pluralAffixed: "3 pairs of hot spicy pants of cold 'Fred'",
    );

    testShort(
      "mass noun",
      something,
      single: "something",
      singleAffixed: "hot spicy something of cold 'Fred'",
      plural: "3 somethings",
      pluralAffixed: "3 hot spicy somethings of cold 'Fred'",
    );
  });

  group('indefinite', () {
    testIndefinite(
      String description,
      NounBuilder template, {
      required String singular,
      required String singularAffixed,
      required String plural,
      required String pluralAffixed,
    }) {
      test(description, () {
        expect(template.build(1).indefinite, singular);

        expect(
          template.build(1, prefixes: prefixes, suffixes: suffixes).indefinite,
          singularAffixed,
        );

        expect(template.build(3).indefinite, plural);

        expect(
          template.build(3, prefixes: prefixes, suffixes: suffixes).indefinite,
          pluralAffixed,
        );
      });
    }

    testIndefinite(
      "simple noun",
      sword,
      singular: "a sword",
      singularAffixed: "a hot spicy sword of cold 'Fred'",
      plural: "3 swords",
      pluralAffixed: "3 hot spicy swords of cold 'Fred'",
    );

    testIndefinite(
      "noun that starts with a vowel and gets \"an\"",
      axe,
      singular: "an axe",
      singularAffixed: "a hot spicy axe of cold 'Fred'",
      plural: "3 axes",
      pluralAffixed: "3 hot spicy axes of cold 'Fred'",
    );

    testIndefinite(
      "noun that starts with a vowel and gets \"a\"",
      unicycle,
      singular: "a unicycle",
      singularAffixed: "a hot spicy unicycle of cold 'Fred'",
      plural: "3 unicycles",
      pluralAffixed: "3 hot spicy unicycles of cold 'Fred'",
    );

    testIndefinite(
      "noun that starts with a consonant and gets \"an\"",
      homage,
      singular: "an homage",
      singularAffixed: "a hot spicy homage of cold 'Fred'",
      plural: "3 homages",
      pluralAffixed: "3 hot spicy homages of cold 'Fred'",
    );

    testIndefinite(
      "irregular plural",
      stilleto,
      singular: "a stilleto",
      singularAffixed: "a hot spicy stilleto of cold 'Fred'",
      plural: "3 stilletoes",
      pluralAffixed: "3 hot spicy stilletoes of cold 'Fred'",
    );

    testIndefinite(
      "irregular plural",
      staff,
      singular: "a staff",
      singularAffixed: "a hot spicy staff of cold 'Fred'",
      plural: "3 staves",
      pluralAffixed: "3 hot spicy staves of cold 'Fred'",
    );

    testIndefinite(
      "named proper noun",
      sting,
      singular: "Sting",
      singularAffixed: "hot spicy Sting of cold 'Fred'",
      plural: "3 Stings",
      pluralAffixed: "3 hot spicy Stings of cold 'Fred'",
    );

    testIndefinite(
      "titled proper noun",
      phial,
      singular: "the Phial",
      singularAffixed: "the hot spicy Phial of cold 'Fred'",
      plural: "3 Phials",
      pluralAffixed: "3 hot spicy Phials of cold 'Fred'",
    );

    testIndefinite(
      "collective noun",
      pants,
      singular: "a pair of pants",
      singularAffixed: "a pair of hot spicy pants of cold 'Fred'",
      plural: "3 pairs of pants",
      pluralAffixed: "3 pairs of hot spicy pants of cold 'Fred'",
    );

    testIndefinite(
      "mass noun",
      something,
      singular: "something",
      singularAffixed: "hot spicy something of cold 'Fred'",
      plural: "3 somethings",
      pluralAffixed: "3 hot spicy somethings of cold 'Fred'",
    );

    test("vowel-sound prefix", () {
      expect(
        sword.build(1, prefixes: ["unholy"]).indefinite,
        "an unholy sword",
      );

      expect(
        sword.build(3, prefixes: ["unholy"]).indefinite,
        "3 unholy swords",
      );
    });
  });

  group('definite', () {
    testDefinite(
      String description,
      NounBuilder template, {
      required String singular,
      required String singularAffixed,
      required String plural,
      required String pluralAffixed,
    }) {
      test(description, () {
        expect(template.build(1).definite, singular);

        expect(
          template.build(1, prefixes: prefixes, suffixes: suffixes).definite,
          singularAffixed,
        );

        expect(template.build(3).definite, plural);

        expect(
          template.build(3, prefixes: prefixes, suffixes: suffixes).definite,
          pluralAffixed,
        );
      });
    }

    testDefinite(
      "simple noun",
      sword,
      singular: "the sword",
      singularAffixed: "the hot spicy sword of cold 'Fred'",
      plural: "the 3 swords",
      pluralAffixed: "the 3 hot spicy swords of cold 'Fred'",
    );

    testDefinite(
      "noun that starts with a vowel and gets \"an\"",
      axe,
      singular: "the axe",
      singularAffixed: "the hot spicy axe of cold 'Fred'",
      plural: "the 3 axes",
      pluralAffixed: "the 3 hot spicy axes of cold 'Fred'",
    );

    testDefinite(
      "noun that starts with a vowel and gets \"a\"",
      unicycle,
      singular: "the unicycle",
      singularAffixed: "the hot spicy unicycle of cold 'Fred'",
      plural: "the 3 unicycles",
      pluralAffixed: "the 3 hot spicy unicycles of cold 'Fred'",
    );

    testDefinite(
      "noun that starts with a consonant and gets \"an\"",
      homage,
      singular: "the homage",
      singularAffixed: "the hot spicy homage of cold 'Fred'",
      plural: "the 3 homages",
      pluralAffixed: "the 3 hot spicy homages of cold 'Fred'",
    );

    testDefinite(
      "irregular plural",
      stilleto,
      singular: "the stilleto",
      singularAffixed: "the hot spicy stilleto of cold 'Fred'",
      plural: "the 3 stilletoes",
      pluralAffixed: "the 3 hot spicy stilletoes of cold 'Fred'",
    );

    testDefinite(
      "irregular plural",
      staff,
      singular: "the staff",
      singularAffixed: "the hot spicy staff of cold 'Fred'",
      plural: "the 3 staves",
      pluralAffixed: "the 3 hot spicy staves of cold 'Fred'",
    );

    testDefinite(
      "named proper noun",
      sting,
      singular: "Sting",
      singularAffixed: "hot spicy Sting of cold 'Fred'",
      plural: "the 3 Stings",
      pluralAffixed: "the 3 hot spicy Stings of cold 'Fred'",
    );

    testDefinite(
      "titled proper noun",
      phial,
      singular: "the Phial",
      singularAffixed: "the hot spicy Phial of cold 'Fred'",
      plural: "the 3 Phials",
      pluralAffixed: "the 3 hot spicy Phials of cold 'Fred'",
    );

    testDefinite(
      "collective noun",
      pants,
      singular: "the pants",
      singularAffixed: "the hot spicy pants of cold 'Fred'",
      plural: "the 3 pairs of pants",
      pluralAffixed: "the 3 pairs of hot spicy pants of cold 'Fred'",
    );

    testDefinite(
      "mass noun",
      something,
      singular: "something",
      singularAffixed: "hot spicy something of cold 'Fred'",
      plural: "the 3 somethings",
      pluralAffixed: "the 3 hot spicy somethings of cold 'Fred'",
    );
  });
}
