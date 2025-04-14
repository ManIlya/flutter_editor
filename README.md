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
  flutter_editor: ^0.0.1
```

## Использование

### Базовый пример редактора

```dart
import 'package:flutter/material.dart';
import 'package:flutter_editor/flutter_editor.dart';
import 'dart:typed_data';

class EditorDemo extends StatefulWidget {
  @override
  _EditorDemoState createState() => _EditorDemoState();
}

class _EditorDemoState extends State<EditorDemo> {
  // Создаем пустую модель документа
  DocumentModel document = DocumentModel(elements: [
    TextElement(text: "Начните редактирование здесь..."),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Редактор документов")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomEditor(
          initialDocument: document,
          onDocumentChanged: (newDoc) {
            setState(() {
              document = newDoc;
            });
          },
          // Функция для загрузки изображений на сервер
          fileToUrlConverter: (Uint8List fileData, String fileName) async {
            // В реальном приложении здесь должен быть код загрузки файла на сервер
            // Для примера просто возвращаем фиктивную ссылку
            return 'https://example.com/images/$fileName';
          },
        ),
      ),
    );
  }
}
```

### Настройка темы приложения

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      EditorThemeExtension.light, // Используем светлую тему редактора
    ],
  ),
  darkTheme: ThemeData(
    extensions: [
      EditorThemeExtension.dark, // Используем темную тему редактора
    ],
  ),
  home: EditorDemo(),
);
```

### Режим просмотра документа

```dart
// Для просмотра документа без возможности редактирования
DocumentViewer(
  document: yourDocumentModel,
)
```

### Добавление пользовательских иконок в тулбар

Редактор поддерживает добавление пользовательских иконок на панель инструментов, которые могут взаимодействовать с выделенным текстом или изображением:

```dart
CustomEditor(
  initialDocument: document,
  onDocumentChanged: (newDoc) => setState(() => document = newDoc),
  customToolbarItems: [
    // Иконка, работающая с выделенным текстом
    CustomToolbarItem(
      icon: Icons.format_color_text,
      tooltip: 'Изменить цвет текста',
      onAction: (context) {
        // Проверяем, что выделен текст
        if (context.hasTextSelection) {
          // Получаем элемент текста и выделение
          final textElement = context.textElement!;
          final start = context.textSelection!.start;
          final end = context.textSelection!.end;
          
          // Применяем стиль к выделенному тексту
          textElement.applyStyle(
            TextStyleAttributes(color: Colors.blue), 
            start, end
          );
          
          setState(() {}); // Обновляем UI
        }
      },
      // Активна только для выделенного текста
      enableOnlyWithSelection: true,
      enabledForTypes: {SelectedElementType.text},
    ),
    
    // Иконка для работы с изображением
    CustomToolbarItem(
      icon: Icons.photo_size_select_small,
      tooltip: 'Уменьшить размер изображения',
      onAction: (context) {
        if (context.hasImageSelection) {
          // Получаем изображение и его индекс
          final imageElement = context.imageElement!;
          final index = context.elementIndex!;
          
          // Создаем обновленное изображение с новыми размерами
          final newImage = imageElement.copyWith(
            width: imageElement.width * 0.8,
            height: imageElement.height * 0.8,
          );
          
          // Обновляем документ
          setState(() {
            document.elements[index] = newImage;
          });
        }
      },
      // Активна только для выделенного изображения
      enableOnlyWithSelection: true,
      enabledForTypes: {SelectedElementType.image},
    ),
    
    // Обычная иконка, активная всегда
    CustomToolbarItem(
      icon: Icons.info_outline,
      tooltip: 'Справка',
      onPressed: () {
        // Простое действие без контекста выделения
        showDialog(context: context, builder: (_) => AlertDialog(
          title: Text('Справка'),
          content: Text('Информация о редакторе'),
        ));
      },
    ),
  ],
)
```

## Структура документа

Документ состоит из элементов двух типов:
- `TextElement` - текстовый элемент с поддержкой форматирования через спаны
- `ImageElement` - изображение с подписью и возможностью обтекания текстом

### TextElement
Поддерживает:
- Стили форматирования (жирный, курсив, подчеркнутый)
- Размер шрифта
- Выравнивание текста
- Ссылки

