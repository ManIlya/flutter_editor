<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Flutter Editor

Мощный и гибкий WYSIWYG-редактор документов для Flutter с расширенными функциями форматирования и поддержкой мультимедиа.

## Возможности

* 📝 **Текстовый редактор** с расширенными возможностями форматирования
  * Жирный, курсивный, подчеркнутый текст
  * Выравнивание (по левому краю, центру, правому краю, по ширине)
  * Поддержка ссылок с автоматическим распознаванием
  * Настраиваемые размеры и цвета шрифтов
  * Возможность сброса форматирования

* 🖼️ **Работа с изображениями**
  * Загрузка изображений из галереи 
  * Вставка изображений по ссылке
  * Обтекание текстом (слева, справа, по центру)
  * Поддержка подписей к изображениям
  * Изменение размера изображений
  * Возможность отключения обтекания на узких экранах

* 📄 **Управление документами**
  * Создание, редактирование и просмотр многоэлементных документов
  * Перетаскивание элементов для изменения порядка
  * Удаление элементов
  * Богатая модель данных для представления документов

* 🎨 **Настраиваемая тема**
  * Поддержка светлой и темной темы
  * Адаптация к темам приложения через ThemeExtension
  * Множество настраиваемых параметров внешнего вида

* 🔧 **Расширяемость**
  * Поддержка пользовательских иконок в панели инструментов
  * Контекстно-зависимые действия для выделенного текста или изображения
  * Легкая интеграция в существующие приложения

* 🔄 **Сериализация данных**
  * Преобразование DocumentModel в JSON строку для хранения или передачи через API
  * Десериализация JSON строки обратно в DocumentModel
  * Сохранение всех стилей и форматирования при сериализации

## Установка

Добавьте зависимость в ваш файл `pubspec.yaml`:

```yaml
dependencies:
  flutter_editor: ^0.5.0
```

## Использование

### Настройка темы

Сначала добавьте тему редактора в ваше приложение:

```dart
MaterialApp(
  theme: ThemeData(
    // Ваши настройки темы
    extensions: [
      // Используйте встроенную светлую тему
      EditorThemeExtension.light,
    ],
  ),
  darkTheme: ThemeData(
    // Настройки темной темы
    extensions: [
      // Используйте встроенную темную тему
      EditorThemeExtension.dark,
    ],
  ),
  home: YourHomePage(),
);
```

Вы также можете создать собственную тему для редактора:

```dart
// Пример пользовательской темы
final customTheme = EditorThemeExtension(
  backgroundColor: Colors.white,
  borderColor: Colors.grey.shade200,
  selectedBorderColor: Colors.blue,
  selectedBackgroundColor: Colors.blue.withOpacity(0.1),
  toolbarColor: Colors.grey.shade50,
  toolbarIconColor: Colors.grey.shade700,
  toolbarSelectedIconColor: Colors.blue,
  captionColor: Colors.grey.shade600,
  linkColor: Colors.blue,
  // И другие параметры...
);

// Применение темы
Theme(
  data: Theme.of(context).copyWith(
    extensions: [customTheme],
  ),
  child: CustomEditor(...),
);
```

### Создание редактора

#### Базовый редактор

```dart
import 'package:flutter/material.dart';
import 'package:flutter_editor/flutter_editor.dart';
import 'dart:typed_data';

// Создаем пустую модель документа
DocumentModel document = DocumentModel(elements: [
  TextElement(text: "Начните редактирование здесь..."),
]);

// Добавляем редактор в виджет
CustomEditor(
  initialDocument: document,
  onDocumentChanged: (newDoc) {
    setState(() {
      document = newDoc;
    });
  },
  // Функция для загрузки изображений на сервер
  fileToUrlConverter: (Uint8List fileData, String fileName) async {
    // В реальном приложении здесь должен быть код загрузки файла на сервер
    // и получения URL для изображения
    return 'https://example.com/images/$fileName';
  },
)
```

#### Редактор с дополнительными опциями

```dart
CustomEditor(
  initialDocument: document,
  onDocumentChanged: (newDoc) {
    setState(() {
      document = newDoc;
    });
  },
  // Функция для загрузки изображений
  fileToUrlConverter: (Uint8List fileData, String fileName) async {
    // Загрузка файла и получение URL
    return 'https://example.com/images/$fileName';
  },
  // Включение логирования для отладки
  enableLogging: true, 
  // Фиксированная высота области редактирования
  editorHeight: 500, 
  // Пользовательские элементы панели инструментов
  customToolbarItems: [
    CustomToolbarItem(
      icon: Icons.color_lens,
      tooltip: 'Изменить цвет текста',
      onAction: (context) {
        // Ваш код обработки действия
      },
      enableOnlyWithSelection: true,
      enabledForTypes: {SelectedElementType.text},
    ),
  ],
)
```

### Просмотр документа

Для просмотра документа без возможности редактирования используйте `DocumentViewer`:

```dart
DocumentViewer(
  document: document,
  // Обработка нажатия на изображения
  onImageTap: (imageUrl, imageElement) {
    // Ваш код обработки нажатия
    print('Нажатие на изображение: $imageUrl');
  },
  // Отключить обтекание изображений текстом на узких экранах
  disableFloatOnNarrowScreens: true,
  // Пороговое значение ширины экрана в пикселях
  narrowScreenThreshold: 600,
)
```

## Структура документа

### DocumentModel

Основная модель данных, представляющая документ. Содержит список элементов:

