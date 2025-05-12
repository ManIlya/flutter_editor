import 'package:flutter/material.dart' hide TextSpan;
import 'package:flutter_editor/flutter_editor.dart';
import 'dart:typed_data';
import 'package:flutter_editor/src/widgets/toolbar.dart';

/// Пример интеграции редактора в другое приложение с пользовательской темой
class EditorIntegrationExample extends StatelessWidget {
  const EditorIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Пример интеграции редактора',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        // Добавляем нашу тему редактора в приложение
        extensions: [
          // Можно использовать предустановленную тему
          EditorThemeExtension.light,
        ],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
        // Добавляем темную тему редактора
        extensions: [EditorThemeExtension.dark],
      ),
      themeMode: ThemeMode.system,
      home: const EditorExampleScreen(),
    );
  }
}

class EditorExampleScreen extends StatefulWidget {
  const EditorExampleScreen({super.key});

  @override
  State<EditorExampleScreen> createState() => _EditorExampleScreenState();
}

class _EditorExampleScreenState extends State<EditorExampleScreen> {
  // Пример документа
  late DocumentModel _document;
  // Режим просмотра/редактирования
  bool _isEditMode = true;
  // Флаг для пользовательской темы
  bool _useCustomTheme = false;

  @override
  void initState() {
    super.initState();
    // Создаем пустой документ
    _document = DocumentModel(
      elements: [
        TextElement(text: 'Это пример интеграции редактора в ваше приложение с использованием ThemeExtension.'),
        TextElement(
          text:
              'Попробуйте выделить текст и нажать на пользовательскую иконку в панели инструментов для изменения цвета текста.',
        ),
        ImageElement(
          imageUrl: 'https://images.unsplash.com/photo-1501854140801-50d01698950b',
          caption: 'Пример изображения',
          width: 400,
          height: 200,
        ),
        TextElement(
          text:
              'Также можно выбрать изображение и применить к нему действие с помощью пользовательской иконки тулбара.',
        ),
      ],
    );
  }

