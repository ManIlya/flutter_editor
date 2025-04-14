import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/document_model.dart' as doc;
import '../theme/editor_theme.dart';

/// Виджет для редактирования изображения в документе
class ImageEditor extends StatelessWidget {
  final doc.ImageElement imageElement;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(doc.ImageElement) onImageChanged;
  final Function() onDelete;

  const ImageEditor({
    super.key,
    required this.imageElement,
    required this.isSelected,
    required this.onTap,
    required this.onImageChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final editorTheme = EditorThemeExtension.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Обертка изображения с учетом выравнивания
          Container(
            alignment: imageElement.alignment,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Индикатор float-эффекта
                if (imageElement.alignment == Alignment.centerLeft || imageElement.alignment == Alignment.centerRight)
                  Container(
                    width: imageElement.width,
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                    color: editorTheme.floatIndicatorColor,
                    child: Row(
                      mainAxisAlignment:
                          imageElement.alignment == Alignment.centerLeft
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                      children: [
                        Icon(
                          imageElement.alignment == Alignment.centerLeft ? Icons.arrow_left : Icons.arrow_right,
                          size: 14,
                          color: editorTheme.floatIndicatorTextColor,
                        ),
                        Text(
                          imageElement.alignment == Alignment.centerLeft ? 'Обтекание справа' : 'Обтекание слева',
                          style: editorTheme.floatLabelTextStyle,
                        ),
                        Icon(
                          imageElement.alignment == Alignment.centerLeft ? Icons.arrow_left : Icons.arrow_right,
                          size: 14,
                          color: editorTheme.floatIndicatorTextColor,
                        ),
                      ],
                    ),
                  ),

                // Индикатор размера
                if (isSelected)
                  Container(
                    width: imageElement.width,
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                    color: editorTheme.toolbarColor.withOpacity(0.8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_size_select_large, size: 14, color: editorTheme.toolbarIconColor),
                        const SizedBox(width: 4),
                        Text(
                          '${imageElement.sizePercent.toInt()}% от ширины экрана',
                          style: TextStyle(
                            fontSize: 12,
                            color: editorTheme.toolbarIconColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Изображение
                CachedNetworkImage(
                  imageUrl: imageElement.imageUrl,
                  width: imageElement.width,
                  height: imageElement.height,
                  placeholder:
                      (context, url) => Container(
                        width: imageElement.width,
                        height: imageElement.height,
                        color: editorTheme.placeholderColor,
                        child: Center(child: CircularProgressIndicator(color: editorTheme.toolbarIconColor)),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        width: imageElement.width,
                        height: imageElement.height,
                        color: editorTheme.placeholderColor,
                        child: Icon(Icons.error, color: editorTheme.toolbarIconColor),
                      ),
                ),

                // Подпись к изображению
                if (imageElement.caption.isNotEmpty || isSelected)
                  Container(
                    width: imageElement.width,
                    padding: const EdgeInsets.only(top: 8.0),
                    child:
                        isSelected
                            ? InkWell(
                              onTap: () => showCaptionEditDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
                                  border: Border.all(color: editorTheme.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        imageElement.caption.isEmpty ? "Добавить подпись..." : imageElement.caption,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color:
                                              imageElement.caption.isEmpty
                                                  ? editorTheme.placeholderColor
                                                  : editorTheme.captionColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.edit, size: 16, color: editorTheme.toolbarIconColor),
                                  ],
                                ),
                              ),
                            )
                            : Text(
                              imageElement.caption,
                              style: editorTheme.captionTextStyle,
                              textAlign: TextAlign.center,
                            ),
                  ),
              ],
            ),
          ),

