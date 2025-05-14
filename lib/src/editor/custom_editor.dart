import 'package:flutter/material.dart';
import 'package:float_column/float_column.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'dart:typed_data';
import 'package:flutter_editor/flutter_editor.dart';
import '../widgets/toolbar.dart';
import '../models/document_model.dart';
import '../widgets/text_editor.dart'; // Импортируем для доступа к StyledTextEditingController

/// Тип источника изображения
enum ImageSourceType {
  /// URL-ссылка на изображение
  link,

  /// Файл изображения с устройства
  file,
}

/// Функция для преобразования файла в URL
typedef FileToUrlConverter = Future<String?> Function(Uint8List fileData, String fileName);

class CustomEditor extends StatefulWidget {
  final DocumentModel initialDocument;
  final Function(DocumentModel)? onDocumentChanged;
  final bool enableLogging;

  /// Колбэк для преобразования файла изображения в URL
  /// Если не указан, будет использовано изображение по умолчанию
  final FileToUrlConverter? fileToUrlConverter;

  /// Список пользовательских иконок для панели инструментов
  final List<Widget>? customToolbarItems;

  /// Высота области редактирования в пикселях
  /// Если не указано (null), будет использована вся доступная высота
  final double? editorHeight;

  const CustomEditor({
    Key? key,
    required this.initialDocument,
    this.onDocumentChanged,
    this.enableLogging = false,
    this.fileToUrlConverter,
    this.customToolbarItems,
    this.editorHeight = 750,
  }) : super(key: key);

  @override
  State<CustomEditor> createState() => _CustomEditorState();
}

class _CustomEditorState extends State<CustomEditor> {
  late DocumentModel _document;
  final FocusNode _focusNode = FocusNode();
  int? _selectedIndex;
  TextSelection? _selection;
  // Текущее положение float для изображения
  FCFloat _currentImageFloat = FCFloat.start;

