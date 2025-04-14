import 'dart:convert';
import 'package:flutter/material.dart';
import 'document_model.dart';
import 'html_document_parser.dart';

/// Формат входной строки для десериализации
enum InputFormat {
  /// JSON формат
  json,

  /// HTML формат
  html,

  /// Обычный текст без форматирования
  plainText,

  /// Автоматическое определение формата
  auto,
}

/// Сериализует DocumentModel в JSON строку
String serializeDocumentModel(DocumentModel model) {
  final Map<String, dynamic> json = {'elements': model.elements.map((element) => serializeElement(element)).toList()};
  return jsonEncode(json);
}

/// Десериализует DocumentModel из строки в указанном формате
/// Если формат auto, пытается определить формат входной строки
DocumentModel deserializeDocumentModel(String inputStr, {InputFormat format = InputFormat.auto}) {
  // Если формат явно указан, используем соответствующий метод десериализации
  switch (format) {
    case InputFormat.json:
      return _deserializeFromJson(inputStr);
    case InputFormat.html:
      // Вызов парсера HTML (предполагается, что он уже определен в проекте)
      return HtmlDocumentParser.parseHtml(inputStr);
    case InputFormat.plainText:
      return _deserializeFromPlainText(inputStr);
    case InputFormat.auto:
    default:
      // Автоматическое определение формата
      return _detectFormatAndDeserialize(inputStr);
  }
}

/// Десериализует DocumentModel из JSON строки
DocumentModel _deserializeFromJson(String jsonStr) {
  try {
    final Map<String, dynamic> json = jsonDecode(jsonStr);
    final List<dynamic> elementsJson = json['elements'];
    final List<DocumentElement> elements = elementsJson.map((elementJson) => deserializeElement(elementJson)).toList();

    return DocumentModel(elements: elements);
  } catch (e) {
    print('Ошибка при десериализации JSON: $e');
    // Возвращаем модель с ошибкой
    return DocumentModel(
      elements: [
        TextElement(text: 'Ошибка при десериализации JSON: $e', style: TextStyleAttributes(color: Colors.red)),
      ],
    );
  }
}

/// Создает DocumentModel из обычного текста без форматирования
DocumentModel _deserializeFromPlainText(String plainText) {
  // Разбиваем текст на параграфы по символам новой строки
  final paragraphs = plainText.split('\n\n');

  // Создаем список элементов
  final elements = <DocumentElement>[];

  for (final paragraph in paragraphs) {
    final trimmedText = paragraph.trim();
    if (trimmedText.isNotEmpty) {
      elements.add(TextElement(text: trimmedText));
    }
  }

  // Если элементов нет, создаем пустой текстовый элемент
  if (elements.isEmpty) {
    elements.add(TextElement(text: plainText.trim()));
  }

  return DocumentModel(elements: elements);
}

/// Определяет формат входной строки и применяет соответствующий метод десериализации
DocumentModel _detectFormatAndDeserialize(String inputStr) {
  inputStr = inputStr.trim();

  // Пробуем определить формат по содержимому строки

  // Проверяем, похоже ли на JSON (начинается с { и заканчивается на })
  if (inputStr.startsWith('{') && inputStr.endsWith('}')) {
    try {
      return _deserializeFromJson(inputStr);
    } catch (e) {
      print('Строка похожа на JSON, но не удалось распарсить: $e');
      // Продолжаем с другими форматами
    }
  }

  // Проверяем, похоже ли на HTML (содержит HTML-теги)
  final containsHtmlTags = RegExp(r'<[a-z]+[^>]*>|</[a-z]+>').hasMatch(inputStr);
  if (containsHtmlTags) {
    return HtmlDocumentParser.parseHtml(inputStr);
  }

  // Если не определили формат, считаем обычным текстом
  return _deserializeFromPlainText(inputStr);
}

/// Сериализует DocumentElement в JSON
Map<String, dynamic> serializeElement(DocumentElement element) {
  if (element is TextElement) {
    return {'type': 'text', 'spans': element.spans.map((span) => serializeSpan(span)).toList()};
  } else if (element is ImageElement) {
    return {
      'type': 'image',
      'imageUrl': element.imageUrl,
      'caption': element.caption,
      'width': element.width,
      'height': element.height,
      'alignment': serializeAlignment(element.alignment),
      'paragraphText': element.paragraphText,
      'originalWidth': element.originalWidth,
      'originalHeight': element.originalHeight,
      'sizePercent': element.sizePercent,
      'sizeType': element.sizeType,
    };
  }
  throw Exception('Неизвестный тип элемента');
}

