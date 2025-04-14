import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'document_model.dart';

/// Класс для преобразования HTML в DocumentModel и обратно
class HtmlDocumentParser {
  /// Преобразует HTML-строку в DocumentModel для редактора
  static DocumentModel parseHtml(String htmlString) {
    if (htmlString.isEmpty) {
      return DocumentModel(elements: [TextElement(text: "", style: TextStyleAttributes())]);
    }

    try {
      final document = html_parser.parse(htmlString);
      final elements = <DocumentElement>[];

      // Обрабатываем элементы HTML
      _parseHtmlNodes(document.body?.nodes ?? [], elements);

      if (elements.isEmpty) {
        return DocumentModel(elements: [TextElement(text: htmlString, style: TextStyleAttributes())]);
      }

      return DocumentModel(elements: elements);
    } catch (e) {
      print('Ошибка при парсинге HTML: $e');
      // В случае ошибки возвращаем необработанный HTML как текст
      return DocumentModel(elements: [TextElement(text: htmlString, style: TextStyleAttributes())]);
    }
  }

  /// Обрабатывает HTML-узлы и добавляет соответствующие элементы в DocumentModel
  static void _parseHtmlNodes(List<dom.Node> nodes, List<DocumentElement> elements) {
    for (var node in nodes) {
      if (node is dom.Element) {
        // Обработка изображений
        if (node.localName == 'img') {
          final imageUrl = node.attributes['src'] ?? '';
          final alt = node.attributes['alt'] ?? '';

          // Определяем выравнивание на основе стилей
          Alignment alignment = Alignment.center;
          String? style = node.attributes['style'];
          if (style != null) {
            if (style.contains('float: left')) {
              alignment = Alignment.centerLeft;
            } else if (style.contains('float: right')) {
              alignment = Alignment.centerRight;
            }
          }

          // Извлекаем ширину из стилей
          double width = 300; // Ширина по умолчанию
          if (style != null) {
            final widthRegex = RegExp(r'width: (\d+)px');
            final match = widthRegex.firstMatch(style);
            if (match != null && match.groupCount >= 1) {
              width = double.tryParse(match.group(1) ?? '') ?? width;
            }
          }

          // Ищем подпись (figcaption) для изображения
          String caption = alt;
          dom.Element? figcaption;

          try {
            // Ищем figcaption среди дочерних элементов родителя
            if (node.parent != null) {
              for (var childNode in node.parent!.nodes) {
                if (childNode is dom.Element && childNode.localName == 'figcaption') {
                  figcaption = childNode;
                  break;
                }
              }
            }
          } catch (e) {
            print('Ошибка при поиске figcaption: $e');
          }

          if (figcaption != null) {
            caption = figcaption.text ?? alt;
          }

          elements.add(ImageElement(imageUrl: imageUrl, caption: caption, alignment: alignment, width: width));
        }
        // Обработка параграфов и других текстовых элементов
        else if (node.localName == 'p' ||
            node.localName == 'div' ||
            node.localName == 'h1' ||
            node.localName == 'h2' ||
            node.localName == 'h3' ||
            node.localName == 'h4' ||
            node.localName == 'h5' ||
            node.localName == 'h6' ||
            node.localName == 'span') {
          // Определяем базовый стиль для элемента
          TextStyleAttributes baseStyle = TextStyleAttributes();

          // Устанавливаем размер шрифта в зависимости от типа заголовка
          if (node.localName == 'h1')
            baseStyle = baseStyle.copyWith(fontSize: 32, bold: true);
          else if (node.localName == 'h2')
            baseStyle = baseStyle.copyWith(fontSize: 28, bold: true);
          else if (node.localName == 'h3')
            baseStyle = baseStyle.copyWith(fontSize: 24, bold: true);
          else if (node.localName == 'h4')
            baseStyle = baseStyle.copyWith(fontSize: 20, bold: true);
          else if (node.localName == 'h5')
            baseStyle = baseStyle.copyWith(fontSize: 18, bold: true);
          else if (node.localName == 'h6')
            baseStyle = baseStyle.copyWith(fontSize: 16, bold: true);

          // Определяем выравнивание текста
          TextAlign textAlign = TextAlign.left;
          String? style = node.attributes['style'];
          if (style != null) {
            if (style.contains('text-align: center'))
              textAlign = TextAlign.center;
            else if (style.contains('text-align: right'))
              textAlign = TextAlign.right;
            else if (style.contains('text-align: justify'))
              textAlign = TextAlign.justify;
          }

          baseStyle = baseStyle.copyWith(alignment: textAlign);

          // Создаем список спанов для текстового элемента
          final spans = <TextSpanDocument>[];
          _parseTextNode(node, spans, baseStyle);

          if (spans.isNotEmpty) {
            // Вычисляем общий текст из всех спанов
            String fullText = spans.map((span) => span.text).join();

            final textElement = TextElement(text: fullText, style: baseStyle);
            // Устанавливаем спаны, только если их несколько или стили отличаются
            if (spans.length > 1 || (spans.length == 1 && spans[0].style != baseStyle)) {
              textElement.spans = spans;
            }
            elements.add(textElement);
          }
        }
        // Рекурсивная обработка других типов элементов
        else {
          _parseHtmlNodes(node.nodes, elements);
        }
      }
      // Обработка текстовых узлов
      else if (node is dom.Text) {
        final text = node.text?.trim() ?? '';
        if (text.isNotEmpty) {
          elements.add(TextElement(text: text, style: TextStyleAttributes()));
        }
      }
    }
  }

