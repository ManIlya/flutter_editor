import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:float_column/float_column.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/document_model.dart' as doc;
import '../theme/editor_theme.dart';

/// Виджет для отображения документа без возможности редактирования
class DocumentViewer extends StatelessWidget {
  final doc.DocumentModel document;
  final bool enableLogging;
  final bool enableFirstLineIndent; // Добавляем параметр для управления отступами
  /// Колбек для обработки нажатия на изображение
  final Function(String imageUrl, doc.ImageElement imageElement)? onImageTap;

  /// Флаг отключения обтекания текстом на узких экранах
  final bool disableFloatOnNarrowScreens;

  /// Ширина экрана, при которой считаем его узким (в пикселях)
  final double narrowScreenThreshold;

  const DocumentViewer({
    super.key,
    required this.document,
    this.enableLogging = false,
    this.enableFirstLineIndent = true, // По умолчанию отступы включены
    this.onImageTap,
    this.disableFloatOnNarrowScreens = true, // По умолчанию отключаем float на узких экранах
    this.narrowScreenThreshold = 600, // По умолчанию считаем узким экран уже 600px
  });

  @override
  Widget build(BuildContext context) {
    final editorTheme = EditorThemeExtension.of(context);

    return Container(
      decoration: BoxDecoration(
        color: editorTheme.backgroundColor,
        // Удаляем border, чтобы убрать рамку
        // border: Border.all(color: editorTheme.borderColor),
        borderRadius: editorTheme.containerBorderRadius,
        // Также убираем тень, чтобы улучшить вид без рамки
        // boxShadow: [editorTheme.containerShadow],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => FloatColumn(children: _buildDocumentElements(context, constraints)),
      ),
    );
  }

  /// Создает отступ для строки текста
  InlineSpan _createIndentSpan() {
    return WidgetSpan(
      child: SizedBox(width: 20.0), // Отступ в 20 пикселей
    );
  }

  /// Обрабатывает текст с учетом переносов строк и отступов
  List<InlineSpan> _processTextWithIndents(TextSpan span) {
    // Разбиваем текст на строки, сохраняя двойные переносы
    final lines = (span.text ?? '').split('\n\n');
    final List<InlineSpan> result = [];

    for (int i = 0; i < lines.length; i++) {
      // Добавляем двойной перенос строки для всех параграфов кроме первого
      if (i > 0) {
        result.add(const TextSpan(text: '\n\n'));
      }

      // Разбиваем параграф на строки
      final paragraphLines = lines[i].split('\n');

      for (int j = 0; j < paragraphLines.length; j++) {
        // Добавляем одиночный перенос строки для всех строк кроме первой в параграфе
        if (j > 0) {
          result.add(const TextSpan(text: '\n\n')); // Добавляем двойной перенос для одиночных \n
        }

        // Добавляем отступ только для первой строки параграфа
        if (j == 0 && enableFirstLineIndent) {
          result.add(_createIndentSpan());
        }

        // Добавляем текст строки
        result.add(TextSpan(text: paragraphLines[j], style: span.style, recognizer: span.recognizer));
      }
    }

    return result;
  }

