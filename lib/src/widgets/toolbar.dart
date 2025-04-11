import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  final VoidCallback? onBoldPressed;
  final VoidCallback? onItalicPressed;
  final VoidCallback? onUnderlinePressed;
  final VoidCallback? onClearFormattingPressed;
  final VoidCallback? onAddImagePressed;
  final VoidCallback? onAddTextPressed;

  const EditorToolbar({
    super.key,
    this.onBoldPressed,
    this.onItalicPressed,
    this.onUnderlinePressed,
    this.onClearFormattingPressed,
    this.onAddImagePressed,
    this.onAddTextPressed,
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
      ],
    );
  }
}