```dart
final document = DocumentModel(elements: [
  TextElement(text: "Заголовок документа", 
    style: TextStyleAttributes(
      bold: true, 
      fontSize: 24.0
    )
  ),
  TextElement(text: "Обычный параграф текста..."),
  ImageElement(
    imageUrl: 'https://example.com/image.jpg',
    caption: 'Подпись к изображению',
    float: FCFloat.start, // Обтекание слева
    width: 300,
    height: 200,
  ),
]);
```

### TextElement

Элемент документа, содержащий текст с возможностью форматирования:

```dart
// Простой текстовый элемент
TextElement(text: "Простой текст")

// Отформатированный текст
TextElement(
  text: "Форматированный текст",
  style: TextStyleAttributes(
    bold: true,
    italic: false,
    underline: false,
    fontSize: 18.0,
    color: Colors.blue,
    alignment: TextAlign.center,
    link: "https://example.com",
  ),
)

// Текст с разными стилями через spans
TextElement(
  text: "Комбинированный текст с разными стилями",
  spans: [
    TextSpanDocument(
      text: "Комбинированный ",
      style: TextStyleAttributes(bold: true),
    ),
    TextSpanDocument(
      text: "текст с ",
      style: TextStyleAttributes(italic: true),
    ),
    TextSpanDocument(
      text: "разными стилями",
      style: TextStyleAttributes(underline: true),
    ),
  ],
)
```

### ImageElement

Элемент документа, содержащий изображение:

```dart
// Простое изображение
ImageElement(
  imageUrl: 'https://example.com/image.jpg',
)

// Изображение с дополнительными параметрами
ImageElement(
  imageUrl: 'https://example.com/image.jpg',
  caption: 'Подпись к изображению',
  float: FCFloat.start, // Обтекание слева (start, end, none)
  width: 300, // Ширина в пикселях
  height: 200, // Высота в пикселях
  sizeType: ImageSizeType.absolute, // Тип размера (absolute, percentOfScreen, original)
  sizePercent: 50, // Процент от ширины экрана (если выбран тип percentOfScreen)
)
```

## Пользовательские элементы панели инструментов

Редактор поддерживает добавление пользовательских иконок на панель инструментов с доступом к контексту выделения:

```dart
CustomToolbarItem(
  icon: Icons.format_color_text, // Иконка 
  tooltip: 'Изменить цвет текста', // Подсказка
  color: Colors.blue, // Цвет иконки (опционально)
  
  // Простой обработчик нажатия без контекста
  onPressed: () {
    // Код обработки нажатия
  },
  
  // ИЛИ обработчик с доступом к контексту выделения
  onAction: (EditorSelectionContext context) {
    // Проверка типа выделенного элемента
    if (context.type == SelectedElementType.text) {
      // Доступ к выделенному тексту
      final textElement = context.textElement!;
      final selection = context.textSelection!;
      
      // Применение стиля к выделенному тексту
      textElement.applyStyle(
        TextStyleAttributes(color: Colors.red),
        selection.start,
        selection.end
      );
    }
  },
  
  // Активация только при наличии выделения
  enableOnlyWithSelection: true,
  
  // Типы элементов, для которых доступна иконка
  enabledForTypes: {
    SelectedElementType.text,
    SelectedElementType.image,
  },
)
```

## Сериализация и десериализация документа

```dart
// Конвертация DocumentModel в JSON строку для хранения
String jsonString = documentModel.toJson();

// Восстановление из JSON
DocumentModel restoredDoc = DocumentModel.fromJson(jsonString);

// Также доступны другие форматы:
String htmlString = documentModel.toHtml(); // Конвертация в HTML
DocumentModel htmlDoc = DocumentModel.fromHtml(htmlString); // Из HTML

// Из обычного текста
DocumentModel plainTextDoc = DocumentModel.fromPlainText("Простой текст");
```

## API-документация

### Основные классы

#### CustomEditor

```dart
CustomEditor({
  required DocumentModel initialDocument,
  Function(DocumentModel)? onDocumentChanged,
  FileToUrlConverter? fileToUrlConverter,
  List<Widget>? customToolbarItems,
  bool enableLogging = false,
  double? editorHeight,
})
```

#### DocumentViewer

```dart
DocumentViewer({
  required DocumentModel document,
  Function(String, ImageElement)? onImageTap,
  bool enableLogging = false,
  bool enableFirstLineIndent = true,
  bool disableFloatOnNarrowScreens = true,
  double narrowScreenThreshold = 600,
})
```

#### EditorThemeExtension

```dart
EditorThemeExtension({
  Color backgroundColor = Colors.white,
  Color borderColor = const Color(0xFFE0E0E0),
  Color selectedBorderColor = Colors.blue,
  Color selectedBackgroundColor = const Color(0xFFE3F2FD),
  Color toolbarColor = Colors.white,
  Color toolbarIconColor = Colors.black,
  Color toolbarSelectedIconColor = Colors.blue,
  // другие параметры...
})
```

## Требования

- Flutter: `>=1.17.0`
- Dart: `>=3.0.0 <4.0.0`

## Зависимости

- float_column: `^4.0.0` - для обтекания изображений текстом
- image_picker: `^1.0.7` - для выбора изображений
- cached_network_image: `^3.3.1` - для кеширования изображений
- url_launcher: `^6.2.5` - для открытия ссылок
- html: `^0.15.4` - для парсинга HTML

## Лицензия

Проект распространяется под лицензией FITTIN.