  /// Создает элементы документа для отображения
  List<Widget> _buildDocumentElements(BuildContext context, BoxConstraints constraints) {
    final List<Widget> elements = [];
    final editorTheme = EditorThemeExtension.of(context);
    final bool isNarrowScreen = disableFloatOnNarrowScreens && constraints.maxWidth < narrowScreenThreshold;

    for (int i = 0; i < document.elements.length; i++) {
      final element = document.elements[i];

      if (element is doc.TextElement) {
        if (enableLogging) print('DocumentViewer: Отображение TextElement $i: spans=${element.spans.length}');

        // Получаем выравнивание текста из первого спана
        final TextAlign textAlignment = element.spans.isNotEmpty ? element.spans[0].style.alignment : TextAlign.left;

        if (enableLogging) print('DocumentViewer: Выравнивание текста: $textAlignment');

        final List<InlineSpan> textSpans = [];

        // Обрабатываем все спаны как единый параграф
        if (element.spans.isNotEmpty) {
          // Группируем спаны по абзацам
          final List<List<doc.TextSpanDocument>> paragraphs = [];
          List<doc.TextSpanDocument> currentParagraph = [];

          for (int j = 0; j < element.spans.length; j++) {
            final span = element.spans[j];
            final parts = span.text.split('\n');

            // Добавляем первую часть в текущий абзац
            if (parts[0].isNotEmpty) {
              currentParagraph.add(doc.TextSpanDocument(
                text: parts[0],
                style: span.style,
              ));
            }

            // Если есть переносы строк, создаем новые абзацы
            for (int k = 1; k < parts.length; k++) {
              if (currentParagraph.isNotEmpty) {
                paragraphs.add(List.from(currentParagraph));
                currentParagraph = [];
              }
              if (parts[k].isNotEmpty) {
                currentParagraph.add(doc.TextSpanDocument(
                  text: parts[k],
                  style: span.style,
                ));
              }
            }
          }

          // Добавляем последний абзац, если он не пустой
          if (currentParagraph.isNotEmpty) {
            paragraphs.add(currentParagraph);
          }

          // Добавляем абзацы с отступами
          for (int j = 0; j < paragraphs.length; j++) {
            // Добавляем отступ в начале абзаца
            if (enableFirstLineIndent) {
              textSpans.add(_createIndentSpan());
            }

            // Добавляем все спаны абзаца
            for (final span in paragraphs[j]) {
              textSpans.add(
                TextSpan(
                  text: span.text,
                  style: _convertToTextStyle(context, span.style),
                  recognizer: span.style.link != null
                      ? (TapGestureRecognizer()
                        ..onTap = () {
                          _handleLinkTap(span.style.link!);
                        })
                      : null,
                ),
              );
            }

            // Добавляем перенос строки, если это не последний абзац
            if (j < paragraphs.length - 1) {
              textSpans.add(const TextSpan(text: '\n\n'));
            }
          }
        }

        // Добавляем Text.rich с примененным выравниванием
        elements.add(
          Text.rich(
            TextSpan(
              children: textSpans..add(TextSpan(text: '\n')),
            ),
            textAlign: textAlignment,
          ),
        );
      } else if (element is doc.ImageElement) {
        // Определяем float на основе выравнивания
        FCFloat float;
        if (element.alignment == Alignment.centerLeft)
          float = isNarrowScreen ? FCFloat.none : FCFloat.start;
        else if (element.alignment == Alignment.centerRight)
          float = isNarrowScreen ? FCFloat.none : FCFloat.end;
        else
          float = FCFloat.none;

        // Определяем отступы в зависимости от положения
        EdgeInsets padding;
        if (float == FCFloat.start) {
          padding = EdgeInsets.only(right: editorTheme.elementSpacing, bottom: editorTheme.elementSpacing);
        } else if (float == FCFloat.end) {
          padding = EdgeInsets.only(left: editorTheme.elementSpacing, bottom: editorTheme.elementSpacing);
        } else {
          padding = EdgeInsets.only(bottom: editorTheme.elementSpacing);
        }

        // Добавляем изображение как Floatable
        final percentSize = _calculateMaxWidthPercentage(element, float, isNarrowScreen);
        final pictureSize = constraints.maxWidth * percentSize;

        // Создаем виджет в зависимости от типа float
        Widget imageWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Изображение обернутое в InkWell для обработки нажатия
            InkWell(
              onTap: onImageTap != null ? () => onImageTap!(element.imageUrl, element) : null,
              child: CachedNetworkImage(
                imageUrl: element.imageUrl,
                width: pictureSize,
                fit: BoxFit.fitWidth,
                // height: element.height,
                placeholder: (context, url) => Container(
                  width: pictureSize,
                  // height: element.height,
                  color: editorTheme.placeholderColor,
                  child: Center(child: CircularProgressIndicator(color: editorTheme.toolbarIconColor)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: pictureSize,
                  // height: element.height,
                  color: editorTheme.placeholderColor,
                  child: Icon(Icons.error, color: editorTheme.toolbarIconColor),
                ),
              ),
            ),

            // Подпись к изображению
            if (element.caption.isNotEmpty)
              Container(
                width: element.width, // Устанавливаем ширину контейнера равной ширине изображения
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(element.caption, style: editorTheme.captionTextStyle, textAlign: TextAlign.center),
              ),
          ],
        );

        // Если float == none, оборачиваем в Center для выравнивания по центру
        if (float == FCFloat.none) {
          imageWidget = Center(child: imageWidget);
        }

        elements.add(
          Floatable(
            float: float,
            padding: padding,
            // Устанавливаем максимальную ширину для обтекания текстом в зависимости от типа размера изображения
            maxWidthPercentage: percentSize,
            child: imageWidget,
          ),
        );

        // Если у изображения есть текстовый параграф, добавляем его
        if (element.paragraphText != null && element.paragraphText!.isNotEmpty) {
          elements.add(
            Padding(
              padding: EdgeInsets.only(bottom: editorTheme.elementSpacing),
              child: Text(element.paragraphText!, style: editorTheme.defaultTextStyle),
            ),
          );
        }
      }
    }

