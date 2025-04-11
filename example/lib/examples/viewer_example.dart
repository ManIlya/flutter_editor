import 'package:flutter/material.dart' hide TextSpan;
import 'package:flutter_editor/flutter_editor.dart';

/// Пример интеграции просмотрщика документов в другое приложение
class ViewerIntegrationExample extends StatelessWidget {
  const ViewerIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Пример просмотрщика документов',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        // Добавляем тему редактора
        extensions: [
          // Пользовательская тема для просмотрщика
          _getViewerTheme(),
        ],
      ),
      home: const ViewerExampleScreen(),
    );
  }

  // Пользовательская тема для просмотрщика
  EditorThemeExtension _getViewerTheme() {
    return EditorThemeExtension(
        backgroundColor: Colors.white,
        borderColor: const Color(0xFFE0E0E0),
        selectedBorderColor: Colors.teal,
        selectedBackgroundColor: Colors.teal.shade50,
        toolbarColor: Colors.white,
        toolbarIconColor: Colors.grey.shade700,
        toolbarSelectedIconColor: Colors.teal,
        captionColor: Colors.grey.shade600,
        linkColor: Colors.teal,
        placeholderColor: Colors.grey.shade200,
        floatIndicatorColor: Colors.teal.shade100,
        floatIndicatorTextColor: Colors.teal,
        borderRadius: 8.0,
        elementSpacing: 16.0,
        containerBorderRadius: BorderRadius.circular(8.0),
        containerShadow: BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 1), blurRadius: 3.0),
        defaultTextStyle: const TextStyle(fontSize: 16.0, color: Color(0xFF212121), height: 1.5),
        captionTextStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 13.0, color: Colors.grey.shade600),
        placeholderTextStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16.0),
        floatLabelTextStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
        titleTextStyle: TextStyle(fontSize: 32, color: Color(0xFF212121), height: 1.5),
        subtitleTextStyle: TextStyle(fontSize: 24.0, color: Color(0xFF212121), height: 1.5),
    );
  }
}

class ViewerExampleScreen extends StatelessWidget {
  const ViewerExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Создаем пример документа с разными элементами
    final document = _createSampleDocument();

    return Scaffold(
      appBar: AppBar(title: const Text('Просмотр документа')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // Используем просмотрщик с готовым документом
          child: DocumentViewer(document: document),
        ),
      ),
    );
  }

  // Создаем пример документа для демонстрации
  DocumentModel _createSampleDocument() {
    return DocumentModel(
      elements: [
        TextElement(
          text: 'Пример просмотрщика документов',
          style: TextStyleAttributes(fontSize: 24.0, bold: true, alignment: TextAlign.center),
        ),
        TextElement(
          text:
          'Этот пример показывает, как можно интегрировать просмотрщик документов в ваше приложение без использования редактора.',
        ),
        ImageElement(
          imageUrl: 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809',
          width: 300,
          height: 200,
          caption: 'Пример изображения с подписью',
          alignment: Alignment.center,
        ),
        TextElement(text: 'Текст с разными стилями', style: TextStyleAttributes(fontSize: 18.0, bold: true)),
        TextElement(text: 'Этот текст содержит жирный и курсивный текст, а также ссылку.')
          ..applyStyle(TextStyleAttributes(bold: true), 17, 23)..applyStyle(
            TextStyleAttributes(italic: true), 26, 35)..applyStyle(
            TextStyleAttributes(link: 'https://flutter.dev'), 44, 50),
        ImageElement(
          imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe',
          width: 150,
          height: 100,
          caption: 'Изображение с обтеканием справа',
          alignment: Alignment.centerLeft,
        ),
        TextElement(
          text:
          'Этот текст обтекает изображение слева. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam venenatis enim at arcu convallis scelerisque. Mauris rhoncus justo eu tellus gravida, vel elementum arcu volutpat. Proin feugiat lectus a risus ullamcorper, vel rhoncus mauris posuere.',
        ),
        TextElement(
          text: 'Для интеграции в ваше приложение необходимо:',
          style: TextStyleAttributes(fontSize: 18.0, bold: true),
        ),
        TextElement(
          text:
          '1. Добавить зависимость с редактором в pubspec.yaml\n2. Настроить тему с помощью EditorThemeExtension\n3. Использовать DocumentViewer для отображения документа',
        ),
      ],
    );
  }
}

/// Инструкция по интеграции просмотрщика документов:
///
/// 1. Импортируйте необходимые файлы:
///    ```dart
///    import 'package:your_package/widgets/document_viewer.dart';
///    import 'package:your_package/models/document_model.dart';
///    import 'package:your_package/theme/editor_theme.dart';
///    ```
///
/// 2. Настройте тему в MaterialApp:
///    ```dart
///    MaterialApp(
///      // ...
///      theme: ThemeData(
///        // ...
///        extensions: [
///          EditorThemeExtension.light, // или пользовательская тема
///        ],
///      ),
///    )
///    ```
///
/// 3. Используйте DocumentViewer в своем интерфейсе:
///    ```dart
///    DocumentViewer(document: yourDocument)
///    ```
///
/// 4. При необходимости примените пользовательскую тему:
///    ```dart
///    Theme(
///      data: Theme.of(context).copyWith(
///        extensions: [yourCustomTheme],
///      ),
///      child: DocumentViewer(document: yourDocument),
///    )
///    ```