  /// Парсит текстовый узел в список спанов с учетом форматирования
  static void _parseTextNode(dom.Node node, List<TextSpanDocument> spans, TextStyleAttributes parentStyle) {
    if (node is dom.Text) {
      final text = node.text ?? '';
      if (text.isNotEmpty) {
        spans.add(TextSpanDocument(text: text, style: parentStyle));
      }
    } else if (node is dom.Element) {
      // Обновляем стиль на основе текущего элемента
      var style = TextStyleAttributes(
        bold: parentStyle.bold,
        italic: parentStyle.italic,
        underline: parentStyle.underline,
        color: parentStyle.color,
        fontSize: parentStyle.fontSize,
        link: parentStyle.link,
        alignment: parentStyle.alignment,
      );

      // Обработка форматирования
      if (node.localName == 'b' || node.localName == 'strong') {
        style = style.copyWith(bold: true);
      }
      if (node.localName == 'i' || node.localName == 'em') {
        style = style.copyWith(italic: true);
      }
      if (node.localName == 'u') {
        style = style.copyWith(underline: true);
      }
      if (node.localName == 'a') {
        style = style.copyWith(link: node.attributes['href']);
      }

      // Обработка стилей из атрибутов
      String? nodeStyle = node.attributes['style'];
      if (nodeStyle != null) {
        if (nodeStyle.contains('font-weight: bold') || nodeStyle.contains('font-weight:bold')) {
          style = style.copyWith(bold: true);
        }
        if (nodeStyle.contains('font-style: italic') || nodeStyle.contains('font-style:italic')) {
          style = style.copyWith(italic: true);
        }
        if (nodeStyle.contains('text-decoration: underline') || nodeStyle.contains('text-decoration:underline')) {
          style = style.copyWith(underline: true);
        }

        // Извлечение цвета текста
        final colorRegex = RegExp(
          r'color: (#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}|rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*(,\s*[0-9.]+\s*)?\))',
        );
        final colorMatch = colorRegex.firstMatch(nodeStyle);
        if (colorMatch != null && colorMatch.groupCount >= 1) {
          final colorStr = colorMatch.group(1) ?? '';
          style = style.copyWith(color: _parseColor(colorStr));
        }

        // Извлечение размера шрифта
        final fontSizeRegex = RegExp(r'font-size: (\d+)px');
        final fontSizeMatch = fontSizeRegex.firstMatch(nodeStyle);
        if (fontSizeMatch != null && fontSizeMatch.groupCount >= 1) {
          final fontSize = double.tryParse(fontSizeMatch.group(1) ?? '');
          if (fontSize != null) {
            style = style.copyWith(fontSize: fontSize);
          }
        }
      }

      // Рекурсивная обработка дочерних узлов
      for (var child in node.nodes) {
        _parseTextNode(child, spans, style);
      }
    }
  }

