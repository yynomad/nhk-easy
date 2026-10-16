import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../data/news_repository.dart';

class RubyText extends StatelessWidget {
  const RubyText(
    this.source, {
    super.key,
    required this.showRuby,
    this.fontSize = 20,
    this.bold = false,
  });
  final String source;
  final bool showRuby;
  final double fontSize;
  final bool bold;
  @override
  Widget build(BuildContext context) => HtmlWidget(
    cleanHtml(source, ruby: showRuby),
    textStyle: TextStyle(
      fontSize: fontSize,
      height: 1.9,
      fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
    ),
    customStylesBuilder: (element) => switch (element.localName) {
      'rt' => {'font-size': '0.55em'},
      'rp' => {'display': 'none'},
      _ => null,
    },
  );
}
