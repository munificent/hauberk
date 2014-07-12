import 'dart:async';

import 'package:barback/barback.dart';
import 'package:markdown/markdown.dart';

// TODO: Make lazy.
class MarkdownToHtmlTransformer extends Transformer {
  MarkdownToHtmlTransformer.asPlugin();

  String get allowedExtensions => ".md";

  Future apply(Transform transform) {
    var template;
    var templateId = new AssetId("hauberk", "web/_template.html");
    return transform.readInputAsString(templateId).then((_template) {
      template = _template;
      return transform.primaryInput.readAsString();
    }).then((contents) {
      transform.consumePrimary();
      var html = template.replaceAll("{{content}}", markdownToHtml(contents));
      var id = transform.primaryInput.id.changeExtension(".html");
      transform.addOutput(new Asset.fromString(id, html));
    });
  }
}