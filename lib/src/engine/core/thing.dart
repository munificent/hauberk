/// The shared base class of [Actor] and [Item].
///
/// Represents a [Noun] with a known quantity.
abstract class Thing {
  static final Thing something = Prop._(NounBuilder.something.build(1));

  /// The base [Noun] used to describe this thing.
  Noun get noun;

  @override
  String toString() => noun.short;
}

/// An ephemeral [Thing] used in messages but not actually interactive in the
/// game world.
final class Prop extends Thing {
  @override
  final Noun noun;

  factory Prop(String template) => Prop._(NounBuilder(template).build(1));

  factory Prop.mass(String template) =>
      Prop._(NounBuilder(template, category: NounCategory.mass).build(1));

  Prop._(this.noun);
}

/// A template for building nouns with a given quantity and set of affixes from
/// a parsed string notation.
///
/// These are used for [Item]s where [ItemType] has a [NounBuilder] created in
/// the game content and then specific [Item]s instantiate a [Noun] from the
/// builder for their stack size and affixes.
///
/// ## Template syntax
///
/// The template syntax for the string works like:
///
/// ## Indefinite article
///
/// If the template starts with "a ", then its indefinite article is "a". If it
/// starts with "an ", then the indefinite article is "an". Otherwise, the
/// indefinite article is "an" if the first letter of the template is a vowel
/// and "a" otherwise.
///
/// ## Collective nouns
///
/// If the template contains text inside parentheses, than that is a
/// "collective" quantifier. For example, "(pair[s] of )pants". If there is a
/// collective, it is included in the noun whenever it's plural or in an
/// indefinite context, but omitted for brevity otherwise. For example: "You
/// see a pair of pants. You pick up the pants."
///
/// ## Pluralization
///
/// If the template contains any text inside square brackets, those determine
/// how it gets pluralized. If the contents are two strings separated by `|`,
/// then the first string is used for the singular form and the second for
/// plural, like "sta[ff|ves]". Otherwise, the singular omits the contents and
/// the plural includes them like "stilleto[es]". If no square brackets are
/// present, then the template implicitly gets an "s" at the end to pluralize.
final class NounBuilder {
  /// Mass noun for the word "something".
  static final NounBuilder something = NounBuilder(
    "something",
    category: NounCategory.mass,
  );

  /// Matches singular/plural markers in a string. There are two forms:
  ///
  /// * A single set of characters in square brackets like `"stilleto[es]"`
  ///   expands to an empty string for the singular and includes the characters
  ///   in brackets for the plural case.
  ///
  /// * Two sets of characters in square brackets like `"sta[ff|ves]"` expands
  ///   to the first set when singular and the second when plural.
  static final RegExp _quantifier = RegExp(
    r"\[" // Opening "[".
    r"([^|\]]+)" // First or only part inside square brackets.
    r"(\|([^\]]+))?" // Optional "|" followed by second part.
    r"\]", // Closing "]".
  );

  static final RegExp _collective = RegExp(
    r"^\(" // Opening "(" at beginning of string.
    r"([^)]+)" // Characters inside the parentheses.
    r"\)" // Closing ")".
    r"(.*)", // Rest of string.
  );

  /// If true, then a leading indefinite "a" becomes "an" unless there is a
  /// prefix in which case it's inferred from the prefix.
  final bool _startsWithVowelSound;

  final String _listSingular;
  final String _indefiniteSingular;
  final String _indefinitePlural;
  final String _definiteSingular;
  final String _definitePlural;

  final Pronoun pronoun;

  String get shortName => build(1).short;

  factory NounBuilder(
    String template, {
    Pronoun pronoun = Pronoun.it,
    NounCategory category = NounCategory.normal,
  }) {
    return _parse(template, pronoun, category);
  }

  NounBuilder._({
    required bool startsWithVowelSound,
    required String listSingular,
    required String indefiniteSingular,
    required String indefinitePlural,
    required String definiteSingular,
    required String definitePlural,
    required this.pronoun,
  }) : _startsWithVowelSound = startsWithVowelSound,
       _listSingular = listSingular,
       _indefiniteSingular = indefiniteSingular,
       _indefinitePlural = indefinitePlural,
       _definiteSingular = definiteSingular,
       _definitePlural = definitePlural;