  @override
  void initState() {
    super.initState();
    _document = widget.initialDocument.copy();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _addImage() async {
    // Показываем диалог выбора источника изображения
    final selectedSource = await _showImageSourceDialog();
    if (selectedSource == null) return;

    String? imageUrl;

    if (selectedSource == ImageSourceType.file) {
      // Выбираем изображение из галереи
      final picker.ImagePicker imagePicker = picker.ImagePicker();
      final picker.XFile? imageFile = await imagePicker.pickImage(source: picker.ImageSource.gallery);

      if (imageFile == null) return;

      // Если есть конвертер файла в URL, используем его
      if (widget.fileToUrlConverter != null) {
        // Читаем содержимое файла
        final Uint8List fileData = await imageFile.readAsBytes();
        // Передаем содержимое и имя файла в колбэк
        imageUrl = await widget.fileToUrlConverter!(fileData, imageFile.name);
      }

      // Если URL не получен, используем заглушку
      if (imageUrl == null) {
        if (widget.enableLogging) print('URL изображения не получен, используем заглушку');
        imageUrl = 'https://storage.yandexcloud.net/vrnm/aad3dc7c4ebeed752ec109_800.jpg';
      }
    } else {
      // Показываем диалог ввода URL
      imageUrl = await _showImageUrlDialog();
      if (imageUrl == null || imageUrl.isEmpty) return;
    }

    // Создаем элемент изображения
    final imageElement = ImageElement(
      imageUrl: imageUrl,
      caption: '',
      alignment: Alignment.center,
      sizePercent: 40.0, // 50% от ширины экрана по умолчанию
      sizeType: 'screen', // Всегда используем процент от экрана
    );

    setState(() {
      _document.addElement(imageElement);
      _selectedIndex = _document.elements.length - 1;
      _notifyDocumentChanged();
    });
  }

  // Показывает диалог выбора источника изображения
  Future<ImageSourceType?> _showImageSourceDialog() async {
    return await showDialog<ImageSourceType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить изображение'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Вставить ссылку'),
                onTap: () => Navigator.of(context).pop(ImageSourceType.link),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.of(context).pop(ImageSourceType.file),
              ),
            ],
          ),
        );
      },
    );
  }

  // Показывает диалог ввода URL изображения
  Future<String?> _showImageUrlDialog() async {
    final TextEditingController controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Вставить ссылку на изображение'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'https://example.com/image.jpg', labelText: 'URL изображения'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Добавить')),
          ],
        );
      },
    );
  }

  void _updateTextElement(int index, String newText) {
    if (index >= 0 && index < _document.elements.length) {
      if (_document.elements[index] is TextElement) {
        final textElement = _document.elements[index] as TextElement;

        if (widget.enableLogging) {
          print('════════════════════════════════════════════');
          print('🔄 ОБНОВЛЕНИЕ ТЕКСТА:');
          print('Старый текст: "${StyledTextEditingController.formatSpanText(textElement.text)}"');
          print('Новый текст: "${StyledTextEditingController.formatSpanText(newText)}"');
        }

        // Логируем структуру спанов до обновления
        if (widget.enableLogging) {
          print('СТРУКТУРА СПАНОВ ДО ОБНОВЛЕНИЯ:');
          int currentPos = 0;
          for (int i = 0; i < textElement.spans.length; i++) {
            final span = textElement.spans[i];
            final spanStart = currentPos;
            final spanEnd = currentPos + span.text.length;

            final bool isBold = span.style.bold;
            final bool isItalic = span.style.italic;
            final bool isUnderline = span.style.underline;
            final String styleMarkers = [if (isBold) 'Ж', if (isItalic) 'К', if (isUnderline) 'П'].join('');

            // Обрабатываем длинные спаны для компактного отображения
            String displayText = StyledTextEditingController.formatSpanText(span.text);

            print('Спан #$i [$spanStart-$spanEnd]: ${styleMarkers.isNotEmpty ? "[$styleMarkers] " : ""}"$displayText"');
            currentPos = spanEnd;
          }
        }

        // Сохраняем текст для отложенного обновления
        final String updatedText = newText;

        // Отложенное обновление текстового элемента
        Future.microtask(() {
          if (mounted) {
            if (_selection != null && _selection!.start != _selection!.end) {
              // Если есть активное выделение, обновляем текст с сохранением стилей
              if (widget.enableLogging)
                print('Обновление текста с активным выделением: ${_selection!.start}-${_selection!.end}');

              // Важно! TextEditor сам управляет форматированием текста
              // и передает только newText, но не spans
              if (textElement.text != updatedText) {
                textElement.text = updatedText;
              }
            } else {
              // Обычное обновление текста
              if (textElement.spans.length <= 1) {
                textElement.text = updatedText;
                if (widget.enableLogging) print('Обновлен текст элемента (один спан)');
              } else {
                if (widget.enableLogging) print('Обновление текста с сохранением структуры спанов...');
                _updateTextElementWithSpans(textElement, updatedText);
              }
            }

            // Логируем структуру спанов после обновления
            if (widget.enableLogging) {
              print('СТРУКТУРА СПАНОВ ПОСЛЕ ОБНОВЛЕНИЯ:');
              int posAfter = 0;
              for (int i = 0; i < textElement.spans.length; i++) {
                final span = textElement.spans[i];
                final spanStart = posAfter;
                final spanEnd = posAfter + span.text.length;

                final bool isBold = span.style.bold;
                final bool isItalic = span.style.italic;
                final bool isUnderline = span.style.underline;
                final String styleMarkers = [if (isBold) 'Ж', if (isItalic) 'К', if (isUnderline) 'П'].join('');

                // Обрабатываем длинные спаны для компактного отображения
                String displayText = StyledTextEditingController.formatSpanText(span.text);

                print(
                  'Спан #$i [$spanStart-$spanEnd]: ${styleMarkers.isNotEmpty ? "[$styleMarkers] " : ""}"$displayText"',
                );
                posAfter = spanEnd;
              }
              print('════════════════════════════════════════════');
            }

            // Единый вызов на обновление состояния
            if (mounted) {
              setState(() {
                // Все изменения стейта находятся внутри одного блока
              });

              // Отдельно уведомляем об изменении документа
              _notifyDocumentChanged();
            }
          }
        });
      }
    }
  }

  // Обновляет элемент изображения
  void _updateImageElement(int index, ImageElement newImageElement) {
    if (index >= 0 && index < _document.elements.length) {
      if (_document.elements[index] is ImageElement) {
        setState(() {
          _document.elements[index] = newImageElement;
          _notifyDocumentChanged();
        });
      }
    }
  }

  // Изменяет положение float для изображения
  void _changeImageFloat(FCFloat float) {
    setState(() {
      _currentImageFloat = float;
    });
  }

  // Обновляет текст, сохраняя стили в существующих спанах
  void _updateTextElementWithSpans(TextElement element, String newText) {
    final String oldText = element.text;

    if (widget.enableLogging) {
      print('════════════════════════════════════════════');
      print('🔄 ОБНОВЛЕНИЕ ТЕКСТА С СОХРАНЕНИЕМ СТИЛЕЙ:');
      print('Старый текст: "${StyledTextEditingController.formatSpanText(oldText)}"');
      print('Новый текст: "${StyledTextEditingController.formatSpanText(newText)}"');
    }

    // Если нет изменений, ничего не делаем
    if (oldText == newText) {
      if (widget.enableLogging) print('Текст не изменился, выходим без изменений.');
      return;
    }

    // Определяем тип изменения (добавление или удаление текста)
    final isAddition = newText.length > oldText.length;
    final isDeletion = newText.length < oldText.length;

    // Используем алгоритм наибольшей общей подпоследовательности для определения
    // позиции изменения, но это упрощенная версия
    int commonPrefixLength = 0;
    int minLength = min(oldText.length, newText.length);

    // Ищем общий префикс
    while (commonPrefixLength < minLength && oldText[commonPrefixLength] == newText[commonPrefixLength]) {
      commonPrefixLength++;
    }

    if (widget.enableLogging) print('Найден общий префикс длиной $commonPrefixLength символов');

    // Если у нас добавление текста
    if (isAddition) {
      if (widget.enableLogging) print('➕ Обнаружено добавление текста');

      // Позиция, где был добавлен новый текст
      final insertPosition = commonPrefixLength;
      final addedLength = newText.length - oldText.length;
      final addedText = newText.substring(insertPosition, insertPosition + addedLength);

      if (widget.enableLogging) print('Позиция вставки: $insertPosition');
      if (widget.enableLogging) print('Добавленный текст: "${StyledTextEditingController.formatSpanText(addedText)}"');

      // Создаем новые спаны
      List<TextSpanDocument> newSpans = [];
      int currentPos = 0;

      for (int i = 0; i < element.spans.length; i++) {
        final span = element.spans[i];
        final spanStart = currentPos;
        final spanEnd = currentPos + span.text.length;

        if (widget.enableLogging)
          print(
              'Анализ спана #$i: "${StyledTextEditingController.formatSpanText(span.text)}" позиция [$spanStart-$spanEnd]');

        // Если вставка произошла внутри этого спана
        if (insertPosition >= spanStart && insertPosition <= spanEnd) {
          if (widget.enableLogging) print('Вставка произошла в спане #$i');

          // Текст до вставки
          if (insertPosition > spanStart) {
            final beforeText = span.text.substring(0, insertPosition - spanStart);
            newSpans.add(TextSpanDocument(text: beforeText, style: span.style));
            if (widget.enableLogging)
              print(
                  'Добавлен текст до вставки: "${StyledTextEditingController.formatSpanText(beforeText)}" (тот же стиль)');
          }

          // Добавленный текст (с тем же стилем, что и спан, где произошла вставка)
          newSpans.add(TextSpanDocument(text: addedText, style: span.style));
          if (widget.enableLogging)
            print(
                'Добавлен новый текст: "${StyledTextEditingController.formatSpanText(addedText)}" (стиль: bold=${span.style.bold}, italic=${span.style.italic})');

          // Текст после вставки
          if (insertPosition - spanStart < span.text.length) {
            final afterText = span.text.substring(insertPosition - spanStart);
            newSpans.add(TextSpanDocument(text: afterText, style: span.style));
            if (widget.enableLogging)
              print(
                  'Добавлен текст после вставки: "${StyledTextEditingController.formatSpanText(afterText)}" (тот же стиль)');
          }
        }
        // Если спан полностью до места вставки
        else if (spanEnd <= insertPosition) {
          newSpans.add(span);
          if (widget.enableLogging) print('Спан до места вставки, добавлен без изменений');
        }
        // Если спан полностью после места вставки
        else {
          final textAfterInsert = span.text;
          newSpans.add(TextSpanDocument(text: textAfterInsert, style: span.style));
          if (widget.enableLogging)
            print(
                'Спан после места вставки, добавлен с текстом: "${StyledTextEditingController.formatSpanText(textAfterInsert)}"');
        }

        currentPos = spanEnd;
      }

      // Проверяем, что мы создали хотя бы один спан
      if (newSpans.isEmpty) {
        if (widget.enableLogging) print('Не удалось создать спаны, используем стиль первого спана для всего текста');
        final style = element.spans.isNotEmpty ? element.spans[0].style : TextStyleAttributes();
        element.spans = [TextSpanDocument(text: newText, style: style)];
      } else {
        // Объединяем соседние спаны с одинаковыми стилями для оптимизации
        element.spans = _mergeAdjacentSpans(newSpans);
        if (widget.enableLogging) print('Созданы новые спаны с сохранением форматирования (${element.spans.length})');
      }
    }
    // Если у нас удаление текста
    else if (isDeletion) {
      if (widget.enableLogging) print('➖ Обнаружено удаление текста');

      // Ищем общий суффикс
      int commonSuffixLength = 0;
      while (commonSuffixLength < minLength &&
          oldText[oldText.length - 1 - commonSuffixLength] == newText[newText.length - 1 - commonSuffixLength]) {
        commonSuffixLength++;
      }

      // Определяем положение удаления
      final deleteStart = commonPrefixLength;
      final deleteEnd = oldText.length - commonSuffixLength;
      final deletedText = oldText.substring(deleteStart, deleteEnd);

      if (widget.enableLogging) print('Позиция удаления: $deleteStart-$deleteEnd');
      if (widget.enableLogging) print('Удаленный текст: "${StyledTextEditingController.formatSpanText(deletedText)}"');

      // Строим новые спаны с учетом удаления
      List<TextSpanDocument> newSpans = [];
      int currentPos = 0;

      for (int i = 0; i < element.spans.length; i++) {
        final span = element.spans[i];
        final spanStart = currentPos;
        final spanEnd = currentPos + span.text.length;

        if (widget.enableLogging)
          print(
              'Анализ спана #$i: "${StyledTextEditingController.formatSpanText(span.text)}" позиция [$spanStart-$spanEnd]');

        // Спан полностью до удаления
        if (spanEnd <= deleteStart) {
          newSpans.add(span);
          if (widget.enableLogging) print('Спан до удаления, добавлен без изменений');
        }
        // Спан полностью после удаления
        else if (spanStart >= deleteEnd) {
          // Корректируем позицию для нового текста
          final newSpanStart = spanStart - (deleteEnd - deleteStart);
          final newText = span.text;
          newSpans.add(TextSpanDocument(text: newText, style: span.style));
          if (widget.enableLogging)
            print('Спан после удаления, добавлен с текстом: "${StyledTextEditingController.formatSpanText(newText)}"');
        }
        // Спан пересекается с удалением
        else {
          // Часть до удаления
          if (spanStart < deleteStart) {
            final beforeText = span.text.substring(0, deleteStart - spanStart);
            newSpans.add(TextSpanDocument(text: beforeText, style: span.style));
            if (widget.enableLogging)
              print('Добавлена часть спана до удаления: "${StyledTextEditingController.formatSpanText(beforeText)}"');
          }

          // Часть после удаления
          if (spanEnd > deleteEnd) {
            final afterText = span.text.substring(deleteEnd - spanStart);
            newSpans.add(TextSpanDocument(text: afterText, style: span.style));
            if (widget.enableLogging)
              print('Добавлена часть спана после удаления: "${StyledTextEditingController.formatSpanText(afterText)}"');
          }
        }

        currentPos = spanEnd;
      }

      // Проверяем, что мы создали хотя бы один спан
      if (newSpans.isEmpty) {
        if (widget.enableLogging) print('Не удалось создать спаны, используем стиль первого спана для всего текста');
        final style = element.spans.isNotEmpty ? element.spans[0].style : TextStyleAttributes();
        element.spans = [TextSpanDocument(text: newText, style: style)];
      } else {
        // Объединяем соседние спаны с одинаковыми стилями для оптимизации
        element.spans = _mergeAdjacentSpans(newSpans);
        if (widget.enableLogging) print('Созданы новые спаны с сохранением форматирования (${element.spans.length})');
      }
    }
    // В редких случаях, когда мы не можем точно определить изменение
    else {
      if (widget.enableLogging) print('⚠️ Не удалось определить точный тип изменения');

      // Сохраняем хотя бы текст
      element.text = newText;
    }

    if (widget.enableLogging) print('════════════════════════════════════════════');
  }

  // Объединяет соседние спаны с одинаковыми стилями для оптимизации
  List<TextSpanDocument> _mergeAdjacentSpans(List<TextSpanDocument> spans) {
    if (spans.length <= 1) return spans;

    if (widget.enableLogging) print('Объединение соседних спанов с одинаковыми стилями...');
    final result = <TextSpanDocument>[];
    TextSpanDocument? currentSpan;

    for (final span in spans) {
      if (currentSpan == null) {
        currentSpan = span;
      } else if (_areStylesEqual(currentSpan.style, span.style)) {
        // Если стили одинаковые, объединяем текст
        currentSpan = TextSpanDocument(text: currentSpan.text + span.text, style: currentSpan.style);
        if (widget.enableLogging)
          print(
              'Объединены спаны с одинаковыми стилями: "${StyledTextEditingController.formatSpanText(currentSpan.text)}"');
      } else {
        // Если стили разные, добавляем текущий спан и начинаем новый
        result.add(currentSpan);
        currentSpan = span;
      }
    }

    // Добавляем последний спан
    if (currentSpan != null) {
      result.add(currentSpan);
    }

    if (widget.enableLogging) print('После объединения: было ${spans.length} спанов, стало ${result.length}');
    return result;
  }

  // Проверяет, равны ли стили двух спанов
  bool _areStylesEqual(TextStyleAttributes a, TextStyleAttributes b) {
    return a.bold == b.bold &&
        a.italic == b.italic &&
        a.underline == b.underline &&
        a.color == b.color &&
        a.link == b.link &&
        a.alignment == b.alignment;
  }

  void _addNewTextElement() {
    final newTextElement = TextElement(text: '');
    setState(() {
      _document.addElement(newTextElement);
      _selectedIndex = _document.elements.length - 1;
      _notifyDocumentChanged();
    });
  }

  // Удаляет элемент документа по индексу
  void _removeElement(int index) {
    if (index < 0 || index >= _document.elements.length) return;

    setState(() {
      // Запоминаем тип удаляемого элемента для логирования
      final elementType = _document.elements[index] is TextElement ? 'текстовый блок' : 'изображение';
      if (widget.enableLogging) print('Удаляем $elementType с индексом $index');

      // Удаляем элемент из документа
      _document.elements.removeAt(index);

      // Очищаем выделение, если был выбран удаляемый элемент
      if (_selectedIndex == index) {
        _selectedIndex = null;
        _selection = null;
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        // Если был выбран элемент после удаляемого, корректируем его индекс
        _selectedIndex = _selectedIndex! - 1;
      }

      // Уведомляем об изменении документа
      _notifyDocumentChanged();
    });
  }

  // Уведомляем о изменении документа с небольшой задержкой
  void _notifyDocumentChanged() {
    Future.microtask(() {
      if (mounted) {
        widget.onDocumentChanged?.call(_document);
      }
    });
  }

  // Обработка изменения выделения текста
  void _handleSelectionChanged(TextSelection selection) {
    if (_selection?.start != selection.start || _selection?.end != selection.end) {
      setState(() {
        _selection = selection;

        // Отладочная информация о выделении
        if (widget.enableLogging) print('Выделение: start=${selection.start}, end=${selection.end}');

        // Проверим, действительно ли это выделение (не просто курсор)
        if (selection.start != selection.end && _selectedIndex != null) {
          if (widget.enableLogging) print('Текст выделен от ${selection.start} до ${selection.end}');

          // Проверим стиль текущего выделения для отладки
          if (_document.elements[_selectedIndex!] is TextElement) {
            final textElement = _document.elements[_selectedIndex!] as TextElement;
            final style = textElement.styleAt(selection.start);
            if (widget.enableLogging)
              print(
                'Стиль выделенного текста: bold=${style?.bold}, italic=${style?.italic}, underline=${style?.underline}',
              );
          }
        }
      });
    }
  }

  // Обрабатывает тап по элементу изображения
  void _handleImageTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Обрабатывает тап по параграфу изображения
  void _handleParagraphTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Применяет форматирование к выделенному тексту
  void _applyFormatting(TextStyleAttributes Function(TextStyleAttributes) styleUpdater) {
    if (_selection == null || _selection!.start == _selection!.end || _selectedIndex == null) {
      return;
    }

    if (_document.elements[_selectedIndex!] is TextElement) {
      // Применяем стиль к текстовому элементу
      final textElement = _document.elements[_selectedIndex!] as TextElement;
      final currentStyle = textElement.styleAt(_selection!.start) ?? textElement.style;
      final newStyle = styleUpdater(currentStyle);

      setState(() {
        textElement.applyStyle(newStyle, _selection!.start, _selection!.end);
        _notifyDocumentChanged();
      });
    }
  }

  // Сбрасывает форматирование выделенного текста
  void _clearFormatting() {
    if (_selection == null || _selection!.start == _selection!.end || _selectedIndex == null) {
      return;
    }

    if (_document.elements[_selectedIndex!] is TextElement) {
      final textElement = _document.elements[_selectedIndex!] as TextElement;

      if (widget.enableLogging) {
        print('════════════════════════════════════════════');
        print('🧹 СБРОС ФОРМАТИРОВАНИЯ:');
        print('Диапазон: ${_selection!.start}-${_selection!.end}');
      }

      // Создаем стиль без форматирования
      final plainStyle = TextStyleAttributes(bold: false, italic: false, underline: false, link: null);

      if (widget.enableLogging) print('Новый стиль: bold=false, italic=false, underline=false, link=null');

      setState(() {
        textElement.applyStyle(plainStyle, _selection!.start, _selection!.end);
        _notifyDocumentChanged();

        if (widget.enableLogging) print('Форматирование сброшено.');
        if (widget.enableLogging) print('════════════════════════════════════════════');
      });
    }
  }

  /// Создает контекст выделения для EditorToolbar
  EditorSelectionContext _buildSelectionContext() {
    if (_selectedIndex == null) {
      return const EditorSelectionContext(type: SelectedElementType.none);
    }

    if (_selectedIndex! >= 0 && _selectedIndex! < _document.elements.length) {
      final element = _document.elements[_selectedIndex!];

      if (element is TextElement) {
        return EditorSelectionContext(
          type: SelectedElementType.text,
          elementIndex: _selectedIndex,
          textElement: element,
          textSelection: _selection,
        );
      } else if (element is ImageElement) {
        return EditorSelectionContext(
          type: SelectedElementType.image,
          elementIndex: _selectedIndex,
          imageElement: element,
        );
      }
    }

    return const EditorSelectionContext(type: SelectedElementType.none);
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme = EditorThemeExtension.of(context);

    // Создаем содержимое редактора
    final editorContent = Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: editorTheme.toolbarColor,
            borderRadius: BorderRadius.circular(editorTheme.borderRadius),
            border: Border.all(color: editorTheme.borderColor),
          ),
          child: EditorToolbar(
            onBoldPressed: () => _applyFormatting((style) => style.copyWith(bold: !style.bold)),
            onItalicPressed: () => _applyFormatting((style) => style.copyWith(italic: !style.italic)),
            onUnderlinePressed: () => _applyFormatting((style) => style.copyWith(underline: !style.underline)),
            onClearFormattingPressed: _clearFormatting,
            onAddImagePressed: _addImage,
            onAddTextPressed: _addNewTextElement,
            customToolbarItems: widget.customToolbarItems,
            selectionContext: _buildSelectionContext(),
          ),
        ),
        if (_selectedIndex != null && _document.elements[_selectedIndex!] is ImageElement) _buildImageFloatToolbar(),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: EdgeInsets.all(editorTheme.elementSpacing),
            decoration: BoxDecoration(
              color: editorTheme.backgroundColor,
              border: Border.all(color: editorTheme.borderColor),
              borderRadius: editorTheme.containerBorderRadius,
              boxShadow: [editorTheme.containerShadow],
            ),
            child: _buildReorderableDocumentView(),
          ),
        ),
      ],
    );

    // Если указана высота, оборачиваем весь редактор в контейнер с указанной высотой
    if (widget.editorHeight != null) {
      return SizedBox(height: widget.editorHeight, child: editorContent);
    } else {
      // Иначе возвращаем содержимое без ограничения высоты
      return editorContent;
    }
  }

  // Панель инструментов для управления положением изображения
  Widget _buildImageFloatToolbar() {
    final editorTheme = EditorThemeExtension.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: editorTheme.toolbarColor,
        borderRadius: BorderRadius.circular(editorTheme.borderRadius),
        border: Border.all(color: editorTheme.borderColor),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Положение изображения: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: editorTheme.defaultTextStyle.color),
          ),
          const SizedBox(width: 16),
          ToggleButtons(
            isSelected: [
              _currentImageFloat == FCFloat.start,
              _currentImageFloat == FCFloat.none,
              _currentImageFloat == FCFloat.end,
            ],
            onPressed: (index) {
              setState(() {
                if (index == 0)
                  _currentImageFloat = FCFloat.start;
                else if (index == 1)
                  _currentImageFloat = FCFloat.none;
                else if (index == 2) _currentImageFloat = FCFloat.end;

                // Обновляем положение текущего выбранного изображения
                if (_selectedIndex != null && _document.elements[_selectedIndex!] is ImageElement) {
                  final imageElement = _document.elements[_selectedIndex!] as ImageElement;

                  AlignmentGeometry alignment;
                  if (_currentImageFloat == FCFloat.start)
                    alignment = Alignment.centerLeft;
                  else if (_currentImageFloat == FCFloat.end)
                    alignment = Alignment.centerRight;
                  else
                    alignment = Alignment.center;

                  // Используем copyWith для сохранения всех свойств
                  _updateImageElement(_selectedIndex!, imageElement.copyWith(alignment: alignment));
                }
              });
            },
            borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
            selectedColor: editorTheme.toolbarSelectedIconColor,
            color: editorTheme.toolbarIconColor,
            fillColor: editorTheme.selectedBackgroundColor,
            children: const [
              Icon(Icons.format_align_left),
              Icon(Icons.format_align_center),
              Icon(Icons.format_align_right),
            ],
          ),
        ],
      ),
    );
  }

  // Создает перетаскиваемый список элементов документа
  Widget _buildReorderableDocumentView() {
    // Подготавливаем список виджетов для ReorderableListView
    final List<Widget> documentBlocks = [];

    for (int i = 0; i < _document.elements.length; i++) {
      final element = _document.elements[i];

      if (element is TextElement) {
        // Добавляем текстовый блок
        documentBlocks.add(_buildDraggableTextBlock(element, i));
      } else if (element is ImageElement) {
        // Добавляем блок изображения
        documentBlocks.add(_buildDraggableImageBlock(element, i));
      }
    }

    // Используем ScrollView вокруг ReorderableListView для корректной прокрутки
    return ReorderableListView.builder(
      buildDefaultDragHandles: false, // Отключаем скролл внутри ListView
      itemCount: documentBlocks.length,
      itemBuilder: (context, index) =>
          Container(key: ValueKey('$index'), padding: EdgeInsets.only(bottom: 16), child: documentBlocks[index]),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? _) {
            final double animValue = Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 8, animValue)!;
            final double scale = lerpDouble(1, 1.02, animValue)!;

            return Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Transform.scale(
                scale: scale,
                child: Material(
                  elevation: elevation,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                  child: documentBlocks[index],
                ),
              ),
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          // Корректируем индекс, если перемещаем вниз
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }

          // Перемещаем элемент в документе
          final item = _document.elements.removeAt(oldIndex);
          _document.elements.insert(newIndex, item);

          // Обновляем выделенный индекс, если он изменился
          if (_selectedIndex == oldIndex) {
            _selectedIndex = newIndex;
          } else if (_selectedIndex != null) {
            if (_selectedIndex! > oldIndex && _selectedIndex! <= newIndex) {
              _selectedIndex = _selectedIndex! - 1;
            } else if (_selectedIndex! < oldIndex && _selectedIndex! >= newIndex) {
              _selectedIndex = _selectedIndex! + 1;
            }
          }

          // Уведомляем о изменении документа
          _notifyDocumentChanged();
        });
      },
      footer: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Добавить блок текста'),
                onPressed: _addNewTextElement,
              ),
              const SizedBox(width: 16.0),
              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Добавить изображение'),
                onPressed: _addImage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Создает текстовый блок с возможностью перетаскивания
  Widget _buildDraggableTextBlock(TextElement element, int index) {
    final isSelected = _selectedIndex == index;

    return Container(
      key: ValueKey('text_$index'),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(4.0),
        color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.transparent,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0 + 8, right: 8.0, top: 8.0, bottom: 8.0),
            child: TextEditor(
              text: element.text,
              style: element.style,
              spans: element.spans,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              onTextChanged: (text) => _updateTextElement(index, text),
              onSpansChanged: (newSpans) {
                // Обновляем spans в TextElement напрямую
                if (index >= 0 && index < _document.elements.length && _document.elements[index] is TextElement) {
                  setState(() {
                    final textElement = _document.elements[index] as TextElement;
                    textElement.spans = newSpans;
                    _notifyDocumentChanged();
                  });
                }
              },
              onSelectionChanged: _handleSelectionChanged,
              onDelete: () => _removeElement(index),
              enableLogging: widget.enableLogging,
              onOverflow: _handleTextOverflow,
            ),
          ),
          // Рукоятка для перетаскивания
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 24.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3.0),
                    bottomLeft: Radius.circular(3.0),
                  ),
                ),
                child: Icon(
                  Icons.drag_handle,
                  size: 16.0,
                  color: isSelected ? Colors.blue.withOpacity(0.7) : Colors.grey.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Создает блок изображения с возможностью перетаскивания
  Widget _buildDraggableImageBlock(ImageElement element, int index) {
    final isSelected = _selectedIndex == index;

    // Определяем float на основе выравнивания
    FCFloat float;
    if (element.alignment == Alignment.centerLeft)
      float = FCFloat.start;
    else if (element.alignment == Alignment.centerRight)
      float = FCFloat.end;
    else
      float = FCFloat.none;

    // Определяем отступы в зависимости от положения
    EdgeInsets padding;
    if (float == FCFloat.start) {
      padding = const EdgeInsets.only(right: 16.0, bottom: 8.0);
    } else if (float == FCFloat.end) {
      padding = const EdgeInsets.only(left: 16.0, bottom: 8.0);
    } else {
      padding = const EdgeInsets.only(bottom: 8.0);
    }

    return Container(
      key: ValueKey('image_$index'),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(4.0),
        color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.transparent,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0 + 8, right: 8.0, top: 8.0, bottom: 8.0),
            child: Floatable(
              float: float,
              padding: padding,
              maxWidthPercentage: _calculateMaxWidthPercentage(element, float),
              child: float == FCFloat.none
                  ? Center(
                      child: ImageEditor(
                        imageElement: element,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;

                            // Обновляем текущий float для панели инструментов
                            if (element.alignment == Alignment.centerLeft)
                              _currentImageFloat = FCFloat.start;
                            else if (element.alignment == Alignment.centerRight)
                              _currentImageFloat = FCFloat.end;
                            else
                              _currentImageFloat = FCFloat.none;
                          });
                        },
                        onImageChanged: (newImage) => _updateImageElement(index, newImage),
                        onDelete: () => _removeElement(index),
                      ),
                    )
                  : ImageEditor(
                      imageElement: element,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;

                          // Обновляем текущий float для панели инструментов
                          if (element.alignment == Alignment.centerLeft)
                            _currentImageFloat = FCFloat.start;
                          else if (element.alignment == Alignment.centerRight)
                            _currentImageFloat = FCFloat.end;
                          else
                            _currentImageFloat = FCFloat.none;
                        });
                      },
                      onImageChanged: (newImage) => _updateImageElement(index, newImage),
                      onDelete: () => _removeElement(index),
                    ),
            ),
          ),
          // Рукоятка для перетаскивания
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 24.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3.0),
                    bottomLeft: Radius.circular(3.0),
                  ),
                ),
                child: Icon(
                  Icons.drag_handle,
                  size: 16.0,
                  color: isSelected ? Colors.blue.withOpacity(0.7) : Colors.grey.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDocumentElements() {
    final List<Widget> elements = [];
    final List<InlineSpan> spans = [];
    final editorTheme = EditorThemeExtension.of(context);

    bool hasActiveFloatable = false; // Флаг, показывающий, есть ли активный Floatable

    for (int i = 0; i < _document.elements.length; i++) {
      final element = _document.elements[i];

      if (element is TextElement) {
        // Добавляем текст как WidgetSpan
        spans.add(
          WidgetSpan(
            child: Container(
              margin: EdgeInsets.only(bottom: editorTheme.elementSpacing),
              child: TextEditor(
                key: ValueKey('text_$i'),
                text: element.text,
                style: element.style,
                spans: element.spans,
                isSelected: _selectedIndex == i,
                onTap: () {
                  setState(() {
                    _selectedIndex = i;
                  });
                },
                onTextChanged: (text) => _updateTextElement(i, text),
                onSpansChanged: (newSpans) {
                  // Обновляем spans в TextElement напрямую
                  if (i >= 0 && i < _document.elements.length && _document.elements[i] is TextElement) {
                    setState(() {
                      final textElement = _document.elements[i] as TextElement;
                      textElement.spans = newSpans;
                      _notifyDocumentChanged();
                    });
                  }
                },
                onSelectionChanged: _handleSelectionChanged,
                onDelete: () => _removeElement(i),
                enableLogging: widget.enableLogging,
                onOverflow: _handleTextOverflow,
              ),
            ),
          ),
        );
      } else if (element is ImageElement) {
        // Определяем float на основе выравнивания
        FCFloat float;
        if (element.alignment == Alignment.centerLeft)
          float = FCFloat.start;
        else if (element.alignment == Alignment.centerRight)
          float = FCFloat.end;
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

        // Добавляем изображение как Floatable внутри WidgetSpan
        spans.add(
          WidgetSpan(
            child: Floatable(
              key: ValueKey('image_$i'),
              float: float,
              padding: padding,
              // Устанавливаем максимальную ширину для обтекания текстом в зависимости от типа размера изображения
              maxWidthPercentage: _calculateMaxWidthPercentage(element, float),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedIndex == i ? editorTheme.selectedBorderColor : editorTheme.borderColor,
                    width: _selectedIndex == i ? 2.0 : 1.0,
                  ),
                  borderRadius: editorTheme.containerBorderRadius,
                  color: _selectedIndex == i ? editorTheme.selectedBackgroundColor : Colors.transparent,
                ),
                child: float == FCFloat.none
                    ? Center(
                        child: ImageEditor(
                          imageElement: element,
                          isSelected: _selectedIndex == i,
                          onTap: () {
                            setState(() {
                              _selectedIndex = i;

                              // Обновляем текущий float для панели инструментов
                              if (element.alignment == Alignment.centerLeft)
                                _currentImageFloat = FCFloat.start;
                              else if (element.alignment == Alignment.centerRight)
                                _currentImageFloat = FCFloat.end;
                              else
                                _currentImageFloat = FCFloat.none;
                            });
                          },
                          onImageChanged: (newImage) => _updateImageElement(i, newImage),
                          onDelete: () => _removeElement(i),
                        ),
                      )
                    : ImageEditor(
                        imageElement: element,
                        isSelected: _selectedIndex == i,
                        onTap: () {
                          setState(() {
                            _selectedIndex = i;

                            // Обновляем текущий float для панели инструментов
                            if (element.alignment == Alignment.centerLeft)
                              _currentImageFloat = FCFloat.start;
                            else if (element.alignment == Alignment.centerRight)
                              _currentImageFloat = FCFloat.end;
                            else
                              _currentImageFloat = FCFloat.none;
                          });
                        },
                        onImageChanged: (newImage) => _updateImageElement(i, newImage),
                        onDelete: () => _removeElement(i),
                      ),
              ),
            ),
          ),
        );
      }
    }

    // Добавляем оставшиеся spans, если они есть
    if (spans.isNotEmpty) {
      elements.add(Text.rich(TextSpan(children: spans)));
    }

    // Если у нас нет текущего Floatable, используем обычную колонку вместо FloatColumn
    if (!hasActiveFloatable) {
      return [Column(crossAxisAlignment: CrossAxisAlignment.start, children: elements)];
    }

    // Иначе используем FloatColumn
    return elements;
  }

  // Рассчитывает maxWidthPercentage для Floatable в зависимости от типа размера изображения
  double _calculateMaxWidthPercentage(ImageElement imageElement, FCFloat float) {
    // Если изображение выровнено по центру (нет обтекания), используем всю ширину
    if (float == FCFloat.none) {
      return 1.0;
    }

    // Для процента от экрана используем точное значение, указанное пользователем
    // Преобразуем процент (0-100) в долю (0.0-1.0)
    return imageElement.sizePercent / 100;
  }

  // Создает новый текстовый блок с заданным текстом и стилем
  void _createNewTextBlock(String text, TextStyleAttributes? style) {
    final effectiveStyle = style ?? TextStyleAttributes();
    _createNewTextBlockWithSpans(text, effectiveStyle, [TextSpanDocument(text: text, style: effectiveStyle)]);
  }

  // Создает новый текстовый блок с заданным текстом, стилем и спанами
  void _createNewTextBlockWithSpans(String text, TextStyleAttributes style, List<TextSpanDocument> spans) {
    if (widget.enableLogging) {
      print('Создание нового текстового блока с текстом длиной ${text.length} и ${spans.length} спанами');
    }

    // Создаем новый текстовый элемент
    TextElement newElement = TextElement(text: text, style: style);

    // Если переданы специальные spans, используем их вместо создания одного спана
    if (spans.isNotEmpty) {
      newElement.spans = spans;
      if (widget.enableLogging) {
        print('Установлены spans для нового блока. Количество: ${spans.length}');
      }
    }

    // Если выбран элемент, вставляем новый блок после него
    if (_selectedIndex != null && _selectedIndex! < _document.elements.length) {
      _document.insertElement(_selectedIndex! + 1, newElement);
      // Выбираем новый блок
      setState(() {
        _selectedIndex = _selectedIndex! + 1;
      });
    } else {
      // Если ничего не выбрано, добавляем в конец документа
      _document.addElement(newElement);
      setState(() {
        _selectedIndex = _document.elements.length - 1;
      });
    }

    // Уведомляем об изменении документа
    _notifyDocumentChanged();

    if (widget.enableLogging) {
      print('Новый текстовый блок создан на позиции ${_selectedIndex}');
    }
  }

  // Обработка переполнения текста из TextEditor
  void _handleTextOverflow(String overflowText) {
    if (widget.enableLogging) {
      print('Получено переполнение текста: ${overflowText.length} символов');
    }

    // Определяем стиль текущего элемента в позиции курсора, а не стиль всего элемента
    TextStyleAttributes currentStyle;
    List<TextSpanDocument> overflowSpans = [];

    if (_selectedIndex != null &&
        _selectedIndex! < _document.elements.length &&
        _document.elements[_selectedIndex!] is TextElement) {
      TextElement textElement = (_document.elements[_selectedIndex!] as TextElement);

      // Создаем список спанов для нового блока
      // В зависимости от позиции курсора, мы можем определить, какие стили нужно применить
      int? cursorPosition = _selection?.baseOffset;

      if (cursorPosition != null && cursorPosition >= 0 && cursorPosition < textElement.text.length) {
        // Если курсор в известной позиции, получаем стиль в этой позиции
        TextStyleAttributes? styleAtCursor = textElement.styleAt(cursorPosition);

        if (styleAtCursor != null) {
          currentStyle = styleAtCursor;
          if (widget.enableLogging) {
            print(
                'Используем стиль из позиции курсора ($cursorPosition) для переполнения: bold=${currentStyle.bold}, italic=${currentStyle.italic}, underline=${currentStyle.underline}, fontSize=${currentStyle.fontSize}');
          }

          // Создаем один спан с этим стилем для переполнения
          overflowSpans = [TextSpanDocument(text: overflowText, style: currentStyle)];
        } else {
          // Если стиль не найден в текущей позиции, используем стиль последнего спана
          if (textElement.spans.isNotEmpty) {
            currentStyle = textElement.spans.last.style;
            overflowSpans = [TextSpanDocument(text: overflowText, style: currentStyle)];
            if (widget.enableLogging) {
              print(
                  'Стиль в позиции курсора не найден, используем стиль последнего спана: bold=${currentStyle.bold}, italic=${currentStyle.italic}, underline=${currentStyle.underline}, fontSize=${currentStyle.fontSize}');
            }
          } else {
            // Если нет спанов, используем базовый стиль элемента
            currentStyle = textElement.style;
            overflowSpans = [TextSpanDocument(text: overflowText, style: currentStyle)];
            if (widget.enableLogging) {
              print(
                  'Используем базовый стиль элемента для переполнения, т.к. позиция курсора недоступна: bold=${currentStyle.bold}, italic=${currentStyle.italic}, underline=${currentStyle.underline}, fontSize=${currentStyle.fontSize}');
            }
          }
        }
      } else {
        // Если позиция курсора неизвестна, используем стиль последнего спана
        if (textElement.spans.isNotEmpty) {
          currentStyle = textElement.spans.last.style;
          overflowSpans = [TextSpanDocument(text: overflowText, style: currentStyle)];
          if (widget.enableLogging) {
            print(
                'Позиция курсора недоступна, используем стиль последнего спана: bold=${currentStyle.bold}, italic=${currentStyle.italic}, underline=${currentStyle.underline}, fontSize=${currentStyle.fontSize}');
          }
        } else {
          // Если нет спанов, используем базовый стиль элемента
          currentStyle = textElement.style;
          overflowSpans = [TextSpanDocument(text: overflowText, style: currentStyle)];
          if (widget.enableLogging) {
            print(
                'Используем базовый стиль элемента для переполнения, т.к. позиция курсора недоступна: bold=${currentStyle.bold}, italic=${currentStyle.italic}, underline=${currentStyle.underline}, fontSize=${currentStyle.fontSize}');
          }
        }
      }
    } else {
      // Если не выбран текстовый элемент, используем стиль по умолчанию
      currentStyle = TextStyleAttributes();
      overflowSpans = [TextSpanDocument(text: overflowText, style: currentStyle)];
      if (widget.enableLogging) {
        print(
            'Используем стиль по умолчанию для переполнения: bold=${currentStyle.bold}, italic=${currentStyle.italic}, underline=${currentStyle.underline}, fontSize=${currentStyle.fontSize}');
      }
    }

    // Если размер текста меньше 9500 символов, создаем один блок независимо от наличия переносов строк
    if (overflowText.length < 9500) {
      _createNewTextBlockWithSpans(overflowText, currentStyle, overflowSpans);
      if (widget.enableLogging) {
        print('Создан единичный блок для текста длиной ${overflowText.length} символов (<9500)');
      }
      return;
    }

    // Для больших текстов проверяем наличие параграфов
    final paragraphs = overflowText.split('\n');
    if (paragraphs.length > 1) {
      if (widget.enableLogging) {
        print('Обнаружено ${paragraphs.length} параграфов в переполнении');
      }

      // Создаем один крупный блок текста, объединяя параграфы до достижения оптимального размера ~10K
      int currentBlockLength = 0;
      String currentBlock = '';
      final int blockSizeLimit = 9500; // Стремимся к ~10K на блок

      for (int i = 0; i < paragraphs.length; i++) {
        final paragraph = paragraphs[i];

        // Если параграф сам по себе больше лимита, создаем для него отдельный блок
        if (paragraph.length > blockSizeLimit) {
          // Сначала сохраняем накопленный блок, если он не пустой
          if (currentBlock.isNotEmpty) {
            _createNewTextBlockWithSpans(
                currentBlock, currentStyle, [TextSpanDocument(text: currentBlock, style: currentStyle)]);
            if (widget.enableLogging) {
              print('Создан блок длиной ${currentBlock.length} символов');
            }
            currentBlock = '';
            currentBlockLength = 0;
          }

          // Затем создаем отдельный блок для большого параграфа
          _createNewTextBlockWithSpans(
              paragraph, currentStyle, [TextSpanDocument(text: paragraph, style: currentStyle)]);
          if (widget.enableLogging) {
            print('Создан блок из большого параграфа длиной ${paragraph.length} символов');
          }
        } else {
          // Будущий размер блока при добавлении этого параграфа
          int futureBlockLength = currentBlockLength;
          if (currentBlockLength > 0) futureBlockLength += 1; // +1 для символа переноса строки
          futureBlockLength += paragraph.length;

          // Если при добавлении параграфа блок превысит лимит, сохраняем текущий и начинаем новый
          if (futureBlockLength > blockSizeLimit && currentBlock.isNotEmpty) {
            _createNewTextBlockWithSpans(
                currentBlock, currentStyle, [TextSpanDocument(text: currentBlock, style: currentStyle)]);
            if (widget.enableLogging) {
              print('Создан блок длиной ${currentBlock.length} символов (достиг лимита)');
            }
            currentBlock = paragraph;
            currentBlockLength = paragraph.length;
          } else {
            // Иначе добавляем параграф к текущему блоку
            if (currentBlock.isNotEmpty) {
              currentBlock += '\n' + paragraph;
              currentBlockLength += 1 + paragraph.length;
            } else {
              currentBlock = paragraph;
              currentBlockLength = paragraph.length;
            }
          }
        }
      }

      // Создаем блок из оставшегося текста, если он есть
      if (currentBlock.isNotEmpty) {
        _createNewTextBlockWithSpans(
            currentBlock, currentStyle, [TextSpanDocument(text: currentBlock, style: currentStyle)]);
        if (widget.enableLogging) {
          print('Создан последний блок длиной ${currentBlock.length} символов');
        }
      }
    } else {
      // Если текст не содержит переносов строк, создаем один блок
      _createNewTextBlockWithSpans(overflowText, currentStyle, overflowSpans);
      if (widget.enableLogging) {
        print('Создан единичный блок для переполнения длиной ${overflowText.length} символов');
      }
    }
  }
}
