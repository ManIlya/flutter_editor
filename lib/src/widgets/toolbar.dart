import 'package:flutter/material.dart';
import '../models/document_model.dart';

/// Тип элемента, который выделен в редакторе
enum SelectedElementType {
  /// Выделен текстовый элемент
  text,

  /// Выделено изображение
  image,

  /// Ничего не выделено
  none,
}

/// Контекст выделенного элемента для обработки в пользовательских действиях тулбара
class EditorSelectionContext {
  /// Тип выделенного элемента
  final SelectedElementType type;

  /// Индекс выделенного элемента в документе
  final int? elementIndex;

  /// Текстовый элемент (если type == text)
  final TextElement? textElement;

  /// Текущее выделение текста (если type == text)
  final TextSelection? textSelection;

  /// Изображение (если type == image)
  final ImageElement? imageElement;

  const EditorSelectionContext({
    required this.type,
    this.elementIndex,
    this.textElement,
    this.textSelection,
    this.imageElement,
  });

  /// Проверяет, есть ли текстовое выделение
  bool get hasTextSelection =>
      type == SelectedElementType.text && textSelection != null && textSelection!.start != textSelection!.end;

  /// Проверяет, выбрано ли изображение
  bool get hasImageSelection => type == SelectedElementType.image && imageElement != null;

  /// Проверяет, есть ли какое-либо выделение
  bool get hasSelection => type != SelectedElementType.none;
}

/// Типы колбэка для пользовательских иконок тулбара
typedef CustomToolbarActionCallback = void Function(EditorSelectionContext context);

/// Модель для пользовательской иконки тулбара
class CustomToolbarItem {
  /// Иконка для отображения
  final IconData icon;

  /// Текст подсказки
  final String tooltip;

  /// Обработчик нажатия по иконке без контекста
  final VoidCallback? onPressed;

  /// Обработчик нажатия с контекстом выделения
  final CustomToolbarActionCallback? onAction;

  /// Цвет иконки (необязательно)
  final Color? color;

  /// Должна ли иконка быть активна только при наличии выделения
  final bool enableOnlyWithSelection;

  /// Типы выделений, при которых иконка должна быть активна
  final Set<SelectedElementType> enabledForTypes;

  const CustomToolbarItem({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.onAction,
    this.color,
    this.enableOnlyWithSelection = false,
    this.enabledForTypes = const {SelectedElementType.text, SelectedElementType.image},
  }) : assert(
         onPressed != null || onAction != null,
         'Должен быть указан хотя бы один обработчик: onPressed или onAction',
       );

  /// Проверяет, должна ли иконка быть активна для текущего контекста
  bool isEnabledForContext(EditorSelectionContext context) {
    if (enableOnlyWithSelection && !context.hasSelection) {
      return false;
    }

    return enabledForTypes.contains(context.type);
  }
}

class EditorToolbar extends StatelessWidget {
  final VoidCallback? onBoldPressed;
  final VoidCallback? onItalicPressed;
  final VoidCallback? onUnderlinePressed;
  final VoidCallback? onClearFormattingPressed;
  final VoidCallback? onAddImagePressed;
  final VoidCallback? onAddTextPressed;

  /// Список пользовательских элементов тулбара
  final List<CustomToolbarItem>? customToolbarItems;

  /// Текущий контекст выделения в редакторе
  final EditorSelectionContext selectionContext;

  const EditorToolbar({
    super.key,
    this.onBoldPressed,
    this.onItalicPressed,
    this.onUnderlinePressed,
    this.onClearFormattingPressed,
    this.onAddImagePressed,
    this.onAddTextPressed,
    this.customToolbarItems,
    this.selectionContext = const EditorSelectionContext(type: SelectedElementType.none),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Форматирование текста
        IconButton(
          icon: const Icon(Icons.format_bold),
          tooltip: 'Полужирный',
          onPressed: onBoldPressed,
          color: Colors.grey.shade800,
        ),
        IconButton(
          icon: const Icon(Icons.format_italic),
          tooltip: 'Курсив',
          onPressed: onItalicPressed,
          color: Colors.grey.shade800,
        ),
        IconButton(
          icon: const Icon(Icons.format_underlined),
          tooltip: 'Подчеркнутый',
          onPressed: onUnderlinePressed,
          color: Colors.grey.shade800,
        ),
        IconButton(
          icon: const Icon(Icons.format_clear),
          tooltip: 'Сбросить форматирование',
          onPressed: onClearFormattingPressed,
          color: Colors.grey.shade800,
        ),
        const SizedBox(width: 16),
        Container(height: 24, width: 1, color: Colors.grey.shade400),
        const SizedBox(width: 16),
        // Добавление элементов
        IconButton(
          icon: const Icon(Icons.add_photo_alternate),
          tooltip: 'Добавить изображение',
          onPressed: onAddImagePressed,
          color: Colors.grey.shade800,
        ),
        IconButton(
          icon: const Icon(Icons.text_fields),
          tooltip: 'Добавить текстовый блок',
          onPressed: onAddTextPressed,
          color: Colors.grey.shade800,
        ),

        // Отображаем пользовательские иконки, если они есть
        if (customToolbarItems != null && customToolbarItems!.isNotEmpty) ...[
          const SizedBox(width: 16),
          Container(height: 24, width: 1, color: Colors.grey.shade400),
          const SizedBox(width: 16),

          // Добавляем каждую пользовательскую иконку
          ...customToolbarItems!.map(
            (item) => IconButton(
              icon: Icon(item.icon),
              tooltip: item.tooltip,
              onPressed: () {
                // Если есть обработчик с контекстом и иконка активна для текущего контекста
                if (item.onAction != null && item.isEnabledForContext(selectionContext)) {
                  item.onAction!(selectionContext);
                }
                // Если есть обычный обработчик нажатия
                else if (item.onPressed != null) {
                  item.onPressed!();
                }
              },
              // Тускнеем иконку, если она не активна для текущего контекста
              color:
                  item.isEnabledForContext(selectionContext)
                      ? (item.color ?? Colors.grey.shade800)
                      : Colors.grey.shade400,
            ),
          ),
        ],
      ],
    );
  }
}
