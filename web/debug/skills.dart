import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/classes.dart';
import 'package:hauberk/src/content/races.dart';
import 'package:hauberk/src/content/skill/skills.dart';
import 'package:hauberk/src/debug/histogram.dart';
import 'package:hauberk/src/debug/html_builder.dart';
import 'package:hauberk/src/engine.dart';

final breedDrops = <Breed, Histogram<String>>{};

void main() {
  createContent();
  var hero = HeroSave.create("", Races.human, Classes.mage);

  var builder = HtmlBuilder();
  builder.table();
  builder.td('Name');
  builder.td('Max Focus');
  builder.td('Focus');
  builder.td('Complexity');
  builder.td('Damage');
  builder.td('Range');
  builder.td('Description');
  builder.tbody();

  for (var skill in Skills.all) {
    builder.td('<a href="#${anchor(skill.name)}">${skill.name}</a>');
    builder.td(skill.maxLevel);

    if (skill is UsableSkill) {
      builder.td(skill.focusCost(hero, 1));
    } else {
      builder.td('&mdash;', right: true);
    }

    if (skill is Spell) {
      builder.td(skill.baseComplexity);
      builder.td(skill.damage);
      builder.td(skill.range);
    } else {
      builder.td('&mdash;', right: true);
      builder.td('&mdash;', right: true);
      builder.td('&mdash;', right: true);
    }

    builder.td(skill.description);
    builder.trEnd();
  }

  builder.tableEnd();

  builder.h2('Spell focus cost');
  builder.table();
  builder.td('Intellect');
  for (var intellect = 1; intellect <= Stat.modifiedMax; intellect++) {
    builder.td(intellect);
  }

  builder.tbody();
  for (var skill in Skills.all) {
    if (skill is! Spell) continue;

    builder.td(skill.name);
    for (var intellect = 1; intellect <= Stat.modifiedMax; intellect++) {
      hero.intellect.update(intellect, (_) {});
      // TODO: Get this working again.
      // if (skill.calculateLevel(hero) > 0) {
      //   builder.td(skill.focusCost(hero, 1));
      // } else {
      builder.td('&mdash;', right: true);
      // }
    }

    builder.trEnd();
  }
  builder.tableEnd();

  builder.appendToBody();
}

String anchor(String name) => name.replaceAll(" ", "-").toLowerCase();