  // Пример пользовательской темы в фирменном стиле
  EditorThemeExtension _getCustomBrandTheme() {
    // Основные цвета бренда
    const Color primaryColor = Color(0xFF6200EE);
    const Color secondaryColor = Color(0xFF03DAC5);
    const Color backgroundColor = Color(0xFFF5F5F5);
    const Color textColor = Color(0xFF1F1F1F);

    return EditorThemeExtension(
      backgroundColor: backgroundColor,
      borderColor: Colors.grey.shade300,
      selectedBorderColor: primaryColor,
      selectedBackgroundColor: primaryColor.withOpacity(0.1),
      toolbarColor: Colors.white,
      toolbarIconColor: Colors.grey.shade800,
      toolbarSelectedIconColor: primaryColor,
      captionColor: Colors.grey.shade700,
      linkColor: secondaryColor,
      placeholderColor: Colors.grey.shade200,
      floatIndicatorColor: secondaryColor.withOpacity(0.2),
      floatIndicatorTextColor: secondaryColor,
      borderRadius: 8.0,
      elementSpacing: 16.0,
      containerBorderRadius: BorderRadius.circular(8.0),
      containerShadow: BoxShadow(color: Colors.black12, offset: const Offset(0, 2), blurRadius: 6.0),
      defaultTextStyle: const TextStyle(fontSize: 16.0, color: textColor, fontFamily: 'Roboto'),
      captionTextStyle: TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 13.0,
        color: Colors.grey.shade700,
        fontFamily: 'Roboto',
      ),
      placeholderTextStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16.0, fontFamily: 'Roboto'),
      floatLabelTextStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: secondaryColor,
        fontFamily: 'Roboto',
      ),
      titleTextStyle: const TextStyle(fontSize: 24.0, color: textColor, fontFamily: 'Roboto'),
      subtitleTextStyle: const TextStyle(fontSize: 20.0, color: textColor, fontFamily: 'Roboto'),
    );
  }

  // Пример обработчика для изменения цвета выделенного текста
  void _handleColorText(EditorSelectionContext context) {
    if (context.type == SelectedElementType.text &&
        context.elementIndex != null &&
        context.textSelection != null &&
        context.textElement != null) {
      // Получаем элемент текста
      final textElement = context.textElement!;
      // Получаем диапазон выделения
      final start = context.textSelection!.start;
      final end = context.textSelection!.end;

      if (start < end) {
        // Создаем новый стиль с цветом текста
        final newColor = Colors.red;
        final currentStyle = textElement.styleAt(start) ?? const TextStyleAttributes();
        final newStyle = currentStyle.copyWith(color: newColor);

        // Применяем стиль к выделенному тексту
        textElement.applyStyle(newStyle, start, end);

        // Обновляем состояние (документ изменился)
        setState(() {});
      }
    }
  }

  // Пример обработчика для обработки изображения
  void _handleProcessImage(EditorSelectionContext context) {
    if (context.type == SelectedElementType.image && context.elementIndex != null && context.imageElement != null) {
      // Получаем элемент изображения
      final imageElement = context.imageElement!;
      final elementIndex = context.elementIndex!;

      // Меняем размер изображения
      final newImageElement = imageElement.copyWith(
        width: imageElement.width * 0.8,
        height: imageElement.height * 0.8,
        caption: '${imageElement.caption} (уменьшено)',
      );

      // Обновляем элемент в документе
      setState(() {
        _document.elements[elementIndex] = newImageElement;
      });
    }
  }

  // Создаем список пользовательских иконок для тулбара
  List<Widget> _buildCustomToolbarItems() {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Применяем пользовательскую тему если нужно
    final theme = Theme.of(context).copyWith(
      extensions: [
        _useCustomTheme
            ? _getCustomBrandTheme()
            : Theme.of(context).brightness == Brightness.dark
                ? EditorThemeExtension.dark
                : EditorThemeExtension.light,
      ],
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Редактор документа' : 'Просмотр документа'),
          actions: [
            // Переключение темы
            IconButton(
              icon: Icon(_useCustomTheme ? Icons.color_lens : Icons.color_lens_outlined),
              onPressed: () {
                setState(() {
                  _useCustomTheme = !_useCustomTheme;
                });
              },
              tooltip: 'Переключить тему',
            ),
            // Переключение режима
            IconButton(
              icon: Icon(_isEditMode ? Icons.visibility : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
              tooltip: _isEditMode ? 'Просмотр' : 'Редактировать',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isEditMode
              ? CustomEditor(
                  initialDocument: _document,
                  onDocumentChanged: (newDoc) {
                    setState(() {
                      _document = newDoc;
                    });
                  },
                  enableLogging: true,
                  // Добавляем пользовательские иконки тулбара
                  customToolbarItems: _buildCustomToolbarItems(),
                  // Пример функции для преобразования файла в URL
                  fileToUrlConverter: (Uint8List fileData, String fileName) async {
                    // В реальном приложении здесь должен быть код загрузки файла на сервер
                    // и получения URL. Сейчас просто возвращаем примерную ссылку для демонстрации.

                    // Пример имитации загрузки файла
                    await Future.delayed(const Duration(seconds: 1));

                    // Для тестовых целей можно вывести размер файла
                    print('Загружаемый файл: $fileName, размер: ${fileData.length} байт');

                    // Возвращаем фиктивный URL
                    return 'https://example.com/uploaded_images/$fileName';

                    // Если возвращается null, будет использовано изображение по умолчанию
                  },
                  // Высота области редактирования (по умолчанию 750px)
                  // Если null, будет использована вся доступная высота
                  editorHeight: 500, // Можно указать конкретную высоту или null
                )
              : DocumentViewer(
                  document: _document,
                  enableLogging: false,
                  onImageTap: (String imageUrl, ImageElement imageElement) {
                    // Обработка нажатия на изображение
                    print('Нажатие на изображение: $imageUrl');
                    // Здесь можно реализовать нужный функционал
                  },
                ),
        ),
      ),
    );
  }
}

/// Как использовать редактор в вашем приложении:
/// 
/// 1. Добавьте зависимости в pubspec.yaml:
///    - В раздел dependencies добавьте пакет с редактором
/// 
/// 2. Добавьте тему в вашем приложении:
///    ```dart
///    MaterialApp(
///      theme: ThemeData(
///        // ... ваша тема ...
///        extensions: [
///          EditorThemeExtension.light, // или ваша пользовательская тема
///        ],
///      ),
///    )
///    ```
/// 
/// 3. Используйте виджеты редактора:
///    ```dart
///    // Для редактирования:
///    CustomEditor(
///      initialDocument: yourDocument,
///      onDocumentChanged: (newDoc) {
///        // Обработка изменений документа
///      },
///      // Функция для загрузки файла изображения и получения URL
///      fileToUrlConverter: (Uint8List fileData, String fileName) async {
///        // Загрузка файла на сервер и получение URL
///        return 'https://your-server.com/images/$fileName';
///      },
///      // Высота области редактирования (по умолчанию 750px)
///      // Если null, будет использована вся доступная высота
///      editorHeight: 500, // Можно указать конкретную высоту или null
///    )
///    
///    // Для просмотра:
///    DocumentViewer(
///      document: yourDocument,
///      onImageTap: (imageUrl, imageElement) {
///        // Обработка нажатия на изображение
///      },
///    )
///    ```
/// 
/// 4. Для создания собственной темы создайте экземпляр EditorThemeExtension:
///    ```dart
///    final customTheme = EditorThemeExtension(
///      backgroundColor: Colors.white,
///      // ... другие параметры ...
///    );
///    
///    // И примените его в своем виджете:
///    Theme(
///      data: Theme.of(context).copyWith(
///        extensions: [customTheme],
///      ),
///      child: CustomEditor(...),
///    )
///    ``` 