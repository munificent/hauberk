import 'dart:async';
import 'dart:io';

import 'package:hauberk/src/engine.dart' show Log;
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;

final hauberkDir = p.dirname(p.dirname(p.fromUri(Platform.script)));
final docDir = Directory(p.join(hauberkDir, "doc"));

/// Regenerates the documentation HTML files from the Markdown sources.
void main(List<String> arguments) {
  var templatePath = "doc/_template.html";
  var template = readFile(templatePath);

  if (arguments.contains("--watch")) {
    var templateReadTime = DateTime.now();

    Timer.periodic(Duration(seconds: 2), (_) {
      if (modTime(templatePath).isAfter(templateReadTime)) {
        template = readFile(templatePath);
        templateReadTime = DateTime.now();
      }

      buildDocs(templatePath, template);
    });
  } else {
    buildDocs(templatePath, template, force: true);
  }
}

void buildDocs(String templatePath, String template, {bool force = false}) {
  var chapters = <String, List<Node>>{};

  for (var entry in docDir.listSync(recursive: true)) {
    if (!entry.path.endsWith(".md")) continue;

    var markdownPath = p.relative(entry.path, from: hauberkDir);
    var name = p.basenameWithoutExtension(markdownPath);
    var htmlPath = "web/$name.html";

    if (force ||
        modTime(markdownPath).isAfter(modTime(htmlPath)) ||
        modTime(templatePath).isAfter(modTime(htmlPath))) {
      var markdown = readFile(markdownPath);

      var document = Document();
      var nodes = document.parse(markdown);

      // Assume first paragraph in the page is the page header.
      chapters[nodes[0].textContent] = nodes;

      var html = template.replaceAll("{{content}}", renderToHtml(nodes));
      writeFile("web/$name.html", html);
      print("Wrote web/$name.html");
    }
  }

  buildInGameDocs(chapters);
}

DateTime modTime(String path) {
  return File(p.join(hauberkDir, path)).lastModifiedSync();
}

String readFile(String path) {
  return File(p.join(hauberkDir, path)).readAsStringSync();
}

void writeFile(String path, String contents) {
  File(p.join(hauberkDir, path)).writeAsStringSync(contents);
}

void buildInGameDocs(Map<String, List<Node>> chapters) {
  // Update the in-game help.
  var buffer = StringBuffer();
  buffer.writeln("import \"../../hues.dart\";");
  buffer.writeln("import \"help_dialog.dart\";");
  buffer.writeln();
  buffer.writeln("const Map<String, List<HelpLine>> helpChapters = {");

  chapters.forEach((chapter, nodes) {
    buffer.writeln("  \"$chapter\": [");

    var needsBlankLine = false;
    for (var node in nodes) {
      var text = node.textContent
          .replaceAll("\n", " ")
          .replaceAll("\"", "\\\"")
          .replaceAll("&lt;", "<")
          .replaceAll("&gt;", ">")
          .replaceAll("&quot;", "\\\"");

      if (needsBlankLine) {
        buffer.writeln("    HelpLine(\"\"),");
        needsBlankLine = false;
      }

      switch (node) {
        case Element(tag: "h1"):
          buffer.writeln("    HelpLine(color: UIHue.header, \"$text\"),");
          buffer.writeln("    HelpLine(color: UIHue.header, \"${'═' * 50}\"),");

        case Element(tag: "h2"):
          buffer.writeln("    HelpLine(color: UIHue.header, \"$text\"),");
          buffer.writeln("    HelpLine(color: UIHue.header, \"${'─' * 50}\"),");

        case Element(tag: "h3"):
          buffer.writeln("    HelpLine(color: UIHue.header, \"$text\"),");

        default:
          for (var line in Log.wordWrap(50, text)) {
            buffer.writeln("    HelpLine(\"$line\"),");
          }
      }

      needsBlankLine = true;
    }

    buffer.writeln("  ],");
  });

  buffer.writeln("};");
  writeFile("lib/src/ui/help/data.dart", buffer.toString());
  print("Wrote in-game help data");
}
