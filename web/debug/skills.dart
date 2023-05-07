import 'dart:html' as html;

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/classes.dart';
import 'package:hauberk/src/content/races.dart';
import 'package:hauberk/src/content/skill/skills.dart';
import 'package:hauberk/src/engine.dart';

import 'histogram.dart';

final validator = html.NodeValidatorBuilder.common()..allowInlineStyles();
final breedDrops = <Breed, Histogram<String>>{};

void main() {
  createContent();
  var hero = HeroSave("", Races.human, Classes.mage);

  var text = StringBuffer();
  text.write('''
    <table>
    <thead>
    <tr>
      <td>Name</td>
      <td>Max Level</td>
      <td>Focus</td>
      <td>Complexity</td>
      <td>Damage</td>
      <td>Range</td>
      <td>Description</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var skill in Skills.all) {
    text.write('<tr>');
    text.write('<td><a href="#${anchor(skill.name)}">${skill.name}</a></td>');
    text.write('<td class="r">${skill.maxLevel}</td>');

    if (skill is UsableSkill) {
      text.write('<td class="r">${skill.focusCost(hero, 1)}</td>');
    } else {
      text.write('<td class="r">&mdash;</td>');
    }

    if (skill is Discipline) {
      text.write('<td class="r">&mdash;</td>');
      text.write('<td class="r">&mdash;</td>');
      text.write('<td class="r">&mdash;</td>');
    } else if (skill is Spell) {
      text.write('<td class="r">${skill.baseComplexity}</td>');
      text.write('<td class="r">${skill.damage}</td>');
      text.write('<td class="r">${skill.range}</td>');
    }

    text.write('<td>${skill.description}</td>');
    text.writeln('</tr>');
  }
  text.write('</tbody></table>');

  for (var skill in Skills.all) {
    text.write('<h2 id="${anchor(skill.name)}">${skill.name}</h2>');
    if (skill is Discipline) {
      // TODO: Show stuff.
    } else if (skill is Spell) {
      text.write('''<table><thead>
      <tr>
        <td>Intellect</td><td>Focus Cost</td>
      </tr>
      </thead><tbody>''');
      for (var intellect = skill.baseComplexity; intellect <= 60; intellect++) {
        hero.intellect.update(intellect, (_) {});
        text.write('<tr><td>$intellect</td>');
        var focus = skill.focusCost(hero, 1);
        text.write('<td>$focus</td>');
        text.writeln('</tr>');
      }
      text.writeln('</tbody></table>');
    }
  }

  html.querySelector('body')!.appendHtml(text.toString(), validator: validator);
}

String anchor(String name) => name.replaceAll(" ", "-").toLowerCase();
