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
  * Выравнивание (по левому краю, центру, правому краю)
  * Поддержка ссылок с автоматическим распознаванием
  * Настраиваемые размеры и цвета шрифтов

* 🖼️ **Работа с изображениями**
  * Загрузка изображений из галереи или камеры
  * Изменение размера и пропорций изображений
  * Обтекание текстом слева и справа
  * Поддержка подписей к изображениям

* 📄 **Управление документами**
  * Создание, редактирование и просмотр многоэлементных документов
  * Серверная синхронизация (опционально)
  * Богатая модель данных для представления документов

* 🎨 **Настраиваемая тема**
  * Поддержка светлой и темной темы
  * Адаптация к темам приложения через ThemeExtension
  * Множество настраиваемых параметров внешнего вида

## Установка

Добавьте зависимость в ваш файл `pubspec.yaml`:

```yaml
dependencies:
  flutter_editor: ^0.0.1
```

## Использование

### Базовый пример

```dart
import 'package:flutter/material.dart';
import 'package:flutter_editor/flutter_editor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  }
}

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
      body: Column(
        children: [
          // Панель инструментов
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: EditorToolbar(
              onBoldPressed: () {
                // Логика для форматирования выделенного текста
              },
              onItalicPressed: () {
                // Логика для форматирования выделенного текста
              },
              onUnderlinePressed: () {
                // Логика для форматирования выделенного текста
              },
              onAddImagePressed: () {
                // Логика для добавления изображения
              },
              onAddTextPressed: () {
                // Логика для добавления текстового блока
              },
            ),
          ),
          
          // Редактор документа
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: // Здесь ваша логика для отображения редактора
            ),
          ),
        ],
      ),
    );
  }
}
```

### Режим просмотра документа

```dart
// Для просмотра документа без возможности редактирования
DocumentViewer(
  document: yourDocumentModel,
)
```

## Структура документа

Документ состоит из элементов двух типов:
- `TextElement` - текстовый элемент с поддержкой форматирования
- `ImageElement` - изображение с подписью и возможностью обтекания текстом

Каждый текстовый элемент поддерживает различные стили через `TextStyleAttributes`.

## API

### Основные классы

#### DocumentModel
Представляет полный документ, состоящий из элементов.

#### TextElement
Представляет текстовый блок с поддержкой стилей и форматирования.

#### ImageElement
Представляет изображение с подписью и настройками отображения.

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
