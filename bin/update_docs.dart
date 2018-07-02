import 'dart:async';
import 'dart:io';

import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;

final hauberkDir = p.dirname(p.dirname(p.fromUri(Platform.script)));
final docDir = new Directory(p.join(hauberkDir, "doc"));

/// Regenerates the documentation HTML files from the Markdown sources.
void main(List<String> arguments) {
  var templatePath = "doc/_template.html";
  var template = readFile(templatePath);

  if (arguments.contains("--watch")) {
    var templateReadTime = new DateTime.now();

    new Timer.periodic(new Duration(seconds: 2), (_) {
      if (modTime(templatePath).isAfter(templateReadTime)) {
        template = readFile(templatePath);
        templateReadTime = new DateTime.now();
      }

      buildDocs(templatePath, template);
    });
  } else {
    buildDocs(templatePath, template, force: true);
  }
}

void buildDocs(String templatePath, String template, {bool force = false}) {
  for (var entry in docDir.listSync(recursive: true)) {
    if (!entry.path.endsWith(".md")) continue;

    var markdownPath = p.relative(entry.path, from: hauberkDir);
    var name = p.basenameWithoutExtension(markdownPath);
    var htmlPath = "web/$name.html";

    if (force ||
        modTime(markdownPath).isAfter(modTime(htmlPath)) ||
        modTime(templatePath).isAfter(modTime(htmlPath))) {
      var markdown = readFile(markdownPath);
      var html = template.replaceAll("{{content}}", markdownToHtml(markdown));
      writeFile("web/$name.html", html);
      print(name);
    }
  }
}

DateTime modTime(String path) {
  return new File(p.join(hauberkDir, path)).lastModifiedSync();
}

String readFile(String path) {
  return new File(p.join(hauberkDir, path)).readAsStringSync();
}

void writeFile(String path, String contents) {
  new File(p.join(hauberkDir, path)).writeAsStringSync(contents);
}
