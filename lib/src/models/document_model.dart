import 'package:flutter/material.dart';
import 'dart:convert';
import 'html_document_parser.dart';

/// Тип элемента документа
enum DocumentElementType { text, image }

/// Стиль текста
class TextStyleAttributes {
  final bool bold;
  final bool italic;
  final bool underline;
  final Color? color;
  final double fontSize;
  final String? link; // Добавляем поддержку ссылок
  final TextAlign alignment; // Добавляем поддержку выравнивания

  const TextStyleAttributes({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color,
    this.fontSize = 14.0,
    this.link, // Ссылка может быть null
    this.alignment = TextAlign.justify, // По умолчанию выравнивание по левому краю
  });
  factory TextStyleAttributes.fromTextStyle({
    required TextStyle textStyle,
    String? link,
    TextAlign alignment = TextAlign.justify,
  }) => TextStyleAttributes(
    bold: textStyle.fontWeight == FontWeight.bold,
    italic: textStyle.fontStyle == FontStyle.italic,
    underline: textStyle.decoration == TextDecoration.underline,
    color: textStyle.color,
    fontSize: textStyle.fontSize ?? 14.0,
    link: link,
    alignment: alignment,
  );

  TextStyleAttributes copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    Color? color,
    double? fontSize,
    String? link,
    bool removeLink = false, // Флаг для удаления ссылки
    TextAlign? alignment,
  }) {
    return TextStyleAttributes(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      link: removeLink ? null : (link ?? this.link),
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextStyleAttributes &&
        other.bold == bold &&
        other.italic == italic &&
        other.underline == underline &&
        other.color == color &&
        other.fontSize == fontSize &&
        other.link == link &&
        other.alignment == alignment;
  }

  @override
  int get hashCode =>
      bold.hashCode ^
      italic.hashCode ^
      underline.hashCode ^
      color.hashCode ^
      fontSize.hashCode ^
      (link?.hashCode ?? 0) ^
      alignment.hashCode;
}

/// Определяет часть текста со своим стилем
class TextSpanDocument {
  String text;
  TextStyleAttributes style;

  TextSpanDocument({required this.text, required this.style});

  TextSpanDocument copyWith({String? text, TextStyleAttributes? style}) {
    return TextSpanDocument(text: text ?? this.text, style: style ?? this.style);
  }
}

/// Базовый класс для элементов документа
abstract class DocumentElement {
  final DocumentElementType type;

  DocumentElement({required this.type});
}

/// Элемент текста, который теперь поддерживает разные стили для разных частей
class TextElement extends DocumentElement {
  List<TextSpanDocument> spans;

  TextElement({required String text, TextStyleAttributes? style})
    : spans = [TextSpanDocument(text: text, style: style ?? const TextStyleAttributes())],
      super(type: DocumentElementType.text);

  /// Получить полный текст
  String get text => spans.map((span) => span.text).join();

  /// Установить текст с сохранением стилей
  set text(String newText) {
    if (spans.isEmpty) {
      spans = [TextSpanDocument(text: newText, style: const TextStyleAttributes())];
    } else if (spans.length == 1) {
      // Если один спан, просто обновляем текст
      spans[0].text = newText;
    } else {
      // Для текста с несколькими спанами
      final oldText = text;

      // Если тексты сильно отличаются, заменяем первый спан на весь текст
      if (oldText.isEmpty ||
          newText.isEmpty ||
          (oldText.length / newText.length > 2) ||
          (newText.length / oldText.length > 2)) {
        final style = spans[0].style;
        spans = [TextSpanDocument(text: newText, style: style)];
        return;
      }

      // Когда изменения незначительные, пытаемся сохранить форматирование
      if (newText.length > oldText.length && newText.contains(oldText)) {
        // Текст был дополнен, находим где именно
        final int startIndex = newText.indexOf(oldText);
        if (startIndex == 0) {
          // Добавили текст в конец
          final String addedText = newText.substring(oldText.length);
          spans.add(TextSpanDocument(text: addedText, style: spans.last.style));
        } else {
          // Добавили текст в начало
          final String addedText = newText.substring(0, startIndex);
          spans.insert(0, TextSpanDocument(text: addedText, style: spans.first.style));
        }
      } else if (oldText.length > newText.length && oldText.contains(newText)) {
        // Текст был сокращен, находим где именно
        final int startIndex = oldText.indexOf(newText);
        if (startIndex == 0) {
          // Удалили текст с конца
          int remainingLength = newText.length;
          final newSpans = <TextSpanDocument>[];

          for (final span in spans) {
            if (remainingLength <= 0) break;
            final int spanLength = span.text.length;
            if (spanLength <= remainingLength) {
              newSpans.add(span);
              remainingLength -= spanLength;
            } else {
              newSpans.add(TextSpanDocument(text: span.text.substring(0, remainingLength), style: span.style));
              remainingLength = 0;
            }
          }

          spans = newSpans;
        } else {
          // Сложный случай, просто заменяем текст с сохранением стиля первого спана
          final style = spans[0].style;
          spans = [TextSpanDocument(text: newText, style: style)];
        }
      } else {
        // Если не можем сохранить форматирование, просто заменяем текст
        final style = spans[0].style;
        spans = [TextSpanDocument(text: newText, style: style)];
      }
    }
  }

