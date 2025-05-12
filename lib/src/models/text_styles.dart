import 'package:flutter/material.dart';

class TextStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final double? fontSize;
  final Color? color;
  final String? link;
  final TextAlign? alignment;

  TextStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontSize,
    this.color,
    this.link,
    this.alignment,
  });

  TextStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    double? fontSize,
    Color? color,
    String? link,
    TextAlign? alignment,
  }) {
    return TextStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      link: link ?? this.link,
      alignment: alignment ?? this.alignment,
    );
  }

  TextStyleAttributes toAttributes() {
    return TextStyleAttributes(
      bold: bold,
      italic: italic,
      underline: underline,
      fontSize: fontSize,
      color: color,
      link: link,
      alignment: alignment,
    );
  }
}

class TextStyleAttributes {
  final bool bold;
  final bool italic;
  final bool underline;
  final double? fontSize;
  final Color? color;
  final String? link;
  final TextAlign? alignment;

  TextStyleAttributes({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontSize,
    this.color,
    this.link,
    this.alignment,
  });

  factory TextStyleAttributes.fromTextStyle(TextStyle style) {
    return TextStyleAttributes(
      bold: style.bold,
      italic: style.italic,
      underline: style.underline,
      fontSize: style.fontSize,
      color: style.color,
      link: style.link,
      alignment: style.alignment,
    );
  }

  TextStyle toTextStyle() {
    return TextStyle(
      bold: bold,
      italic: italic,
      underline: underline,
      fontSize: fontSize,
      color: color,
      link: link,
      alignment: alignment,
    );
  }

  TextStyleAttributes copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    double? fontSize,
    Color? color,
    String? link,
    TextAlign? alignment,
  }) {
    return TextStyleAttributes(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      link: link ?? this.link,
      alignment: alignment ?? this.alignment,
    );
  }
}

class TextSpanDocument {
  final String text;
  final TextStyle style;
  final int start;
  final int end;

  TextSpanDocument({
    required this.text,
    required this.style,
    required this.start,
    required this.end,
  });
}

class TextElement {
  String text;
  TextStyle style;
  List<TextSpanDocument> spans;

  TextElement({
    required this.text,
    required this.style,
    List<TextSpanDocument>? spans,
  }) : spans = spans ?? [];

  void addSpan(int start, int end, TextStyleAttributes style) {
    spans.add(TextSpanDocument(
      text: text.substring(start, end),
      style: style.toTextStyle(),
      start: start,
      end: end,
    ));
  }

  TextStyleAttributes? styleAt(int position) {
    for (final span in spans) {
      if (position >= span.start && position < span.end) {
        return span.style.toAttributes();
      }
    }
    return null;
  }

  void applyStyle(int start, int end, TextStyleAttributes style) {
    // Удаляем существующие спаны в диапазоне
    spans.removeWhere((span) => (span.start >= start && span.start < end) || (span.end > start && span.end <= end));

    // Добавляем новый спан
    addSpan(start, end, style);
  }
}