/// Десериализует DocumentElement из JSON
DocumentElement deserializeElement(Map<String, dynamic> json) {
  final String type = json['type'];

  if (type == 'text') {
    final List<dynamic> spansJson = json['spans'];
    final List<TextSpanDocument> spans = spansJson.map((spanJson) => deserializeSpan(spanJson)).toList();

    final textElement = TextElement(text: ''); // Создаем пустой TextElement
    textElement.spans = spans; // Устанавливаем spans
    return textElement;
  } else if (type == 'image') {
    return ImageElement(
      imageUrl: json['imageUrl'],
      caption: json['caption'] ?? '',
      width: json['width']?.toDouble() ?? 300.0,
      height: json['height']?.toDouble() ?? 200.0,
      alignment: deserializeAlignment(json['alignment']),
      paragraphText: json['paragraphText'],
      originalWidth: json['originalWidth']?.toDouble(),
      originalHeight: json['originalHeight']?.toDouble(),
      sizePercent: json['sizePercent']?.toDouble() ?? 100.0,
      sizeType: json['sizeType'] ?? 'absolute',
    );
  }
  throw Exception('Неизвестный тип элемента: $type');
}

/// Сериализует TextSpanDocument в JSON
Map<String, dynamic> serializeSpan(TextSpanDocument span) {
  return {'text': span.text, 'style': serializeStyle(span.style)};
}

/// Десериализует TextSpanDocument из JSON
TextSpanDocument deserializeSpan(Map<String, dynamic> json) {
  return TextSpanDocument(text: json['text'], style: deserializeStyle(json['style']));
}

/// Сериализует TextStyleAttributes в JSON
Map<String, dynamic> serializeStyle(TextStyleAttributes style) {
  return {
    'bold': style.bold,
    'italic': style.italic,
    'underline': style.underline,
    'color': style.color?.value,
    'fontSize': style.fontSize,
    'link': style.link,
    'alignment': serializeTextAlign(style.alignment),
  };
}

/// Десериализует TextStyleAttributes из JSON
TextStyleAttributes deserializeStyle(Map<String, dynamic> json) {
  return TextStyleAttributes(
    bold: json['bold'] ?? false,
    italic: json['italic'] ?? false,
    underline: json['underline'] ?? false,
    color: json['color'] != null ? Color(json['color']) : null,
    fontSize: json['fontSize']?.toDouble() ?? 14.0,
    link: json['link'],
    alignment: deserializeTextAlign(json['alignment']),
  );
}

/// Сериализует TextAlign в строку
String serializeTextAlign(TextAlign align) {
  switch (align) {
    case TextAlign.left:
      return 'left';
    case TextAlign.center:
      return 'center';
    case TextAlign.right:
      return 'right';
    case TextAlign.justify:
      return 'justify';
    case TextAlign.start:
      return 'start';
    case TextAlign.end:
      return 'end';
    default:
      return 'left';
  }
}

/// Десериализует TextAlign из строки
TextAlign deserializeTextAlign(String? align) {
  switch (align) {
    case 'left':
      return TextAlign.left;
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    case 'start':
      return TextAlign.start;
    case 'end':
      return TextAlign.end;
    default:
      return TextAlign.left;
  }
}

/// Сериализует AlignmentGeometry в строку
String serializeAlignment(AlignmentGeometry alignment) {
  if (alignment == Alignment.center) return 'center';
  if (alignment == Alignment.centerLeft) return 'centerLeft';
  if (alignment == Alignment.centerRight) return 'centerRight';
  if (alignment == Alignment.topCenter) return 'topCenter';
  if (alignment == Alignment.topLeft) return 'topLeft';
  if (alignment == Alignment.topRight) return 'topRight';
  if (alignment == Alignment.bottomCenter) return 'bottomCenter';
  if (alignment == Alignment.bottomLeft) return 'bottomLeft';
  if (alignment == Alignment.bottomRight) return 'bottomRight';
  return 'center'; // По умолчанию центр
}

/// Десериализует AlignmentGeometry из строки
AlignmentGeometry deserializeAlignment(String? alignment) {
  switch (alignment) {
    case 'center':
      return Alignment.center;
    case 'centerLeft':
      return Alignment.centerLeft;
    case 'centerRight':
      return Alignment.centerRight;
    case 'topCenter':
      return Alignment.topCenter;
    case 'topLeft':
      return Alignment.topLeft;
    case 'topRight':
      return Alignment.topRight;
    case 'bottomCenter':
      return Alignment.bottomCenter;
    case 'bottomLeft':
      return Alignment.bottomLeft;
    case 'bottomRight':
      return Alignment.bottomRight;
    default:
      return Alignment.center;
  }
}
