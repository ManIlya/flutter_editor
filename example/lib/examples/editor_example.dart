import 'package:flutter/material.dart' hide TextSpan;
import 'package:flutter_editor/flutter_editor.dart';
import '../editor/custom_editor.dart';

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
      ), titleTextStyle: const TextStyle(fontSize: 24.0, color: textColor, fontFamily: 'Roboto'),
     subtitleTextStyle: const TextStyle(fontSize: 32.0, color: textColor, fontFamily: 'Roboto'),
    );
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
          child:
              _isEditMode
                  ? CustomEditor(
                    initialDocument: _document,
                    onDocumentChanged: (newDoc) {
                      setState(() {
                        _document = newDoc;
                      });
                    },
                  )
                  : DocumentViewer(document: _document),
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
///    )
///    
///    // Для просмотра:
///    DocumentViewer(document: yourDocument)
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