  Noun build(int count, {List<String>? prefixes, List<String>? suffixes}) {
    String apply(String template) {
      // Apply count at "#" marker if there is one.
      var result = template.replaceAll("#", count.toString());

      // Apply prefixes at "<p>" marker.
      if (prefixes != null && prefixes.isNotEmpty) {
        // The first prefix determines the indefinite article if there is one.
        var a = _startsWithVowel(prefixes[0]) ? "an" : "a";
        result = result.replaceAll("<a>", a);
        result = result.replaceAll("<p>", "${prefixes.join(" ")} ");
      } else {
        // No prefix, so the noun determines the indefinite article.
        result = result.replaceAll("<a>", _startsWithVowelSound ? "an" : "a");
        result = result.replaceAll("<p>", "");
      }

      // Apply suffixes at end.
      if (suffixes != null && suffixes.isNotEmpty) {
        result = "$result ${suffixes.join(" ")}";
      }

      return result;
    }

    if (count == 1) {
      return Noun._(
        apply(_listSingular),
        apply(_indefiniteSingular),
        apply(_definiteSingular),
        pronoun,
      );
    } else {
      return Noun._(
        apply(_indefinitePlural),
        apply(_indefinitePlural),
        apply(_definitePlural),
        pronoun,
      );
    }
  }

  @override
  String toString() => _listSingular;

  static NounBuilder _parse(
    String pattern,
    Pronoun pronoun,
    NounCategory category,
  ) {
    // Get or infer the indefinite article.
    var startsWithVowelSound = false;
    if (pattern.startsWith("a ")) {
      pattern = pattern.substring(2);
    } else if (pattern.startsWith("an ")) {
      pattern = pattern.substring(3);
      startsWithVowelSound = true;
    } else if (_startsWithVowel(pattern)) {
      startsWithVowelSound = true;
    }

    // If it's a collective noun, separate out the quantifier.
    var collective = "";
    if (_collective.firstMatch(pattern) case var match?) {
      collective = match[1]!;
      pattern = match[2]!;
    }

    var singularCollective = _quantify(collective, singular: true);
    var pluralCollective = _quantify(collective, singular: false);
    var singular = _quantify(pattern, singular: true, addS: collective.isEmpty);
    var plural = _quantify(pattern, singular: false, addS: collective.isEmpty);

    return NounBuilder._(
      startsWithVowelSound: startsWithVowelSound,
      listSingular: "<p>$singular",
      indefiniteSingular: switch (category) {
        NounCategory.normal => "<a> $singularCollective<p>$singular",
        NounCategory.proper => "$singularCollective<p>$singular",
        NounCategory.definite => "the $singularCollective<p>$singular",
        NounCategory.mass => "$singularCollective<p>$singular",
      },
      indefinitePlural: "# $pluralCollective<p>$plural",
      definiteSingular: switch (category) {
        NounCategory.normal => "the <p>$singular",
        NounCategory.proper => "<p>$singular",
        NounCategory.definite => "the <p>$singular",
        NounCategory.mass => "<p>$singular",
      },
      definitePlural: "the # $pluralCollective<p>$plural",
      pronoun: pronoun,
    );
  }

  static bool _startsWithVowel(String string) =>
      "aeiouAEIOU".contains(string[0]);

  static String _quantify(
    String pattern, {
    required bool singular,
    bool addS = false,
  }) {
    var hadQuantifier = false;
    var result = pattern.replaceAllMapped(_quantifier, (match) {
      hadQuantifier = true;

      var firstPart = match[1]!;
      if (match[3] case var secondPart?) {
        return singular ? firstPart : secondPart;
      } else {
        // Only one part, so it's implicitly the plural part with an empty
        // string for the singular.
        return singular ? '' : firstPart;
      }
    });

    // If there are no quantifiers in the string, implicitly suffix with "s"
    // for the plural form.
    if (!singular && !hadQuantifier && addS) return '${result}s';

    return result;
  }
}

/// Category determines what article a [Noun] has in different contexts.
enum NounCategory {
  /// A normal noun gets an indefinite article in an indefinite context and a
  /// definite article in a definite context. "You see a stick. You pick up the
  /// stick."
  normal,

  /// A proper noun gets no article. "You see Sting. You pick up Sting."
  proper,

  /// A definite noun is like a proper noun with a title. It always gets "the":
  /// "You see the Phial. You pick up the Phial."
  definite,

  /// A mass noun is unquantified and gets no article. "You see something. You
  /// pick up something."
  mass,
}

/// A textual description of an in-game entity that can be quantified and
/// shown as strings in various contexts.
final class Noun {
  static final Noun you = Noun._("you", "you", "you", Pronoun.you);

  final String short;
  final String indefinite;
  final String definite;

  final Pronoun pronoun;

  factory Noun(String template) => NounBuilder(template).build(1);

  Noun._(this.short, this.indefinite, this.definite, this.pronoun);

  @override
  String toString() => short;
}

enum Pronoun {
  // See http://en.wikipedia.org/wiki/English_personal_pronouns.
  you('you', 'you', 'your'),
  she('she', 'her', 'her'),
  he('he', 'him', 'his'),
  it('it', 'it', 'its'),
  they('they', 'them', 'their');

  final String subjective;
  final String objective;
  final String possessive;

  const Pronoun(this.subjective, this.objective, this.possessive);

  @override
  String toString() => "$subjective/$objective";
}
