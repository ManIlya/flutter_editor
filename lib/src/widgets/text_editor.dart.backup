import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/document_model.dart' as doc;
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/editor_theme.dart';

/// Виджет для редактирования текста с поддержкой различных стилей
class TextEditor extends StatefulWidget {
  final String text;
  final List<doc.TextSpanDocument> spans;
  final doc.TextStyleAttributes style;
  final bool isSelected;
  final Function(String) onTextChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function(List<doc.TextSpanDocument>)? onSpansChanged;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  /// Включает подробное логирование для отладки
  final bool enableLogging;

  const TextEditor({
    super.key,
    required this.text,
    required this.spans,
    required this.style,
    required this.isSelected,
    required this.onTextChanged,
    required this.onSelectionChanged,
    this.onSpansChanged,
    required this.onTap,
    this.onDelete,
    this.enableLogging = false,
  });

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late StyledTextEditingController _controller;
  late FocusNode _focusNode;

  // Последнее известное выделение
  TextSelection? _lastKnownSelection;

  // Вспомогательный метод для логирования
  void _log(String message) {
    if (widget.enableLogging) {
      print(message);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = StyledTextEditingController(
      text: widget.text,
      spans: widget.spans,
      styleAttributesToTextStyle: _getFlutterTextStyle,
      enableLogging: widget.enableLogging,
    );
    _focusNode = FocusNode();

    // Обновляем текст при изменении ввода
    _controller.addListener(_onControllerChanged);

    // Запускаем таймер для отслеживания изменений выделения
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSelectionListener();
    });
  }

  void _onControllerChanged() {
    // Проверяем, изменился ли текст
    if (widget.text != _controller.text) {
      _log('Текст изменился с "${widget.text}" на "${_controller.text}"');

      // Отложенное уведомление об изменении текста
      Future.microtask(() {
        if (mounted) {
          // Обновляем spans перед изменением текста
          final spans = _controller.getSpans();
          _log('Сохранено состояние spans перед уведомлением об изменении текста.');

          // Сохраняем текущее выделение
          final selection = _controller.selection;
          _log('Сохранено выделение: start=${selection.start}, end=${selection.end}');

          // Уведомляем об изменении текста
          widget.onTextChanged(_controller.text);

          // Обновляем spans после изменения текста
          if (widget.onSpansChanged != null) {
            widget.onSpansChanged!(spans);
            _log('Отправлены обновленные spans в родительский виджет.');
          }

          // Восстанавливаем выделение, если оно изменилось
          if (_controller.selection != selection) {
            _log('Восстанавливаем выделение: ${selection.start}-${selection.end}');
            _controller.selection = selection;
          }
        }
      });
    }

    // Отслеживаем изменения выделения
    if (_controller.selection != _lastKnownSelection) {
      _lastKnownSelection = _controller.selection;

      // Используем микротаск для обновления выделения
      Future.microtask(() {
        if (mounted) {
          widget.onSelectionChanged(_controller.selection);
          _log(
            'Выделение в TextField обновлено: ${_controller.selection.baseOffset}-${_controller.selection.extentOffset}',
          );
        }
      });
    }
  }

  // Запускаем таймер для проверки изменений выделения
  void _startSelectionListener() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return false;

      // Если выделение изменилось, уведомляем об этом
      if (_controller.selection != _lastKnownSelection && _focusNode.hasFocus) {
        _lastKnownSelection = _controller.selection;

        // Используем микротаск для обновления выделения
        Future.microtask(() {
          if (mounted) {
            widget.onSelectionChanged(_controller.selection);

            // Для отладки
            _log(
              'Выделение в TextField обновлено: ${_controller.selection.baseOffset}-${_controller.selection.extentOffset}',
            );
          }
        });
      }

      return true; // Продолжаем цикл
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Обновляем текст, если он изменился извне
    if (oldWidget.text != widget.text && _controller.text != widget.text) {
      _controller.text = widget.text;
    }

    // Обновляем стили, если они изменились
    if (oldWidget.spans != widget.spans) {
      _controller.updateSpans(widget.spans);
    }

    // Управляем фокусом в зависимости от состояния выделения
    if (widget.isSelected) {
      _focusNode.requestFocus();

      // Сохраняем текущее выделение при получении фокуса
      // Это предотвращает сброс выделения при повторном рендеринге
      if (!oldWidget.isSelected && _controller.selection.baseOffset == -1) {
        // Если нет выделения, установим курсор в конец текста
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      }
    } else {
      _focusNode.unfocus();
    }
  }

  TextStyle _getFlutterTextStyle(doc.TextStyleAttributes style) {
    return TextStyle(
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      decoration:
          style.link != null
              ? TextDecoration.underline
              : (style.underline ? TextDecoration.underline : TextDecoration.none),
      decorationColor: style.link != null ? Colors.blue : null,
      decorationThickness: style.link != null ? 2.0 : 1.0,
      color: style.link != null ? Colors.blue : style.color,
      fontSize: style.fontSize,
    );
  }

  // Получает иконку для текущего выравнивания
  IconData _getAlignmentIcon(TextAlign alignment) {
    switch (alignment) {
      case TextAlign.left:
        return Icons.format_align_left;
      case TextAlign.center:
        return Icons.format_align_center;
      case TextAlign.right:
        return Icons.format_align_right;
      case TextAlign.justify:
        return Icons.format_align_justify;
      default:
        return Icons.format_align_left;
    }
  }

  // Отображает диалог для добавления или редактирования ссылки
  Future<void> _showLinkDialog(String? currentLink) async {
    final TextEditingController linkController = TextEditingController(text: currentLink ?? '');
    String? newLink;
    final editorTheme = EditorThemeExtension.of(context);

    // Определяем границы ссылки или выделения
    int startLink = _controller.selection.start;
    int endLink = _controller.selection.end;
    bool hasSelection = startLink != endLink;
    bool isExistingLink = currentLink != null;

    // Если нет выделения, но есть ссылка, находим её границы
    if (!hasSelection && isExistingLink) {
      // Ищем границы ссылки, на которой стоит курсор
      int currentPos = 0;
      for (final span in _controller.getSpans()) {
        final spanStart = currentPos;
        final spanEnd = currentPos + span.text.length;

        if (span.style.link == currentLink &&
            spanStart <= _controller.selection.start &&
            spanEnd >= _controller.selection.start) {
          startLink = spanStart;
          endLink = spanEnd;
          hasSelection = true;
          break;
        }

        currentPos = spanEnd;
      }
    }

    // Если нет выделения и нет ссылки, показываем сообщение
    if (!hasSelection && !isExistingLink) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Выделите текст для создания ссылки'),
          duration: Duration(seconds: 2),
          backgroundColor: editorTheme.toolbarColor,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isExistingLink ? 'Изменить ссылку' : 'Добавить ссылку',
            style: TextStyle(color: editorTheme.defaultTextStyle.color),
          ),
          backgroundColor: editorTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(editorTheme.borderRadius),
            side: BorderSide(color: editorTheme.borderColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: linkController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  labelText: 'URL',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: editorTheme.borderColor),
                    borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: editorTheme.linkColor),
                    borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
                  ),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                style: TextStyle(color: editorTheme.defaultTextStyle.color),
                onSubmitted: (value) {
                  newLink = value.trim();
                  Navigator.of(context).pop();
                },
              ),
              if (isExistingLink) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: Icon(Icons.open_in_new, size: 16, color: editorTheme.linkColor),
                  label: Text('Открыть в браузере', style: TextStyle(color: editorTheme.linkColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: editorTheme.linkColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2)),
                  ),
                  onPressed: () async {
                    final url = currentLink;
                    if (await canLaunch(url!)) {
                      await launch(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Не удалось открыть $url'), backgroundColor: editorTheme.toolbarColor),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
          actions: [
            if (isExistingLink)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.of(context).pop();
                  newLink = ''; // Специальный флаг для удаления ссылки
                },
                child: const Text('Удалить'),
              ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: editorTheme.toolbarIconColor),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: editorTheme.linkColor),
              onPressed: () {
                newLink = linkController.text.trim();
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    // Применяем ссылку, только если она была изменена
    if (newLink != null) {
      // Используем микротаск для предотвращения изменений во время рендеринга
      Future.microtask(() {
        if (mounted) {
          // Сохраняем текущее выделение
          final currentSelection = _controller.selection;

          // Создаем временное выделение, охватывающее всю ссылку
          final fullLinkSelection = TextSelection(baseOffset: startLink, extentOffset: endLink);

          // Устанавливаем выделение на всю ссылку
          _controller.selection = fullLinkSelection;

          if (newLink!.isEmpty) {
            // Удаляем ссылку
            _applyStyle((s) => s.copyWith(removeLink: true));
          } else {
            // Применяем или обновляем ссылку
            _applyStyle((s) => s.copyWith(link: newLink, underline: true));
          }

          // Восстанавливаем исходное выделение
          Future.microtask(() {
            if (mounted && _focusNode.hasFocus) {
              _controller.selection = currentSelection;
              widget.onSelectionChanged(_controller.selection);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Используем микротаск для обработки нажатия
        Future.microtask(() {
          if (mounted) {
            widget.onTap();
          }
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текстовое поле
          widget.isSelected ? _buildEditableText() : _buildViewableText(),

          // Всегда показываем панель инструментов форматирования, если редактор выбран
          if (widget.isSelected) _buildFormattingToolbar(),
        ],
      ),
    );
  }

  Widget _buildEditableText() {
    // Определяем выравнивание текста на основе стиля первого спана
    final TextAlign textAlignment =
        _controller.spans != null && _controller.spans!.isNotEmpty
            ? _controller.spans![0].style.alignment
            : widget.style.alignment;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      minLines: 1,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(fontSize: widget.style.fontSize),
      textAlign: textAlignment, // Применяем выравнивание
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onTap: () {
        // Используем микротаск для обработки нажатия
        Future.microtask(() {
          if (mounted) {
            widget.onTap();
          }
        });
      },
      onChanged: (value) {
        // Обработка изменений текста происходит через listener контроллера
        // Но здесь можно выполнить дополнительную логику сохранения форматирования
        if (widget.enableLogging) {
          _log('onChanged вызван с текстом: $value');
        }

        // Отложенное обновление стилей
        if (widget.onSpansChanged != null) {
          // Получаем обновленные spans только один раз в следующем микротаске
          Future.microtask(() {
            if (mounted) {
              final newSpans = _controller.getSpans();
              widget.onSpansChanged!(newSpans);
            }
          });
        }
      },
      onEditingComplete: () {
        // При завершении редактирования, убеждаемся, что все изменения spans сохранены
        if (widget.onSpansChanged != null) {
          Future.microtask(() {
            if (mounted) {
              widget.onSpansChanged!(_controller.getSpans());
            }
          });
        }
      },
    );
  }

  // Текст в режиме просмотра с поддержкой кликабельных ссылок
  Widget _buildViewableText() {
    // Определяем выравнивание текста на основе стиля первого спана
    final TextAlign textAlignment =
        _controller.spans != null && _controller.spans!.isNotEmpty
            ? _controller.spans![0].style.alignment
            : widget.style.alignment;

    // Создаем TextSpan с кликабельными ссылками для просмотра
    final List<InlineSpan> children = [];

    if (_controller.spans != null && _controller.spans!.isNotEmpty) {
      for (final span in _controller.spans!) {
        final TextStyle spanStyle = _getFlutterTextStyle(span.style);
        children.add(
          TextSpan(
            text: span.text,
            style: spanStyle,
            // Добавляем обработчик тапа для ссылок только в режиме просмотра
            recognizer:
                span.style.link != null
                    ? (TapGestureRecognizer()
                      ..onTap = () {
                        // Используем микротаск для обработки нажатия на ссылку
                        Future.microtask(() {
                          if (mounted) {
                            _openLink(span.style.link!);
                          }
                        });
                      })
                    : null,
          ),
        );
      }
    } else {
      children.add(TextSpan(text: _controller.text, style: _getFlutterTextStyle(widget.style)));
    }

    return SelectableText.rich(
      TextSpan(children: children, style: TextStyle(fontSize: widget.style.fontSize)),
      onTap: widget.onTap,
      enableInteractiveSelection: true,
      textAlign: textAlignment, // Применяем выравнивание
    );
  }

  // Открывает ссылку в браузере
  void _openLink(String url) {
    _log('Открытие ссылки из текстового редактора: $url');

    // Преобразуем строку в Uri
    final Uri uri = Uri.parse(url);

    // Используем микротаск для предотвращения изменений во время рендеринга
    Future.microtask(() {
      // Открываем URL через url_launcher
      launchUrl(uri, mode: LaunchMode.externalApplication)
          .then((success) {
            if (!success) {
              _log('Не удалось открыть ссылку: $url');
            }
          })
          .catchError((error) {
            _log('Ошибка при открытии ссылки: $error');
          });
    });
  }

  // Строит панель форматирования текста
  Widget _buildFormattingToolbar() {
    final bool hasSelection = _controller.selection.start != _controller.selection.end;
    final doc.TextStyleAttributes style = _controller.getStyleAt(_controller.selection.start) ?? widget.style;
    final editorTheme = EditorThemeExtension.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: editorTheme.toolbarColor,
        borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
        border: Border.all(color: editorTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Левая часть: инструменты форматирования
          Row(
            children: [
              // Кнопка "Полужирный"
              IconButton(
                icon: Icon(
                  Icons.format_bold,
                  size: 18,
                  color:
                      style.bold
                          ? editorTheme.toolbarSelectedIconColor
                          : (hasSelection
                              ? editorTheme.toolbarIconColor
                              : editorTheme.toolbarIconColor.withOpacity(0.5)),
                ),
                onPressed: hasSelection ? () => _applyStyle((s) => s.copyWith(bold: !s.bold)) : null,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'Полужирный',
              ),
              // Кнопка "Курсив"
              IconButton(
                icon: Icon(
                  Icons.format_italic,
                  size: 18,
                  color:
                      style.italic
                          ? editorTheme.toolbarSelectedIconColor
                          : (hasSelection
                              ? editorTheme.toolbarIconColor
                              : editorTheme.toolbarIconColor.withOpacity(0.5)),
                ),
                onPressed: hasSelection ? () => _applyStyle((s) => s.copyWith(italic: !s.italic)) : null,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'Курсив',
              ),
              // Кнопка "Подчеркнутый"
              IconButton(
                icon: Icon(
                  Icons.format_underlined,
                  size: 18,
                  color:
                      style.underline
                          ? editorTheme.toolbarSelectedIconColor
                          : (hasSelection
                              ? editorTheme.toolbarIconColor
                              : editorTheme.toolbarIconColor.withOpacity(0.5)),
                ),
                onPressed: hasSelection ? () => _applyStyle((s) => s.copyWith(underline: !s.underline)) : null,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'Подчеркнутый',
              ),
              // Кнопка "Ссылка"
              IconButton(
                icon: Icon(
                  Icons.link,
                  size: 18,
                  color:
                      style.link != null
                          ? editorTheme.linkColor
                          : (hasSelection
                              ? editorTheme.toolbarIconColor
                              : editorTheme.toolbarIconColor.withOpacity(0.5)),
                ),
                onPressed: hasSelection || style.link != null ? () => _showLinkDialog(style.link) : null,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip:
                    style.link != null
                        ? 'Ссылка: ${style.link!.length > 30 ? style.link!.substring(0, 27) + '...' : style.link}'
                        : hasSelection
                        ? 'Добавить ссылку'
                        : 'Выделите текст для создания ссылки',
              ),
              // Кнопка "Сбросить форматирование"
              IconButton(
                icon: Icon(
                  Icons.format_clear,
                  size: 18,
                  color: hasSelection ? editorTheme.toolbarIconColor : editorTheme.toolbarIconColor.withOpacity(0.5),
                ),
                onPressed: hasSelection ? _clearFormatting : null,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'Сбросить форматирование',
              ),
              // Выпадающий список размеров шрифта
              Container(
                height: 32,
                width: 70,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                margin: EdgeInsets.only(right: 8.0),
                decoration: BoxDecoration(
                  color: editorTheme.backgroundColor,
                  border: Border.all(
                    color: hasSelection ? editorTheme.borderColor : editorTheme.borderColor.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(editorTheme.borderRadius / 4),
                ),
                child: DropdownButton<double>(
                  value: _getFontSizeValue(style),
                  isDense: true,
                  isExpanded: true,
                  underline: SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: hasSelection ? editorTheme.toolbarIconColor : editorTheme.toolbarIconColor.withOpacity(0.5),
                  ),
                  items:
                      [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 32.0]
                          .map(
                            (fontSize) => DropdownMenuItem<double>(
                              value: fontSize,
                              child: Text(
                                '$fontSize пт',
                                style: TextStyle(fontSize: 14, color: editorTheme.defaultTextStyle.color),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      hasSelection
                          ? (double? newSize) {
                            if (newSize != null) {
                              // Используем микротаск, чтобы отложить выполнение до завершения построения виджета
                              Future.microtask(() {
                                if (mounted) {
                                  _setFontSize(newSize);
                                }
                              });
                            }
                          }
                          : null,
                  hint: Text(
                    '${style.fontSize} пт',
                    style: TextStyle(fontSize: 14, color: editorTheme.defaultTextStyle.color),
                  ),
                  style: TextStyle(color: editorTheme.defaultTextStyle.color, fontSize: 14),
                ),
              ),

              // Разделитель между инструментами
              Container(
                height: 24,
                width: 1,
                color: editorTheme.borderColor,
                margin: EdgeInsets.symmetric(horizontal: 8.0),
              ),

              // Выпадающий список с предустановленными стилями текста
              Container(
                height: 32,
                width: 140,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: editorTheme.backgroundColor,
                  border: Border.all(
                    color: hasSelection ? editorTheme.borderColor : editorTheme.borderColor.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(editorTheme.borderRadius / 4),
                ),
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  underline: SizedBox(),
                  value: _getCurrentStyleType(style),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: hasSelection ? editorTheme.toolbarIconColor : editorTheme.toolbarIconColor.withOpacity(0.5),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'heading',
                      child: Text(
                        'Заголовок',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: editorTheme.defaultTextStyle.color,
                        ),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'subheading',
                      child: Text(
                        'Подзаголовок',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: editorTheme.defaultTextStyle.color,
                        ),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'normal',
                      child: Text(
                        'Обычный текст',
                        style: TextStyle(fontSize: 14, color: editorTheme.defaultTextStyle.color),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'custom',
                      child: Text(
                        'Произвольный',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: editorTheme.defaultTextStyle.color,
                        ),
                      ),
                    ),
                  ],
                  onChanged:
                      hasSelection
                          ? (String? styleType) {
                            if (styleType != null && styleType != 'custom') {
                              // Используем микротаск, чтобы отложить выполнение до завершения построения виджета
                              Future.microtask(() {
                                if (mounted) {
                                  _applyPresetStyle(styleType);
                                }
                              });
                            }
                          }
                          : null,
                  style: TextStyle(color: editorTheme.defaultTextStyle.color, fontSize: 14),
                ),
              ),
            ],
          ),

          // Вертикальный разделитель
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            width: 1,
            height: 24,
            color: editorTheme.borderColor,
          ),

          // Средняя часть: выравнивание текста
          Row(
            children: [
              // Кнопка выравнивания по левому краю
              IconButton(
                icon: Icon(
                  Icons.format_align_left,
                  size: 18,
                  color:
                      style.alignment == TextAlign.left
                          ? editorTheme.toolbarSelectedIconColor
                          : editorTheme.toolbarIconColor,
                ),
                onPressed: () => _applyParagraphStyle(TextAlign.left),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'По левому краю',
              ),
              // Кнопка выравнивания по центру
              IconButton(
                icon: Icon(
                  Icons.format_align_center,
                  size: 18,
                  color:
                      style.alignment == TextAlign.center
                          ? editorTheme.toolbarSelectedIconColor
                          : editorTheme.toolbarIconColor,
                ),
                onPressed: () => _applyParagraphStyle(TextAlign.center),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'По центру',
              ),
              // Кнопка выравнивания по правому краю
              IconButton(
                icon: Icon(
                  Icons.format_align_right,
                  size: 18,
                  color:
                      style.alignment == TextAlign.right
                          ? editorTheme.toolbarSelectedIconColor
                          : editorTheme.toolbarIconColor,
                ),
                onPressed: () => _applyParagraphStyle(TextAlign.right),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'По правому краю',
              ),
              // Кнопка выравнивания по ширине
              IconButton(
                icon: Icon(
                  Icons.format_align_justify,
                  size: 18,
                  color:
                      style.alignment == TextAlign.justify
                          ? editorTheme.toolbarSelectedIconColor
                          : editorTheme.toolbarIconColor,
                ),
                onPressed: () => _applyParagraphStyle(TextAlign.justify),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'По ширине',
              ),
            ],
          ),

          const Spacer(), // Занимает всё доступное пространство
          // Правая часть: кнопка удаления
          if (widget.onDelete != null) ...[
            // Вертикальный разделитель перед кнопкой удаления
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              width: 1,
              height: 24,
              color: editorTheme.borderColor,
            ),
            // Кнопка удаления
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(editorTheme.borderRadius / 4),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'Удалить параграф',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Применяет стиль выравнивания к параграфу
  void _applyParagraphStyle(TextAlign alignment) {
    // Используем микротаск для предотвращения вызова setState во время построения
    Future.microtask(() {
      if (mounted) {
        _log('════════════════════════════════════════════');
        _log('🔠 ПРИМЕНЕНИЕ ВЫРАВНИВАНИЯ:');
        _log('Новое выравнивание: $alignment');

        // Выводим текущую структуру спанов
        _log('СТРУКТУРА СПАНОВ ДО ИЗМЕНЕНИЯ ВЫРАВНИВАНИЯ:');
        _controller.logSpansStructure();

        // Применяем выравнивание ко всем спанам в параграфе
        if (_controller.spans != null && _controller.spans!.isNotEmpty) {
          final newSpans = <doc.TextSpanDocument>[];

          for (final span in _controller.spans!) {
            newSpans.add(doc.TextSpanDocument(text: span.text, style: span.style.copyWith(alignment: alignment)));
          }

          _controller.updateSpans(newSpans);
          _log('Выравнивание применено ко всем спанам');

          // Уведомляем родительский виджет об изменениях
          widget.onTextChanged(_controller.text);
          _log('Уведомлен родительский виджет об изменении текста.');

          // Также уведомляем родительский виджет об изменениях в spans
          if (widget.onSpansChanged != null) {
            widget.onSpansChanged!(newSpans);
            _log('Уведомлен родительский виджет об изменении spans.');
          }

          // Обновляем UI
          setState(() {});
        }

        _log('════════════════════════════════════════════');
      }
    });
  }

  // Применяет стиль к выделенному тексту
  void _applyStyle(doc.TextStyleAttributes Function(doc.TextStyleAttributes) styleUpdater) {
    if (_controller.selection.start == _controller.selection.end) {
      // Ничего не делаем, если нет выделения, кроме случая с ссылками
      // Для ссылок уже есть отдельная логика в _showLinkDialog,
      // которая временно создает выделение на весь спан ссылки
      _log('Попытка применить стиль без выделения - пропускаем');
      return;
    }

    _log('════════════════════════════════════════════');
    _log('🔍 ПРИМЕНЕНИЕ СТИЛЯ К ВЫДЕЛЕНИЮ:');

    final start = _controller.selection.start;
    final end = _controller.selection.end;
    _log('Выделение: [$start-$end]');

    final currentStyle = _controller.getStyleAt(start) ?? widget.style;
    _log(
      'Текущий стиль: bold=${currentStyle.bold}, italic=${currentStyle.italic}, underline=${currentStyle.underline}, fontSize=${currentStyle.fontSize}, link=${currentStyle.link}',
    );

    final newStyle = styleUpdater(currentStyle);
    _log(
      'Новый стиль: bold=${newStyle.bold}, italic=${newStyle.italic}, underline=${newStyle.underline}, fontSize=${newStyle.fontSize}, link=${newStyle.link}',
    );

    // Проверяем, имеем ли дело с операцией над ссылкой
    final bool isLinkOperation = newStyle.link != currentStyle.link;
    if (isLinkOperation) {
      _log('Обнаружена операция с ссылкой: ${newStyle.link ?? "удаление ссылки"}');
    }

    // Выводим текущую структуру спанов перед применением стиля
    _log('СТРУКТУРА СПАНОВ ДО ПРИМЕНЕНИЯ СТИЛЯ:');
    _controller.logSpansStructure();

    // Сохраняем текущее выделение
    final currentSelection = _controller.selection;

    // Применяем стиль к спанам контроллера
    _controller.applyStyle(newStyle, start, end);
    _log('Стиль применен к тексту.');

    // После применения стиля объединяем смежные спаны с одинаковыми ссылками
    if (isLinkOperation) {
      _log('Объединение смежных спанов с одинаковыми ссылками...');
      _controller.mergeAdjacentLinksWithSameUrl();
    }

    // Создаем новый текстовый элемент с обновленными спанами
    final newText = _controller.text;

    // Получаем обновленные spans
    final spans = _controller.getSpans();

    // Выводим обновленную структуру спанов
    _log('СТРУКТУРА СПАНОВ ПОСЛЕ ПРИМЕНЕНИЯ СТИЛЯ:');
    _controller.logSpansStructure();

    // Принудительно уведомляем родительский виджет об изменениях
    widget.onTextChanged(newText);
    _log('Уведомлен родительский виджет об изменении текста.');

    // Также уведомляем родительский виджет об изменениях в spans, если есть callback
    if (widget.onSpansChanged != null) {
      widget.onSpansChanged!(spans);
      _log('Уведомлен родительский виджет об изменении spans.');
    }

    // Обновляем UI и восстанавливаем выделение
    setState(() {
      // Обновляем контроллер с измененными spans снова для гарантии
      _controller.updateSpans(spans);

      Future.microtask(() {
        if (mounted && _focusNode.hasFocus) {
          _log('Восстанавливаем выделение: ${currentSelection.start}-${currentSelection.end}');
          _controller.selection = currentSelection;
          widget.onSelectionChanged(_controller.selection);
        }
      });
    });

    _log('════════════════════════════════════════════');
  }

  // Сбрасывает все форматирование для выделенного текста
  void _clearFormatting() {
    if (_controller.selection.start == _controller.selection.end) {
      _log('Попытка сбросить форматирование без выделения - пропускаем');
      return;
    }

    _log('════════════════════════════════════════════');
    _log('🧹 СБРОС ФОРМАТИРОВАНИЯ:');

    final start = _controller.selection.start;
    final end = _controller.selection.end;
    _log('Выделение: [$start-$end]');

    // Получаем текущее выравнивание из первого спана (сохраняем его)
    final currentAlignment =
        _controller.spans != null && _controller.spans!.isNotEmpty
            ? _controller.spans![0].style.alignment
            : TextAlign.left;

    // Получаем текущий размер шрифта (сохраняем его)
    final currentFontSize = _controller.getStyleAt(start)?.fontSize ?? widget.style.fontSize;
    _log('Сохраняем размер шрифта: $currentFontSize');

    // Создаем обычный стиль без форматирования, но с сохранением выравнивания и размера шрифта
    final plainStyle = doc.TextStyleAttributes(
      bold: false,
      italic: false,
      underline: false,
      link: null,
      fontSize: currentFontSize, // Сохраняем текущий размер шрифта
      alignment: currentAlignment, // Сохраняем текущее выравнивание
    );

    _log(
      'Применяем стиль без форматирования: bold=false, italic=false, underline=false, fontSize=$currentFontSize, link=null, alignment=$currentAlignment',
    );

    // Выводим текущую структуру спанов перед сбросом форматирования
    _log('СТРУКТУРА СПАНОВ ДО СБРОСА ФОРМАТИРОВАНИЯ:');
    _controller.logSpansStructure();

    // Сохраняем текущее выделение
    final currentSelection = _controller.selection;

    // Применяем обычный стиль к выделенному тексту
    _controller.applyStyle(plainStyle, start, end);
    _log('Форматирование сброшено.');

    // Создаем новый текстовый элемент с обновленными спанами
    final newText = _controller.text;

    // Получаем обновленные spans
    final spans = _controller.getSpans();

    // Выводим обновленную структуру спанов
    _log('СТРУКТУРА СПАНОВ ПОСЛЕ СБРОСА ФОРМАТИРОВАНИЯ:');
    _controller.logSpansStructure();

    // Уведомляем родительский виджет об изменениях
    widget.onTextChanged(newText);
    _log('Уведомлен родительский виджет об изменении текста.');

    // Также уведомляем родительский виджет об изменениях в spans, если есть callback
    if (widget.onSpansChanged != null) {
      widget.onSpansChanged!(spans);
      _log('Уведомлен родительский виджет об изменении spans.');
    }

    // Обновляем UI и восстанавливаем выделение
    setState(() {
      // Обновляем контроллер с измененными spans снова для гарантии
      _controller.updateSpans(spans);

      Future.microtask(() {
        if (mounted && _focusNode.hasFocus) {
          _log('Восстанавливаем выделение: ${currentSelection.start}-${currentSelection.end}');
          _controller.selection = currentSelection;
          widget.onSelectionChanged(_controller.selection);
        }
      });
    });

    _log('════════════════════════════════════════════');
  }

  // Устанавливает точный размер шрифта для выделенного текста
  void _setFontSize(double newFontSize) {
    if (_controller.selection.start == _controller.selection.end) {
      _log('Попытка изменить размер текста без выделения - пропускаем');
      return;
    }

    _log('════════════════════════════════════════════');
    _log('🔍 УСТАНОВКА РАЗМЕРА ТЕКСТА:');

    final start = _controller.selection.start;
    final end = _controller.selection.end;
    _log('Выделение: [$start-$end]');

    final currentStyle = _controller.getStyleAt(start) ?? widget.style;
    _log('Текущий размер шрифта: ${currentStyle.fontSize}');
    _log('Новый размер шрифта: $newFontSize');

    // Создаем новый стиль с заданным размером шрифта
    final newStyle = currentStyle.copyWith(fontSize: newFontSize);

    // Сохраняем текущее выделение
    final currentSelection = _controller.selection;

    // Применяем стиль к спанам контроллера
    _controller.applyStyle(newStyle, start, end);
    _log('Размер шрифта изменен.');

    // Получаем обновленные spans
    final spans = _controller.getSpans();

    // Уведомляем родительский виджет об изменениях
    widget.onTextChanged(_controller.text);
    _log('Уведомлен родительский виджет об изменении текста.');

    // Также уведомляем родительский виджет об изменениях в spans, если есть callback
    if (widget.onSpansChanged != null) {
      widget.onSpansChanged!(spans);
      _log('Уведомлен родительский виджет об изменении spans.');
    }

    // Обновляем UI и восстанавливаем выделение
    if (mounted) {
      setState(() {
        // Обновляем контроллер с измененными spans снова для гарантии
        _controller.updateSpans(spans);
      });

      Future.microtask(() {
        if (mounted && _focusNode.hasFocus) {
          _log('Восстанавливаем выделение: ${currentSelection.start}-${currentSelection.end}');
          _controller.selection = currentSelection;
          widget.onSelectionChanged(_controller.selection);
        }
      });
    }

    _log('════════════════════════════════════════════');
  }

  // Применяет предустановленный стиль к выделенному тексту
  void _applyPresetStyle(String styleType) {
    if (_controller.selection.start == _controller.selection.end) {
      _log('Попытка применить стиль без выделения - пропускаем');
      return;
    }

    _log('════════════════════════════════════════════');
    _log('🔍 ПРИМЕНЕНИЕ ПРЕДУСТАНОВЛЕННОГО СТИЛЯ:');

    final start = _controller.selection.start;
    final end = _controller.selection.end;
    _log('Выделение: [$start-$end]');

    // Получаем текущую тему редактора
    final editorTheme = EditorThemeExtension.of(context);

    final currentStyle = _controller.getStyleAt(start) ?? widget.style;
    doc.TextStyleAttributes newStyle;

    // Применяем предустановленный стиль в зависимости от выбора
    switch (styleType) {
      case 'heading':
        // Используем стиль заголовка из темы
        newStyle = currentStyle.copyWith(
          bold: editorTheme.titleTextStyle.fontWeight == FontWeight.bold,
          fontSize: editorTheme.titleTextStyle.fontSize ?? 24.0,
          color: editorTheme.titleTextStyle.color,
        );
        _log('Применяем стиль заголовка из темы: fontSize=${newStyle.fontSize}, bold=${newStyle.bold}');
        break;
      case 'subheading':
        // Используем стиль подзаголовка из темы
        newStyle = currentStyle.copyWith(
          bold: editorTheme.subtitleTextStyle.fontWeight == FontWeight.bold,
          fontSize: editorTheme.subtitleTextStyle.fontSize ?? 18.0,
          color: editorTheme.subtitleTextStyle.color,
        );
        _log('Применяем стиль подзаголовка из темы: fontSize=${newStyle.fontSize}, bold=${newStyle.bold}');
        break;
      case 'normal':
        // Используем стиль обычного текста из темы
        newStyle = currentStyle.copyWith(
          bold: editorTheme.defaultTextStyle.fontWeight == FontWeight.bold,
          fontSize: editorTheme.defaultTextStyle.fontSize ?? 14.0,
          color: editorTheme.defaultTextStyle.color,
        );
        _log('Применяем обычный стиль из темы: fontSize=${newStyle.fontSize}, bold=${newStyle.bold}');
        break;
      default:
        _log('Неизвестный тип стиля: $styleType');
        return;
    }

    // Сохраняем текущее выделение
    final currentSelection = _controller.selection;

    // Применяем стиль к спанам контроллера
    _controller.applyStyle(newStyle, start, end);
    _log('Предустановленный стиль применен.');

    // Получаем обновленные spans
    final spans = _controller.getSpans();

    // Уведомляем родительский виджет об изменениях
    widget.onTextChanged(_controller.text);
    _log('Уведомлен родительский виджет об изменении текста.');

    // Также уведомляем родительский виджет об изменениях в spans, если есть callback
    if (widget.onSpansChanged != null) {
      widget.onSpansChanged!(spans);
      _log('Уведомлен родительский виджет об изменении spans.');
    }

    // Обновляем UI и восстанавливаем выделение
    if (mounted) {
      setState(() {
        // Обновляем контроллер с измененными spans снова для гарантии
        _controller.updateSpans(spans);
      });

      Future.microtask(() {
        if (mounted && _focusNode.hasFocus) {
          _log('Восстанавливаем выделение: ${currentSelection.start}-${currentSelection.end}');
          _controller.selection = currentSelection;
          widget.onSelectionChanged(_controller.selection);
        }
      });
    }

    _log('════════════════════════════════════════════');
  }

  // Определяет текущий тип стиля текста на основе его свойств
  String _getCurrentStyleType(doc.TextStyleAttributes style) {
    // Получаем текущую тему редактора
    final editorTheme = EditorThemeExtension.of(context);

    // Проверяем на соответствие стилю заголовка из темы
    if (style.bold == (editorTheme.titleTextStyle.fontWeight == FontWeight.bold) &&
        (style.fontSize == editorTheme.titleTextStyle.fontSize)) {
      return 'heading';
    }
    // Проверяем на соответствие стилю подзаголовка из темы
    else if (style.bold == (editorTheme.subtitleTextStyle.fontWeight == FontWeight.bold) &&
        (style.fontSize == editorTheme.subtitleTextStyle.fontSize)) {
      return 'subheading';
    }
    // Проверяем на соответствие обычному стилю из темы
    else if (style.bold == (editorTheme.defaultTextStyle.fontWeight == FontWeight.bold) &&
        (style.fontSize == editorTheme.defaultTextStyle.fontSize)) {
      return 'normal';
    }
    // Если ничего не совпадает, считаем стиль пользовательским
    else {
      return 'custom';
    }
  }

  // Определяет текущий размер шрифта, учитывая возможные нестандартные значения из темы
  double _getFontSizeValue(doc.TextStyleAttributes style) {
    final editorTheme = EditorThemeExtension.of(context);
    final double fontSize = style.fontSize;

    // Список стандартных размеров шрифта в выпадающем списке
    final List<double> availableSizes = [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 32.0];

    // Проверяем, если размер шрифта совпадает с одним из стандартных значений
    if (availableSizes.contains(fontSize)) {
      return fontSize;
    }

    // Проверяем, не используется ли размер из темы редактора
    if (fontSize == editorTheme.titleTextStyle.fontSize) {
      // Находим ближайший доступный размер к размеру заголовка
      return _findClosestSize(editorTheme.titleTextStyle.fontSize ?? 24.0, availableSizes);
    } else if (fontSize == editorTheme.subtitleTextStyle.fontSize) {
      // Находим ближайший доступный размер к размеру подзаголовка
      return _findClosestSize(editorTheme.subtitleTextStyle.fontSize ?? 20.0, availableSizes);
    } else if (fontSize == editorTheme.defaultTextStyle.fontSize) {
      // Находим ближайший доступный размер к размеру обычного текста
      return _findClosestSize(editorTheme.defaultTextStyle.fontSize ?? 16.0, availableSizes);
    }

    // Если размер не стандартный, находим ближайший из доступных размеров
    return _findClosestSize(fontSize, availableSizes);
  }

  // Находит ближайший размер в списке доступных размеров
  double _findClosestSize(double size, List<double> availableSizes) {
    double closestSize = availableSizes.first;
    double minDifference = (size - closestSize).abs();

    for (final availableSize in availableSizes) {
      final difference = (size - availableSize).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestSize = availableSize;
      }
    }

    return closestSize;
  }
}

/// Контроллер для работы со стилизованным текстом
class StyledTextEditingController extends TextEditingController {
  List<doc.TextSpanDocument>? spans; // Делаем публичным для доступа из TextEditor
  final TextStyle Function(doc.TextStyleAttributes) _styleAttributesToTextStyle;
  String _lastText = ''; // Для отслеживания изменений
  final bool enableLogging;

  StyledTextEditingController({
    String? text,
    List<doc.TextSpanDocument>? spans,
    required TextStyle Function(doc.TextStyleAttributes) styleAttributesToTextStyle,
    this.enableLogging = false,
  }) : spans = spans,
       _styleAttributesToTextStyle = styleAttributesToTextStyle,
       _lastText = text ?? '',
       super(text: text);

  // Вспомогательный метод для логирования
  void _log(String message) {
    if (enableLogging) {
      print(message);
    }
  }

  void updateSpans(List<doc.TextSpanDocument>? newSpans) {
    spans = newSpans;
    // Логируем структуру спанов после каждого обновления
    if (enableLogging) {
      logSpansStructure();
    }
    notifyListeners();
  }

  @override
  set value(TextEditingValue newValue) {
    // Сохраняем старый текст и spans перед изменением
    final oldText = text;
    final oldSpans = spans != null ? List<doc.TextSpanDocument>.from(spans!) : null;

    // Выполняем стандартную установку значения
    super.value = newValue;

    // Обновляем _lastText с проверкой на изменения
    if (oldText != text && oldSpans != null && oldSpans.isNotEmpty) {
      _log('════════════════════════════════════════════');
      _log('📝 ОБНОВЛЕНИЕ ТЕКСТА С СОХРАНЕНИЕМ СТИЛЕЙ:');
      _log('Старый текст: "$oldText"');
      _log('Новый текст: "$text"');

      // Применяем сохранение форматирования
      spans = _preserveFormattingForNewText(oldText, text, oldSpans, selection);

      _log('Обновление текста с сохранением структуры спанов...');
      logSpansStructure();
      _lastText = text;
    }
  }

  // Метод для сохранения форматирования при изменении текста
  List<doc.TextSpanDocument> _preserveFormattingForNewText(
    String oldText,
    String newText,
    List<doc.TextSpanDocument> oldSpans,
    TextSelection currentSelection,
  ) {
    // Если нет изменений или нет spans, возвращаем исходные spans
    if (oldText == newText || oldSpans.isEmpty) {
      _log('Текст не изменился или нет spans, возвращаем исходные spans.');
      return oldSpans;
    }

    _log('════════════════════════════════════════════');
    _log('🔄 ОБРАБОТКА ИЗМЕНЕНИЯ ТЕКСТА:');
    _log('Старый текст: "$oldText"');
    _log('Новый текст: "$newText"');
    _log('Позиция курсора: ${currentSelection.baseOffset}');

    // Определяем тип изменения и позицию курсора
    final cursorPosition = currentSelection.baseOffset;
    final isAddition = newText.length > oldText.length;
    final isDeletion = newText.length < oldText.length;

    if (isAddition) {
      _log('➕ Обнаружено добавление текста.');
      // Найдем точку вставки
      int insertPos = cursorPosition - (newText.length - oldText.length);
      if (insertPos < 0) insertPos = 0;

      _log('Позиция вставки: $insertPos');
      _log('Добавлено символов: ${newText.length - oldText.length}');

      // Получим стиль в позиции вставки
      doc.TextStyleAttributes? styleAtInsert;

      // Текущая позиция в тексте
      int spanStartPos = 0;

      // Создаем новые spans
      List<doc.TextSpanDocument> newSpans = [];

      for (int i = 0; i < oldSpans.length; i++) {
        final span = oldSpans[i];
        final spanStart = spanStartPos;
        final spanEnd = spanStart + span.text.length;

        _log('Обработка спана #$i: "$span.text" позиция [$spanStart-$spanEnd]');

        // Проверяем, находится ли позиция вставки точно на границе между спанами
        bool isAtBoundary = insertPos == spanEnd && i < oldSpans.length - 1;

        // Если вставка произошла внутри этого спана или это последний спан с вставкой на его границе
        if ((insertPos >= spanStart && insertPos < spanEnd) || (insertPos == spanEnd && i == oldSpans.length - 1)) {
          _log('Вставка произошла в этом спане.');
          // Запоминаем стиль для новых символов
          styleAtInsert = span.style;
          _log(
            'Стиль для новых символов: bold=${styleAtInsert.bold}, italic=${styleAtInsert.italic}, fontSize=${styleAtInsert.fontSize}',
          );

          // Вычисляем добавленный текст
          final addedLength = newText.length - oldText.length;
          final addedText = newText.substring(insertPos, insertPos + addedLength);
          _log('Добавленный текст: "$addedText"');

          // Разделяем спан на части
          final beforeInsert = span.text.substring(0, insertPos - spanStart);
          final afterInsert = span.text.substring(insertPos - spanStart);

          // Добавляем части с соответствующим стилем
          if (beforeInsert.isNotEmpty) {
            newSpans.add(doc.TextSpanDocument(text: beforeInsert, style: span.style));
            _log('Создан спан ДО вставки: "$beforeInsert"');
          }

          // Добавляем новый текст с тем же стилем
          newSpans.add(doc.TextSpanDocument(text: addedText, style: span.style));
          _log(
            'Создан спан с НОВЫМ текстом: "$addedText" с стилем: bold=${span.style.bold}, italic=${span.style.italic}, fontSize=${span.style.fontSize}',
          );

          if (afterInsert.isNotEmpty) {
            newSpans.add(doc.TextSpanDocument(text: afterInsert, style: span.style));
            _log('Создан спан ПОСЛЕ вставки: "$afterInsert"');
          }
        } else if (isAtBoundary) {
          // Если вставка происходит точно на границе между спанами,
          // мы просто добавляем текущий спан без изменений.
          // Новый текст будет добавлен при обработке следующего спана.
          newSpans.add(span);
          _log('Спан до места вставки (на границе), добавляем без изменений');
        } else if (spanStart > insertPos) {
          // Спан после места вставки
          newSpans.add(span);
          _log('Спан после места вставки, добавляем без изменений');
        } else {
          // Спан до места вставки
          newSpans.add(span);
          _log('Спан до места вставки, добавляем без изменений');
        }

        spanStartPos = spanEnd;
      }

      // Если newSpans пусто, значит что-то пошло не так - используем fallback
      if (newSpans.isEmpty) {
        _log('⚠️ Не удалось создать новые spans. Используем fallback с одним спаном.');
        // Используем стиль первого спана
        final style = oldSpans[0].style;
        return [doc.TextSpanDocument(text: newText, style: style)];
      }

      _log('Созданы новые spans (${newSpans.length}) после добавления текста.');

      // Объединяем соседние спаны с одинаковым стилем
      final result = _mergeAdjacentSpans(newSpans);
      _log('Объединены смежные спаны с одинаковым стилем. Финальное количество: ${result.length}');
      _log('════════════════════════════════════════════');
      return result;
    } else if (isDeletion) {
      _log('➖ Обнаружено удаление текста.');
      _log('Удалено символов: ${oldText.length - newText.length}');

      // Более точный алгоритм обнаружения места удаления
      int deleteStartOffset = -1;
      int deleteLength = oldText.length - newText.length;

      // Найдем общий префикс
      int commonPrefixLength = 0;
      int minLength = Math.min(oldText.length, newText.length);
      while (commonPrefixLength < minLength && oldText[commonPrefixLength] == newText[commonPrefixLength]) {
        commonPrefixLength++;
      }

      // Найдем общий суффикс, но только если есть общий префикс
      int commonSuffixLength = 0;
      if (commonPrefixLength < minLength) {
        while (commonSuffixLength < minLength - commonPrefixLength &&
            oldText[oldText.length - 1 - commonSuffixLength] == newText[newText.length - 1 - commonSuffixLength]) {
          commonSuffixLength++;
        }
      }

      // Определяем место удаления
      deleteStartOffset = commonPrefixLength;

      _log('Обнаружено удаление в позиции $deleteStartOffset длиной $deleteLength');
      _log('Общий префикс длиной $commonPrefixLength, общий суффикс длиной $commonSuffixLength');

      if (deleteStartOffset >= 0) {
        // Создаем новые spans с учетом удаления
        List<doc.TextSpanDocument> newSpans = [];
        int currentPosition = 0;

        for (int i = 0; i < oldSpans.length; i++) {
          final span = oldSpans[i];
          final spanStart = currentPosition;
          final spanEnd = spanStart + span.text.length;

          _log('Анализ спана #$i: "${span.text}" позиция [$spanStart-$spanEnd]');

          // Удаление полностью до этого спана
          if (deleteStartOffset >= spanEnd) {
            newSpans.add(span);
            _log('Спан до удаления, добавляем без изменений');
          }
          // Удаление полностью после этого спана
          else if (deleteStartOffset + deleteLength <= spanStart) {
            // Добавляем спан со смещением позиции
            newSpans.add(doc.TextSpanDocument(text: span.text, style: span.style));
            _log('Спан после удаления, добавляем без изменений');
          }
          // Удаление затрагивает этот спан
          else {
            // Начало удаления внутри этого спана
            if (deleteStartOffset > spanStart && deleteStartOffset < spanEnd) {
              // Часть до удаления
              final beforeText = span.text.substring(0, deleteStartOffset - spanStart);
              if (beforeText.isNotEmpty) {
                newSpans.add(doc.TextSpanDocument(text: beforeText, style: span.style));
                _log('Добавлена часть спана до удаления: "$beforeText"');
              }

              // Если удаление заканчивается в этом спане
              if (deleteStartOffset + deleteLength < spanEnd) {
                final afterText = span.text.substring(deleteStartOffset - spanStart + deleteLength);
                if (afterText.isNotEmpty) {
                  newSpans.add(doc.TextSpanDocument(text: afterText, style: span.style));
                  _log('Добавлена часть спана после удаления: "$afterText"');
                }
              }
            }
            // Начало удаления до этого спана, но конец удаления внутри спана
            else if (deleteStartOffset <= spanStart && deleteStartOffset + deleteLength < spanEnd) {
              final afterText = span.text.substring(deleteStartOffset + deleteLength - spanStart);
              if (afterText.isNotEmpty) {
                newSpans.add(doc.TextSpanDocument(text: afterText, style: span.style));
                _log('Добавлена часть спана после удаления: "$afterText"');
              }
            }
            // Удаление полностью содержит этот спан
            else if (deleteStartOffset <= spanStart && deleteStartOffset + deleteLength >= spanEnd) {
              _log('Спан полностью удален');
              // Ничего не добавляем, так как спан полностью удален
            }
          }

          currentPosition = spanEnd;
        }

        // Проверяем, что мы создали хотя бы один спан
        if (newSpans.isEmpty) {
          _log('⚠️ Все спаны были удалены. Создаем один спан с оставшимся текстом.');
          // Используем стиль первого спана для оставшегося текста
          final style = oldSpans[0].style;
          return [doc.TextSpanDocument(text: newText, style: style)];
        }

        // Проверяем, весь ли текст учтен
        String reconstructedText = newSpans.map((s) => s.text).join();
        if (reconstructedText.length != newText.length) {
          _log(
            '⚠️ Реконструированный текст (${reconstructedText.length}) не соответствует новому тексту (${newText.length})',
          );
          _log('Реконструированный: "$reconstructedText"');
          _log('Новый: "$newText"');

          // Если текст не совпадает, сохраняем хотя бы стили существующих спанов
          final style = oldSpans[0].style;
          return [doc.TextSpanDocument(text: newText, style: style)];
        }

        // Объединяем соседние спаны с одинаковым стилем
        final result = _mergeAdjacentSpans(newSpans);
        _log('Объединены смежные спаны с одинаковым стилем. Финальное количество: ${result.length}');
        _log('════════════════════════════════════════════');
        return result;
      }

      // Если не удалось определить место удаления точно, используем старый алгоритм
      _log('Используем запасной алгоритм для удаления...');

      // Текущая позиция в тексте
      int oldPos = 0;
      int newPos = 0;

      // Создаем новые spans
      List<doc.TextSpanDocument> newSpans = [];

      // Проходим по старым spans
      for (final span in oldSpans) {
        final oldSpanLength = span.text.length;
        final oldSpanEnd = oldPos + oldSpanLength;

        _log('Обработка спана: "${span.text}" позиция [$oldPos-$oldSpanEnd]');

        // Определяем, сколько текста из этого спана остается в новом тексте
        int charsLeft = 0;
        for (int i = 0; i < oldSpanLength; i++) {
          if (oldPos + i >= oldText.length) break;

          // Ищем текущий символ в оставшемся новом тексте
          bool found = false;
          for (int j = newPos; j < newText.length; j++) {
            if (oldText[oldPos + i] == newText[j]) {
              charsLeft++;
              newPos = j + 1;
              found = true;
              break;
            }
          }

          if (!found) break;
        }

        _log('Символов осталось от этого спана: $charsLeft');

        // Если от спана что-то осталось, добавляем его
        if (charsLeft > 0) {
          final remainingText = newText.substring(newPos - charsLeft, newPos);
          newSpans.add(doc.TextSpanDocument(text: remainingText, style: span.style));
          _log('Добавлен спан с оставшимся текстом: "$remainingText"');
        }

        oldPos = oldSpanEnd;
      }

      // Если newSpans пусто, значит все было удалено или текст полностью изменен
      if (newSpans.isEmpty) {
        _log('⚠️ Все спаны были удалены. Создаем один спан с оставшимся текстом.');
        // Используем стиль первого спана
        final style = oldSpans[0].style;
        return [doc.TextSpanDocument(text: newText, style: style)];
      }

      // Проверяем, весь ли текст учтен
      int coveredLength = 0;
      for (final span in newSpans) {
        coveredLength += span.text.length;
      }

      // Если есть непокрытые части, добавляем их
      if (coveredLength < newText.length) {
        final remainingText = newText.substring(coveredLength);
        _log('Остался непокрытый текст: "$remainingText". Добавляем его со стилем последнего спана.');
        // Используем стиль последнего спана
        newSpans.add(doc.TextSpanDocument(text: remainingText, style: oldSpans.last.style));
      }

      _log('Созданы новые spans (${newSpans.length}) после удаления текста.');

      // Объединяем соседние спаны с одинаковым стилем
      final result = _mergeAdjacentSpans(newSpans);
      _log('Объединены смежные спаны с одинаковым стилем. Финальное количество: ${result.length}');
      _log('════════════════════════════════════════════');
      return result;
    }

    _log('⚠️ Не удалось определить тип изменения текста. Создаем один спан.');
    // Если не удалось определить тип изменения, сохраняем хотя бы стиль
    final style = oldSpans[0].style;
    return [doc.TextSpanDocument(text: newText, style: style)];
  }

  // Метод для отладочного вывода текущей структуры спанов
  void logSpansStructure() {
    if (!enableLogging) return;

    _log('════════════════════════════════════════════');
    _log('📋 СТРУКТУРА СПАНОВ:');
    if (spans == null || spans!.isEmpty) {
      _log('Спаны отсутствуют');
      _log('════════════════════════════════════════════');
      return;
    }

    int currentPos = 0;
    for (int i = 0; i < spans!.length; i++) {
      final span = spans![i];
      final spanStart = currentPos;
      final spanEnd = currentPos + span.text.length;

      final bool isBold = span.style.bold;
      final bool isItalic = span.style.italic;
      final bool isUnderline = span.style.underline;
      final String styleMarkers = [if (isBold) 'Ж', if (isItalic) 'К', if (isUnderline) 'П'].join('');

      _log('Спан #$i [$spanStart-$spanEnd]: ${styleMarkers.isNotEmpty ? "[$styleMarkers] " : ""}"${span.text}"');
      currentPos = spanEnd;
    }
    _log('════════════════════════════════════════════');
  }

  // Объединяет соседние спаны с одинаковым стилем
  List<doc.TextSpanDocument> _mergeAdjacentSpans(List<doc.TextSpanDocument> spans) {
    if (spans.length <= 1) return spans;

    final List<doc.TextSpanDocument> result = [spans[0]];

    for (int i = 1; i < spans.length; i++) {
      final currentSpan = spans[i];
      final previousSpan = result.last;

      // Проверяем, имеют ли соседние спаны одинаковый стиль
      if (_areStylesEqual(previousSpan.style, currentSpan.style)) {
        // Объединяем спаны
        result.last = doc.TextSpanDocument(text: previousSpan.text + currentSpan.text, style: previousSpan.style);
        _log(
          'Объединены спаны с одинаковыми стилями: "${previousSpan.text}" + "${currentSpan.text}" (fontSize=${previousSpan.style.fontSize})',
        );
      } else {
        _log(
          'Спаны не объединены из-за разных стилей: fontSize1=${previousSpan.style.fontSize}, fontSize2=${currentSpan.style.fontSize}',
        );
        result.add(currentSpan);
      }
    }

    return result;
  }

  // Проверяет, одинаковые ли стили
  bool _areStylesEqual(doc.TextStyleAttributes a, doc.TextStyleAttributes b) {
    return a.bold == b.bold &&
        a.italic == b.italic &&
        a.underline == b.underline &&
        a.link == b.link &&
        a.fontSize == b.fontSize &&
        a.alignment == b.alignment;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    // Если нет spans, возвращаем обычный TextSpan
    if (spans == null || spans!.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    // Создаем TextSpan из наших spans
    final List<InlineSpan> children = [];
    for (final span in spans!) {
      final TextStyle spanStyle = _styleAttributesToTextStyle(span.style);
      // В режиме редактирования не добавляем обработчик клика по ссылке
      final TextSpan textSpan = TextSpan(
        text: span.text,
        style: spanStyle,
        // Не добавляем recognizer, чтобы ссылка не была кликабельной в режиме редактирования
      );
      children.add(textSpan);
    }

    return TextSpan(children: children, style: style);
  }

  // Возвращает стиль в указанной позиции
  doc.TextStyleAttributes? getStyleAt(int position) {
    if (spans == null || spans!.isEmpty) {
      return null;
    }

    int currentPos = 0;
    for (final span in spans!) {
      final spanEnd = currentPos + span.text.length;
      if (position >= currentPos && position < spanEnd) {
        return span.style;
      }
      currentPos = spanEnd;
    }

    return null;
  }

  // Применяет стиль к указанному диапазону
  void applyStyle(doc.TextStyleAttributes style, int start, int end) {
    if (spans == null || spans!.isEmpty) {
      spans = [doc.TextSpanDocument(text: text, style: style)];
      _log('Применение стиля к новому тексту. Создан первый спан.');
      logSpansStructure();
      notifyListeners();
      return;
    }

    if (start >= end || start < 0 || end > text.length) {
      _log('⚠️ Неверный диапазон для применения стиля: start=$start, end=$end, textLength=${text.length}');
      return;
    }

    _log('Применение стиля к диапазону: start=$start, end=$end');
    _log('Новый стиль: bold=${style.bold}, italic=${style.italic}, underline=${style.underline}, link=${style.link}');

    final List<doc.TextSpanDocument> newSpans = [];
    int currentPos = 0;

    // Проходим через все spans и разбиваем их в соответствии с диапазоном
    for (final span in spans!) {
      final spanStart = currentPos;
      final spanEnd = currentPos + span.text.length;

      // Если span полностью до диапазона, добавляем его
      if (spanEnd <= start) {
        newSpans.add(span);
        _log('Спан до диапазона: "${span.text}" позиция [$spanStart-$spanEnd]');
      }
      // Если span полностью после диапазона, добавляем его
      else if (spanStart >= end) {
        newSpans.add(span);
        _log('Спан после диапазона: "${span.text}" позиция [$spanStart-$spanEnd]');
      }
      // Если span пересекает диапазон
      else {
        // Часть до диапазона
        if (spanStart < start) {
          final beforeText = span.text.substring(0, start - spanStart);
          newSpans.add(doc.TextSpanDocument(text: beforeText, style: span.style));
          _log('Создан спан ДО выделения: "$beforeText" с тем же стилем');
        }

        // Часть внутри диапазона
        final insideText = span.text.substring(
          Math.max(0, start - spanStart),
          Math.min(span.text.length, end - spanStart),
        );

        newSpans.add(doc.TextSpanDocument(text: insideText, style: style));
        _log('Создан спан ВНУТРИ выделения: "$insideText" с новым стилем: bold=${style.bold}, italic=${style.italic}');

        // Часть после диапазона
        if (spanEnd > end) {
          final afterText = span.text.substring(end - spanStart);
          newSpans.add(doc.TextSpanDocument(text: afterText, style: span.style));
          _log('Создан спан ПОСЛЕ выделения: "$afterText" с тем же стилем');
        }
      }

      currentPos = spanEnd;
    }

    spans = newSpans;
    _log('Применение стиля завершено. Новое количество спанов: ${spans!.length}');
    logSpansStructure();
    notifyListeners();
  }

  // Получает текущий список spans для передачи родительскому виджету
  List<doc.TextSpanDocument> getSpans() {
    final result = spans ?? [doc.TextSpanDocument(text: text, style: const doc.TextStyleAttributes())];
    return result;
  }

  // Объединяет соседние спаны с одинаковыми ссылками
  void mergeAdjacentLinksWithSameUrl() {
    if (spans == null || spans!.length <= 1) return;

    _log('Начинаем объединение смежных спанов с одинаковыми ссылками...');
    logSpansStructure();

    final List<doc.TextSpanDocument> newSpans = [];
    doc.TextSpanDocument? currentSpan;

    for (final span in spans!) {
      if (currentSpan == null) {
        currentSpan = span;
      } else if (span.style.link != null &&
          currentSpan.style.link == span.style.link &&
          currentSpan.style.bold == span.style.bold &&
          currentSpan.style.italic == span.style.italic &&
          currentSpan.style.underline == span.style.underline &&
          currentSpan.style.fontSize == span.style.fontSize) {
        // Проверяем одинаковый размер шрифта
        // Если текущий спан имеет ту же ссылку и стили, объединяем его с предыдущим
        _log('Объединяем спаны с одинаковыми ссылками: "${currentSpan.text}" + "${span.text}"');
        currentSpan = doc.TextSpanDocument(text: currentSpan.text + span.text, style: currentSpan.style);
      } else {
        // Иначе добавляем текущий спан в результат и переходим к следующему
        newSpans.add(currentSpan);
        currentSpan = span;
      }
    }

    // Добавляем последний обрабатываемый спан
    if (currentSpan != null) {
      newSpans.add(currentSpan);
    }

    spans = newSpans;
    _log('Объединение смежных спанов завершено. Новое количество спанов: ${spans!.length}');
    logSpansStructure();
    notifyListeners();
  }
}

/// Вспомогательный класс для математических операций
class Math {
  static int max(int a, int b) => a > b ? a : b;
  static int min(int a, int b) => a < b ? a : b;
}