### ImageElement
Поддерживает:
- Загрузку из галереи устройства
- Добавление по URL
- Выравнивание (по левому краю, по центру, по правому краю)
- Подписи
- Различные типы размеров (абсолютный, процент от экрана, оригинальный)

## API

### Основные классы

#### DocumentModel
Представляет полный документ, состоящий из элементов.

#### CustomEditor
Основной виджет редактора с полной функциональностью:

```dart
CustomEditor(
  initialDocument: documentModel, // Начальный документ
  onDocumentChanged: (newDoc) {}, // Колбэк при изменении документа
  enableLogging: false, // Включение логирования для отладки
  fileToUrlConverter: (fileData, fileName) async {
    // Функция для преобразования файла изображения в URL
    return 'https://example.com/images/$fileName';
  },
  customToolbarItems: [], // Пользовательские иконки панели инструментов
)
```

#### FileToUrlConverter
Тип функции для загрузки изображений:

```dart
typedef FileToUrlConverter = Future<String?> Function(Uint8List fileData, String fileName);
```

#### CustomToolbarItem
Настраиваемая иконка для панели инструментов:

```dart
CustomToolbarItem({
  required IconData icon,           // Иконка для отображения
  required String tooltip,          // Подсказка при наведении
  VoidCallback? onPressed,          // Простой обработчик нажатия
  CustomToolbarActionCallback? onAction, // Обработчик с контекстом
  Color? color,                     // Цвет иконки
  bool enableOnlyWithSelection = false, // Активна только при выделении
  Set<SelectedElementType> enabledForTypes = const {...}, // Для каких типов активна
})
```

#### EditorSelectionContext
Предоставляет контекст о текущем выделении для обработчика иконки:

```dart
EditorSelectionContext({
  required SelectedElementType type, // Тип выделенного элемента
  int? elementIndex,                 // Индекс элемента в документе
  TextElement? textElement,          // Выделенный текстовый элемент
  TextSelection? textSelection,      // Выделение текста
  ImageElement? imageElement,        // Выделенное изображение
})
```

#### DocumentViewer
Виджет для просмотра документа без возможности редактирования.

#### EditorThemeExtension
Позволяет настраивать внешний вид редактора и интегрировать его с темой приложения.

## Дополнительно

### Требования

- Flutter: `>=1.17.0`
- Dart: `^3.7.2`

### Зависимости

- float_column: `^4.0.0` - для обтекания изображений текстом
- image_picker: `^1.0.7` - для выбора изображений
- cached_network_image: `^3.3.1` - для кеширования изображений
- url_launcher: `^6.2.5` - для открытия ссылок

### Сериализация и десериализация документа

Для сохранения или передачи документа между приложениями вы можете использовать различные форматы данных:

#### JSON формат

```dart
// Сериализация документа в JSON строку
DocumentModel document = ...; // Ваш документ
String jsonString = document.toJson();

// Десериализация документа из JSON строки
String jsonFromApi = ...; // JSON строка, полученная из API
DocumentModel restoredDocument = DocumentModel.fromJson(jsonFromApi);
```

#### HTML формат

```dart
// Сериализация документа в HTML
DocumentModel document = ...; // Ваш документ
String htmlString = document.toHtml();

// Десериализация документа из HTML
String html = ...; // HTML-код
DocumentModel htmlDocument = DocumentModel.fromHtml(html);
```

#### Простой текст

```dart
// Десериализация документа из обычного текста
String plainText = "Заголовок\n\nПервый параграф\n\nВторой параграф";
DocumentModel textDocument = DocumentModel.fromPlainText(plainText);
```

#### Универсальный метод

Библиотека также предоставляет универсальный метод десериализации, который автоматически определяет формат входной строки:

```dart
import 'package:flutter_editor/flutter_editor.dart';

// Автоматическое определение формата и десериализация
String input = ...; // Может быть JSON, HTML или простой текст
DocumentModel document = deserializeDocumentModel(input, format: InputFormat.auto);

// Явное указание формата
DocumentModel jsonDoc = deserializeDocumentModel(jsonString, format: InputFormat.json);
DocumentModel htmlDoc = deserializeDocumentModel(htmlString, format: InputFormat.html); 
DocumentModel textDoc = deserializeDocumentModel(text, format: InputFormat.plainText);
```