  /// Получить стиль (актуально, когда один стиль на весь текст)
  TextStyleAttributes get style => spans.isNotEmpty ? spans[0].style : const TextStyleAttributes();

  /// Установить один стиль на весь текст
  set style(TextStyleAttributes newStyle) {
    spans = [TextSpanDocument(text: text, style: newStyle)];
  }

  /// Получить стиль в указанной позиции текста
  TextStyleAttributes? styleAt(int position) {
    if (position < 0 || spans.isEmpty) return null;

    int currentPos = 0;
    for (final span in spans) {
      final spanEnd = currentPos + span.text.length;
      if (position >= currentPos && position < spanEnd) {
        return span.style;
      }
      currentPos = spanEnd;
    }

    // Если позиция за пределами текста, возвращаем стиль последнего спана
    if (position >= currentPos && spans.isNotEmpty) {
      return spans.last.style;
    }

    return null;
  }

  /// Применить стиль к части текста
  void applyStyle(TextStyleAttributes newStyle, int start, int end) {
    if (spans.isEmpty) return;
    if (start >= end) return;

    final String fullText = text;
    if (start < 0 || end > fullText.length) return;

    // Если один спан и стиль одинаковый, ничего не делаем
    if (spans.length == 1 && spans[0].style == newStyle) {
      return;
    }

    // Создаем новые спаны
    final List<TextSpanDocument> newSpans = [];
    int currentPosition = 0;

    // Обрабатываем текст до выделения
    if (start > 0) {
      final List<TextSpanDocument> beforeSpans = _getSpansInRange(0, start);
      newSpans.addAll(beforeSpans);
      currentPosition = start;
    }

    // Добавляем выделенный текст с новым стилем
    newSpans.add(TextSpanDocument(text: fullText.substring(start, end), style: newStyle));
    currentPosition = end;

    // Обрабатываем текст после выделения
    if (end < fullText.length) {
      final List<TextSpanDocument> afterSpans = _getSpansInRange(end, fullText.length);
      newSpans.addAll(afterSpans);
    }

    // Объединяем соседние спаны с одинаковым стилем
    spans = _mergeAdjacentSpans(newSpans);
  }

  /// Получить спаны в заданном диапазоне
  List<TextSpanDocument> _getSpansInRange(int start, int end) {
    final List<TextSpanDocument> result = [];
    int currentPosition = 0;

    for (final span in spans) {
      final spanStart = currentPosition;
      final spanEnd = currentPosition + span.text.length;

      // Спан полностью за пределами диапазона
      if (spanEnd <= start || spanStart >= end) {
        currentPosition = spanEnd;
        continue;
      }

      // Спан попадает в диапазон
      final overlapStart = spanStart < start ? start : spanStart;
      final overlapEnd = spanEnd > end ? end : spanEnd;

      if (overlapStart < overlapEnd) {
        result.add(
          TextSpanDocument(
            text: span.text.substring(overlapStart - spanStart, overlapEnd - spanStart),
            style: span.style,
          ),
        );
      }

      currentPosition = spanEnd;
    }

    return result;
  }

  /// Объединить соседние спаны с одинаковым стилем
  List<TextSpanDocument> _mergeAdjacentSpans(List<TextSpanDocument> inputSpans) {
    if (inputSpans.length <= 1) return inputSpans;

    final List<TextSpanDocument> result = [inputSpans[0]];

    for (int i = 1; i < inputSpans.length; i++) {
      final currentSpan = inputSpans[i];
      final previousSpan = result.last;

      if (previousSpan.style == currentSpan.style) {
        // Объединяем спаны с одинаковым стилем
        result.last = TextSpanDocument(text: previousSpan.text + currentSpan.text, style: previousSpan.style);
      } else {
        result.add(currentSpan);
      }
    }

    return result;
  }
}

/// Элемент изображения
class ImageElement extends DocumentElement {
  final String imageUrl;
  final String caption;
  final double width;
  final double height;
  final AlignmentGeometry alignment;
  final String? paragraphText; // Текстовый параграф, связанный с изображением

  // Оригинальные размеры изображения
  final double? originalWidth;
  final double? originalHeight;

  // Процент от оригинального размера (0-100)
  final double sizePercent;

  // Тип размера: 'absolute' (абсолютный), 'percent' (процент от оригинала), 'screen' (процент от экрана)
  final String sizeType;

  ImageElement({
    required this.imageUrl,
    this.caption = '',
    this.width = 300,
    this.height = 200,
    this.alignment = Alignment.center,
    this.paragraphText,
    this.originalWidth,
    this.originalHeight,
    this.sizePercent = 100.0,
    this.sizeType = 'screen',
  }) : super(type: DocumentElementType.image);

