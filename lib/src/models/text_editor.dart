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

class DocumentModel {
  final List<dynamic> elements;

  DocumentModel({required this.elements});

  DocumentModel copy() {
    return DocumentModel(elements: List.from(elements));
  }

  void addElement(dynamic element) {
    elements.add(element);
  }

  void updateElement(TextElement oldElement, TextElement newElement) {
    final index = elements.indexOf(oldElement);
    if (index != -1) {
      elements[index] = newElement;
    }
  }
}

// Методы для работы с текстом
void updateTextElement(TextElement element, String newText, TextSelection? selection, DocumentModel document,
    {bool enableLogging = false}) {
  if (enableLogging) {
    print('Обновление текста:');
    print('Старый текст: "${element.text}"');
    print('Новый текст: "$newText"');
    print('Выделение: start=${selection?.start}, end=${selection?.end}');
  }

  // Если есть выделение, обрабатываем как замену
  if (selection != null && selection.start != selection.end) {
    final oldText = element.text;
    final start = selection.start;
    final end = selection.end;

    // Получаем стиль выделенного текста
    final selectedStyle = element.styleAt(start);

    // Создаем новый текст с сохранением стилей
    final beforeText = oldText.substring(0, start);
    final afterText = oldText.substring(end);

    // Создаем новый элемент с обновленным текстом
    final updatedElement = TextElement(
      text: beforeText + newText + afterText,
      style: element.style,
    );

    // Копируем стили из старого элемента
    for (final span in element.spans) {
      if (span.start < start) {
        // Стили до выделения
        updatedElement.addSpan(span.start, span.end, span.style.toAttributes());
      } else if (span.start >= end) {
        // Стили после выделения
        final newStart = span.start - (end - start) + newText.length;
        final newEnd = span.end - (end - start) + newText.length;
        updatedElement.addSpan(newStart, newEnd, span.style.toAttributes());
      }
    }

    // Добавляем стиль для нового текста
    if (selectedStyle != null) {
      updatedElement.addSpan(start, start + newText.length, selectedStyle);
    }

    if (enableLogging) {
      print('Выполнена замена текста:');
      print('Выделенный текст: "${oldText.substring(start, end)}"');
      print('Новый текст: "$newText"');
      print(
          'Стиль: bold=${selectedStyle?.bold}, italic=${selectedStyle?.italic}, underline=${selectedStyle?.underline}, fontSize=${selectedStyle?.fontSize}');
    }

    document.updateElement(element, updatedElement);
    return;
  }

  // Если нет выделения, обрабатываем как обычное обновление
  updateTextElementWithSpans(element, newText, document, enableLogging: enableLogging);
}

void updateTextElementWithSpans(TextElement element, String newText, DocumentModel document,
    {bool enableLogging = false}) {
  if (enableLogging) {
    print('Обновление текста с сохранением стилей:');
    print('Старый текст: "${element.text}"');
    print('Новый текст: "$newText"');
  }

  // Создаем новый элемент с обновленным текстом
  final updatedElement = TextElement(
    text: newText,
    style: element.style,
  );

  // Копируем стили из старого элемента
  for (final span in element.spans) {
    if (span.start < newText.length) {
      final end = span.end > newText.length ? newText.length : span.end;
      updatedElement.addSpan(span.start, end, span.style.toAttributes());
    }
  }

  document.updateElement(element, updatedElement);
}