          // Панель инструментов (отображается только при выделении)
          if (isSelected) _buildToolbar(context),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final editorTheme = EditorThemeExtension.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: editorTheme.toolbarColor,
        borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
        border: Border.all(color: editorTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Левая часть панели с кнопками выравнивания
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Положение:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: editorTheme.defaultTextStyle.color),
              ),
              const SizedBox(width: 8),
              // Кнопка выравнивания по левому краю
              IconButton(
                icon: Icon(
                  Icons.format_align_left,
                  size: 18,
                  color:
                      imageElement.alignment == Alignment.centerLeft
                          ? editorTheme.toolbarSelectedIconColor
                          : editorTheme.toolbarIconColor,
                ),
                onPressed: () => _updateAlignment(Alignment.centerLeft),
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
                      imageElement.alignment == Alignment.center
                          ? editorTheme.toolbarSelectedIconColor
                          : editorTheme.toolbarIconColor,
                ),
                onPressed: () => _updateAlignment(Alignment.center),
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
                      imageElement.alignment == Alignment.centerRight
                          ? editorTheme.toolbarSelectedIconColor
                          : editorTheme.toolbarIconColor,
                ),
                onPressed: () => _updateAlignment(Alignment.centerRight),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'По правому краю',
              ),

              const SizedBox(width: 16),

              // Кнопка изменения размера
              IconButton(
                icon: Icon(Icons.photo_size_select_large, size: 18, color: editorTheme.toolbarIconColor),
                onPressed: () => _showResizeDialog(context),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                tooltip: 'Изменить размер',
              ),
            ],
          ),

          // Правая часть панели с кнопкой удаления
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red,
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: 32, height: 32),
            tooltip: 'Удалить изображение',
          ),
        ],
      ),
    );
  }

  void _updateAlignment(AlignmentGeometry alignment) {
    final updatedImage = imageElement.copyWith(alignment: alignment);
    onImageChanged(updatedImage);
  }

  void _showResizeDialog(BuildContext context) {
    final editorTheme = EditorThemeExtension.of(context);

    // Начальные значения базируются на текущих настройках изображения
    double newWidth = imageElement.width;
    double newHeight = imageElement.height;
    double sizePercent = imageElement.sizePercent;
    // Всегда используем "screen" (процент от ширины экрана)
    String sizeType = 'screen';

    // Определяем размер экрана
    final screenWidth = MediaQuery.of(context).size.width;

    // Рассчитываем текущий процент от экрана, если он не задан
    if (sizePercent < 10 || sizePercent > 100) {
      sizePercent = (newWidth / screenWidth * 100).clamp(10.0, 100.0);
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Запрещаем закрытие по клику вне диалога
      builder:
          (BuildContext dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Изменить размер изображения', style: TextStyle(color: editorTheme.defaultTextStyle.color)),
                backgroundColor: editorTheme.backgroundColor,
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок для настройки процента
                      Text(
                        'Размер изображения:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: editorTheme.defaultTextStyle.color),
                      ),

                      const SizedBox(height: 16),

                      // Показываем слайдер процентов
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ширина: ${sizePercent.toInt()}% от экрана',
                            style: TextStyle(fontSize: 14, color: editorTheme.defaultTextStyle.color),
                          ),
                          Slider(
                            value: sizePercent,
                            min: 10,
                            max: 100,
                            divisions: 9,
                            activeColor: editorTheme.toolbarSelectedIconColor,
                            inactiveColor: editorTheme.borderColor,
                            label: '${sizePercent.toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                sizePercent = value;
                                // Пересчитываем ширину и высоту на основе процента
                                newWidth = screenWidth * sizePercent / 100;
                                if (imageElement.originalHeight != null && imageElement.originalWidth != null) {
                                  final aspectRatio = imageElement.originalHeight! / imageElement.originalWidth!;
                                  newHeight = newWidth * aspectRatio;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(foregroundColor: editorTheme.toolbarIconColor),
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: editorTheme.toolbarSelectedIconColor),
                    onPressed: () {
                      // Сохраняем оригинальные размеры, если они еще не заданы
                      double? origWidth = imageElement.originalWidth;
                      double? origHeight = imageElement.originalHeight;

                      if (origWidth == null || origHeight == null) {
                        origWidth = imageElement.width;
                        origHeight = imageElement.height;
                      }

                      // Обновляем изображение с новыми размерами и настройками
                      final updatedImage = imageElement.copyWith(
                        width: newWidth,
                        height: newHeight,
                        originalWidth: origWidth,
                        originalHeight: origHeight,
                        sizePercent: sizePercent,
                        sizeType: sizeType,
                      );

                      onImageChanged(updatedImage);
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Применить'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Публичный метод для редактирования подписи
  void showCaptionEditDialog(BuildContext context) {
    final editorTheme = EditorThemeExtension.of(context);
    final TextEditingController captionController = TextEditingController(text: imageElement.caption);
    bool isControllerDisposed = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Запрещаем закрытие по клику вне диалога
      builder:
          (BuildContext dialogContext) => PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (!didPop) {
                // Освобождаем контроллер при попытке закрыть диалог
                if (!isControllerDisposed) {
                  isControllerDisposed = true;
                  captionController.dispose();
                }
                Navigator.of(dialogContext).pop();
              }
            },
            child: AlertDialog(
              title: Text('Подпись к изображению', style: TextStyle(color: editorTheme.defaultTextStyle.color)),
              backgroundColor: editorTheme.backgroundColor,
              content: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Введите подпись к изображению',
                  hintStyle: TextStyle(color: editorTheme.placeholderColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
                    borderSide: BorderSide(color: editorTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
                    borderSide: BorderSide(color: editorTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(editorTheme.borderRadius / 2),
                    borderSide: BorderSide(color: editorTheme.toolbarSelectedIconColor),
                  ),
                ),
                style: TextStyle(color: editorTheme.defaultTextStyle.color),
                autofocus: true,
                maxLines: 2,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (!isControllerDisposed) {
                      isControllerDisposed = true;
                      captionController.dispose();
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: editorTheme.toolbarIconColor),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: editorTheme.toolbarSelectedIconColor),
                  onPressed: () {
                    // Обновляем изображение и закрываем диалог
                    final updatedImage = imageElement.copyWith(caption: captionController.text.trim());
                    onImageChanged(updatedImage);
                    Navigator.of(dialogContext).pop();
                    if (!isControllerDisposed) {
                      isControllerDisposed = true;
                      captionController.dispose();
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ),
    ).then((_) {
      // Освобождаем контроллер, если он еще не освобожден
      if (!isControllerDisposed) {
        isControllerDisposed = true;
        captionController.dispose();
      }
    });
  }

  // Приватный метод для вызова публичного (для обратной совместимости)
  void _showCaptionEditDialog(BuildContext context) {
    showCaptionEditDialog(context);
  }
}
