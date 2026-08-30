import 'dart:async';
import 'dart:io';

import 'package:hauberk/src/engine.dart' show Log;
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;

final hauberkDir = p.dirname(p.dirname(p.fromUri(Platform.script)));
final docDir = Directory(p.join(hauberkDir, "doc"));

const _pageWidth = 56;

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

  void write(String text, {String? color}) {
    if (color == null) {
      buffer.writeln("    HelpLine(\"$text\"),");
    } else {
      buffer.writeln("    HelpLine(color: UIHue.$color, \"$text\"),");
    }
  }

  void writeNewline([int count = 1]) {
    for (var i = 0; i < count; i++) {
      buffer.writeln("    HelpLine(\"\"),");
    }
  }

  chapters.forEach((chapter, nodes) {
    buffer.writeln("  \"$chapter\": [");

    var afterParagraph = false;
    for (var node in nodes) {
      var text = node.textContent
          .replaceAll("\\", "\\\\")
          .replaceAll("\"", "\\\"")
          .replaceAll("&lt;", "<")
          .replaceAll("&gt;", ">")
          .replaceAll("&quot;", "\\\"");

      var isParagraph = false;
      switch (node) {
        case Element(tag: "h1"):
          write(color: "header", text);
          write(color: "header", '═' * _pageWidth);

        case Element(tag: "h2"):
          writeNewline(2);
          write(color: "header", text);
          write(color: "header", '─' * _pageWidth);

        case Element(tag: "h3"):
          writeNewline(2);
          write(color: "header", text);
          writeNewline();

        case Element(tag: "pre"):
          if (afterParagraph) writeNewline(2);
          for (var line in text.trim().split("\n")) {
            write(line);
          }
          isParagraph = true;

        case Element(tag: "p"):
          if (afterParagraph) writeNewline(2);
          var collapsed = text.replaceAll("\n", " ");
          for (var line in Log.wordWrap(_pageWidth, collapsed)) {
            write(line);
            writeNewline();
          }

          isParagraph = true;

        default:
          print("Unhandled node $node");
      }

      afterParagraph = isParagraph;
    }

    buffer.writeln("  ],");
  });

  buffer.writeln("};");
  writeFile("lib/src/ui/help/data.dart", buffer.toString());
  print("Wrote in-game help data");
}