    return elements;
  }

  // Обработчик тапа по ссылке
  void _handleLinkTap(String url) {
    if (enableLogging) print('Открытие ссылки в просмотрщике: $url');

    // Преобразуем строку в Uri
    final Uri uri = Uri.parse(url);

    // Открываем URL через url_launcher
    launchUrl(uri, mode: LaunchMode.externalApplication).then((success) {
      if (!success) {
        if (enableLogging) print('Не удалось открыть ссылку: $url');
      }
    }).catchError((error) {
      if (enableLogging) print('Ошибка при открытии ссылки: $error');
    });
  }

  /// Преобразует TextStyleAttributes в TextStyle Flutter
  TextStyle _convertToTextStyle(BuildContext context, doc.TextStyleAttributes attributes) {
    final editorTheme = EditorThemeExtension.of(context);

    // Определяем базовый стиль на основе размера шрифта и жирности
    TextStyle baseStyle;

    // Проверяем, соответствует ли стиль заголовку из темы
    if (attributes.fontSize == (editorTheme.titleTextStyle.fontSize ?? 24) &&
        attributes.bold == (editorTheme.titleTextStyle.fontWeight == FontWeight.bold)) {
      // Используем стиль заголовка как базовый
      baseStyle = editorTheme.titleTextStyle;
    }
    // Проверяем, соответствует ли стиль подзаголовку из темы
    else if (attributes.fontSize == (editorTheme.subtitleTextStyle.fontSize ?? 22) &&
        attributes.bold == (editorTheme.subtitleTextStyle.fontWeight == FontWeight.bold)) {
      // Используем стиль подзаголовка как базовый
      baseStyle = editorTheme.subtitleTextStyle;
    }
    // В остальных случаях используем дефолтный стиль
    else {
      baseStyle = editorTheme.defaultTextStyle;
    }

    // Применяем дополнительные атрибуты стиля
    return baseStyle.copyWith(
      fontWeight: attributes.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: attributes.italic ? FontStyle.italic : FontStyle.normal,
      decoration: attributes.link != null
          ? TextDecoration.underline
          : (attributes.underline ? TextDecoration.underline : TextDecoration.none),
      decorationColor: attributes.link != null ? editorTheme.linkColor : null,
      decorationThickness: attributes.link != null ? 2.0 : 1.0,
      color: attributes.link != null
          ? editorTheme.linkColor
          : (attributes.color != Colors.black ? attributes.color : baseStyle.color),
      fontSize: attributes.fontSize != baseStyle.fontSize ? attributes.fontSize : baseStyle.fontSize,
    );
  }

  // Рассчитывает maxWidthPercentage для Floatable в зависимости от типа размера изображения
  double _calculateMaxWidthPercentage(doc.ImageElement imageElement, FCFloat float, bool isNarrowScreen) {
    // Если экран узкий и включена соответствующая опция, используем полную ширину
    if (isNarrowScreen) {
      return 1.0;
    }

    // Для процента от экрана используем точное значение, указанное пользователем
    // Преобразуем процент (0-100) в долю (0.0-1.0)
    return imageElement.sizePercent / 100;
  }
}