  /// Создает копию элемента с новыми значениями
  ImageElement copyWith({
    String? imageUrl,
    String? caption,
    double? width,
    double? height,
    AlignmentGeometry? alignment,
    String? paragraphText,
    double? originalWidth,
    double? originalHeight,
    double? sizePercent,
    String? sizeType,
  }) {
    return ImageElement(
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      width: width ?? this.width,
      height: height ?? this.height,
      alignment: alignment ?? this.alignment,
      paragraphText: paragraphText ?? this.paragraphText,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
      sizePercent: sizePercent ?? this.sizePercent,
      sizeType: sizeType ?? this.sizeType,
    );
  }
}

/// Модель документа содержит все элементы
class DocumentModel {
  List<DocumentElement> elements;

  DocumentModel({this.elements = const []});

  void addElement(DocumentElement element) {
    elements.add(element);
  }

  /// Вставляет элемент в указанную позицию
  void insertElement(int index, DocumentElement element) {
    if (index >= 0 && index <= elements.length) {
      elements.insert(index, element);
    }
  }

  void removeElement(int index) {
    if (index >= 0 && index < elements.length) {
      elements.removeAt(index);
    }
  }

  DocumentModel copy() {
    return DocumentModel(elements: List.from(elements));
  }

  /// Преобразует DocumentModel в JSON строку
  String toJson() {
    final jsonMap = {
      'elements':
          elements.map((element) {
            if (element is TextElement) {
              return {
                'type': 'text',
                'spans':
                    element.spans
                        .map(
                          (span) => {
                            'text': span.text,
                            'style': {
                              'bold': span.style.bold,
                              'italic': span.style.italic,
                              'underline': span.style.underline,
                              'color': span.style.color?.value,
                              'fontSize': span.style.fontSize,
                              'link': span.style.link,
                              'alignment': _serializeTextAlign(span.style.alignment),
                            },
                          },
                        )
                        .toList(),
              };
            } else if (element is ImageElement) {
              return {
                'type': 'image',
                'imageUrl': element.imageUrl,
                'caption': element.caption,
                'width': element.width,
                'height': element.height,
                'alignment': _serializeAlignment(element.alignment),
                'paragraphText': element.paragraphText,
                'originalWidth': element.originalWidth,
                'originalHeight': element.originalHeight,
                'sizePercent': element.sizePercent,
                'sizeType': element.sizeType,
              };
            }
            throw Exception('Неизвестный тип элемента');
          }).toList(),
    };
    return jsonEncode(jsonMap);
  }

  /// Создает DocumentModel из JSON строки
  static DocumentModel fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final List<dynamic> elementsJson = json['elements'];

    final List<DocumentElement> elements =
        elementsJson.map((elementJson) {
          final String type = elementJson['type'];

          if (type == 'text') {
            final List<dynamic> spansJson = elementJson['spans'];
            final List<TextSpanDocument> spans =
                spansJson.map((spanJson) {
                  final style = spanJson['style'];
                  return TextSpanDocument(
                    text: spanJson['text'],
                    style: TextStyleAttributes(
                      bold: style['bold'] ?? false,
                      italic: style['italic'] ?? false,
                      underline: style['underline'] ?? false,
                      color: style['color'] != null ? Color(style['color']) : null,
                      fontSize: style['fontSize']?.toDouble() ?? 14.0,
                      link: style['link'],
                      alignment: _deserializeTextAlign(style['alignment']),
                    ),
                  );
                }).toList();

            final textElement = TextElement(text: '');
            textElement.spans = spans;
            return textElement;
          } else if (type == 'image') {
            return ImageElement(
              imageUrl: elementJson['imageUrl'],
              caption: elementJson['caption'] ?? '',
              width: elementJson['width']?.toDouble() ?? 300.0,
              height: elementJson['height']?.toDouble() ?? 200.0,
              alignment: _deserializeAlignment(elementJson['alignment']),
              paragraphText: elementJson['paragraphText'],
              originalWidth: elementJson['originalWidth']?.toDouble(),
              originalHeight: elementJson['originalHeight']?.toDouble(),
              sizePercent: elementJson['sizePercent']?.toDouble() ?? 100.0,
              sizeType: elementJson['sizeType'] ?? 'screen',
            );
          }
          throw Exception('Неизвестный тип элемента: $type');
        }).toList();

    return DocumentModel(elements: elements);
  }

  // Вспомогательные методы для сериализации

  static String _serializeTextAlign(TextAlign align) {
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
        return 'justify';
    }
  }

  static TextAlign _deserializeTextAlign(String? align) {
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
        return TextAlign.justify;
    }
  }

  static String _serializeAlignment(AlignmentGeometry alignment) {
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

  static AlignmentGeometry _deserializeAlignment(String? alignment) {
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

  /// Создает DocumentModel из HTML строки
  static DocumentModel fromHtml(String htmlString) {
    // Это просто обертка для импортирования парсера HTML
    // Полная реализация находится в html_document_parser.dart
    return HtmlDocumentParser.parseHtml(htmlString);
  }

  /// Создает DocumentModel из обычного текста
  static DocumentModel fromPlainText(String plainText) {
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

  /// Преобразует DocumentModel в HTML строку
  String toHtml() {
    return HtmlDocumentParser.convertToHtml(this);
  }
}