  /// Преобразует DocumentModel обратно в HTML-строку
  static String convertToHtml(DocumentModel document) {
    String html = "";

    for (var element in document.elements) {
      if (element is TextElement) {
        if (element.text.isEmpty) continue;

        // Текст форматируется в зависимости от его стиля
        String formattedText = "";

        if (element.spans.isEmpty) {
          // Простой случай - один стиль для всего текста
          formattedText = _formatTextWithStyle(element.text, element.style);
        } else {
          // Сложный случай - разные стили для разных частей текста
          for (var span in element.spans) {
            formattedText += _formatTextWithStyle(span.text, span.style);
          }
        }

        // Оборачиваем текст в параграф с указанным выравниванием
        String textAlignment = 'left';
        if (element.style.alignment == TextAlign.center)
          textAlignment = 'center';
        else if (element.style.alignment == TextAlign.right)
          textAlignment = 'right';
        else if (element.style.alignment == TextAlign.justify)
          textAlignment = 'justify';

        html += '<p style="text-align: $textAlignment;">$formattedText</p>';
      } else if (element is ImageElement) {
        // Формируем HTML для изображения
        String imgStyle = '';

        // Добавляем стили в зависимости от выравнивания
        if (element.alignment == Alignment.centerLeft) {
          imgStyle = 'float: left; margin-right: 16px; margin-bottom: 8px;';
        } else if (element.alignment == Alignment.centerRight) {
          imgStyle = 'float: right; margin-left: 16px; margin-bottom: 8px;';
        } else {
          imgStyle = 'display: block; margin: 0 auto;';
        }

        // Добавляем ширину
        imgStyle += ' width: ${element.width}px;';

        // Формируем HTML с изображением
        html += '<img src="${element.imageUrl}" style="$imgStyle" alt="${element.caption}">';

        // Если есть подпись, добавляем ее
        if (element.caption.isNotEmpty) {
          html += '<figcaption style="text-align: center;">${element.caption}</figcaption>';
        }
      }
    }

    return html;
  }

  /// Форматирует текст в соответствии со стилем
  static String _formatTextWithStyle(String text, TextStyleAttributes style) {
    if (text.isEmpty) return "";

    String formattedText = text;

    // Применяем стили в обратном порядке (от внутренних к внешним)

    // Ссылки
    if (style.link != null && style.link!.isNotEmpty) {
      formattedText = '<a href="${style.link}" style="color: #0066cc; text-decoration: underline;">$formattedText</a>';
    }

    // Подчеркивание
    if (style.underline && style.link == null) {
      formattedText = '<u>$formattedText</u>';
    }

    // Курсив
    if (style.italic) {
      formattedText = '<i>$formattedText</i>';
    }

    // Жирный текст
    if (style.bold) {
      formattedText = '<b>$formattedText</b>';
    }

    // Цвет текста, если отличается от черного
    if (style.color != null && style.color != Colors.black) {
      formattedText = '<span style="color: ${_colorToHex(style.color!)};">$formattedText</span>';
    }

    // Размер текста, если задан
    if (style.fontSize != 16) {
      // 16 - размер по умолчанию
      formattedText = '<span style="font-size: ${style.fontSize}px;">$formattedText</span>';
    }

    return formattedText;
  }

  /// Преобразует строку с цветом в объект Color
  static Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      // Hex color
      String hex = colorStr.replaceFirst('#', '');
      if (hex.length == 3) {
        // Convert 3-digit hex to 6-digit
        hex = hex.split('').map((c) => c + c).join('');
      }

      int colorValue = int.parse(hex, radix: 16);
      return Color(colorValue | 0xFF000000); // Add alpha
    } else if (colorStr.startsWith('rgb')) {
      // RGB color
      final rgbRegex = RegExp(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([0-9.]+)\s*)?\)');
      final match = rgbRegex.firstMatch(colorStr);

      if (match != null) {
        int red = int.parse(match.group(1) ?? '0');
        int green = int.parse(match.group(2) ?? '0');
        int blue = int.parse(match.group(3) ?? '0');
        double alpha = 1.0;

        if (match.groupCount >= 4 && match.group(4) != null) {
          alpha = double.tryParse(match.group(4) ?? '1.0') ?? 1.0;
        }

        return Color.fromRGBO(red, green, blue, alpha);
      }
    }

    return Colors.black; // Default color
  }

  /// Преобразует Color в строку Hex
  static String _colorToHex(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}';
  }
}
