import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_editor/flutter_editor.dart';
import 'screens/document_preview_screen.dart';
import 'examples/serialization_example.dart';
import 'examples/format_conversion_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Создаем светлую и темную цветовые схемы
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);

    final ColorScheme darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

    // Создаем светлую тему с настроенными текстовыми стилями
    final ThemeData lightTheme = ThemeData(
      colorScheme: lightColorScheme,
      useMaterial3: true,
      // Настраиваем текстовые стили темы
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: 16.0, color: lightColorScheme.onSurface, letterSpacing: 0.3),
        headlineMedium: TextStyle(
          fontSize: 26.0,
          fontWeight: FontWeight.bold,
          color: lightColorScheme.onSurface,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.w500,
          color: lightColorScheme.onSurface,
          letterSpacing: 0.1,
        ),
      ),
    );

    // Создаем темную тему с настроенными текстовыми стилями
    final ThemeData darkTheme = ThemeData(
      colorScheme: darkColorScheme,
      useMaterial3: true,
      // Настраиваем текстовые стили темы
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: 16.0, color: darkColorScheme.onSurface, letterSpacing: 0.3),
        headlineMedium: TextStyle(
          fontSize: 26.0,
          fontWeight: FontWeight.bold,
          color: darkColorScheme.onSurface,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.w500,
          color: darkColorScheme.onSurface,
          letterSpacing: 0.1,
        ),
      ),
    );

    return MaterialApp(
      title: 'Редактор текста',
      theme: lightTheme.copyWith(
        extensions: [
          // Используем метод fromTheme для создания темы редактора на основе TextTheme
          EditorThemeExtension.fromTheme(lightTheme, borderRadius: 10.0),
        ],
      ),
      darkTheme: darkTheme.copyWith(
        extensions: [
          // Используем метод fromTheme для создания темы редактора на основе TextTheme
          EditorThemeExtension.fromTheme(darkTheme, borderRadius: 10.0),
        ],
      ),
      themeMode: ThemeMode.light,
      home: Builder(
        builder: (context) {
          final theme = EditorThemeExtension.of(context);
          return EditorPage(theme: theme);
        },
      ),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.theme});
  final EditorThemeExtension theme;
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late DocumentModel _document;
  bool _isEditMode = true; // Флаг для отслеживания текущего режима (редактирование/просмотр)
  bool _useCustomTheme = false; // Флаг для демонстрации пользовательской темы
  int _selectedColorSeed = 0; // Индекс выбранного цвета seed для colorScheme

  // Варианты цветов для демонстрации разных colorScheme
  final List<Color> _seedColors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.teal, Colors.pink];

  // Названия цветов для отображения
  final List<String> _colorNames = ['Синий', 'Зеленый', 'Фиолетовый', 'Оранжевый', 'Бирюзовый', 'Розовый'];
  @override
  void initState() {
    super.initState();
    _document = DocumentModel(
      elements: [
        TextElement(
          text: 'Демонстрация текстовых стилей',
          style: TextStyleAttributes.fromTextStyle(textStyle: widget.theme.titleTextStyle, alignment: TextAlign.center),
        ),
        TextElement(
          text:
              'Пример обычного текста в редакторе. Вы можете добавить изображение, нажав кнопку с иконкой картинки, а также добавить новый текстовый блок, нажав кнопку с иконкой текста. Выделите текст и используйте кнопки форматирования для изменения стиля.',
        ),
        TextElement(
          text: 'Это пример подзаголовка',
          style: TextStyleAttributes.fromTextStyle(
            textStyle: widget.theme.subtitleTextStyle,
            alignment: TextAlign.left,
          ),
        ),
        TextElement(
          text:
              'Система тем автоматически подстраивается под цветовую схему приложения. Вы можете изменить цвет приложения, нажав на кнопку с иконкой палитры. Также можно переключаться между системной темой и пользовательской.',
        ),
      ],
    );
  }

  void _onDocumentChanged(DocumentModel newDocument) {
    if (!mounted) return;

    bool hasChanges = false;

    if (_document.elements.length != newDocument.elements.length) {
      hasChanges = true;
    } else {
      for (int i = 0; i < _document.elements.length; i++) {
        final oldElement = _document.elements[i];
        final newElement = newDocument.elements[i];

        if (oldElement is TextElement && newElement is TextElement) {
          if (oldElement.text != newElement.text) {
            hasChanges = true;
            break;
          }
        } else {
          hasChanges = true;
          break;
        }
      }
    }

    if (hasChanges) {
      setState(() {
        _document = newDocument;
      });
    }
  }

  // Переключение между режимами редактирования и просмотра
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  // Переключение между стандартной и пользовательской темой
  void _toggleTheme() {
    setState(() {
      _useCustomTheme = !_useCustomTheme;
    });
  }

  // Сменить цвет colorScheme
  void _changeSeedColor() {
    setState(() {
      _selectedColorSeed = (_selectedColorSeed + 1) % _seedColors.length;
    });
  }

  // Переход на экран предварительного просмотра
  void _showPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => DocumentPreviewScreen(document: _document, onEditPressed: () => Navigator.of(context).pop()),
      ),
    );
  }

  // Переход на пример сериализации
  void _showSerializationExample() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SerializationExample()));
  }

  // Переход на пример форматирования
  void _showFormatConversionExample() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const FormatConversionExample()));
  }

  // Создаем пользовательскую тему для демонстрации
  EditorThemeExtension _getCustomTheme(BuildContext context) {
    return EditorThemeExtension(
      backgroundColor: const Color(0xFFFFFDF7),
      borderColor: const Color(0xFFE6DDC6),
      selectedBorderColor: const Color(0xFF678983),
      selectedBackgroundColor: const Color(0xFFE6DDC6).withOpacity(0.3),
      toolbarColor: const Color(0xFFE6DDC6),
      toolbarIconColor: const Color(0xFF181D31),
      toolbarSelectedIconColor: const Color(0xFF678983),
      captionColor: const Color(0xFF678983),
      linkColor: const Color(0xFF678983),
      placeholderColor: const Color(0xFFE6DDC6),
      floatIndicatorColor: const Color(0xFF678983).withOpacity(0.1),
      floatIndicatorTextColor: const Color(0xFF678983),
      borderRadius: 12.0,
      elementSpacing: 16.0,
      containerBorderRadius: BorderRadius.circular(12.0),
      containerShadow: const BoxShadow(color: Color(0xFFE6DDC6), offset: Offset(0, 2), blurRadius: 8.0),
      // Настраиваем стили текста для пользовательской темы
      defaultTextStyle: const TextStyle(
        fontSize: 16.0,
        color: Color(0xFF181D31),
        fontFamily: 'Georgia',
        letterSpacing: 0.5,
      ),
      titleTextStyle: const TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFF181D31),
        fontFamily: 'Georgia',
        letterSpacing: -0.5,
        height: 1.2,
      ),
      subtitleTextStyle: const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        color: Color(0xFF181D31),
        fontFamily: 'Georgia',
        letterSpacing: 0,
        fontStyle: FontStyle.italic,
      ),
      captionTextStyle: const TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 13.0,
        color: Color(0xFF678983),
        fontFamily: 'Georgia',
        letterSpacing: 0.5,
      ),
      placeholderTextStyle: TextStyle(
        color: const Color(0xFF678983).withOpacity(0.5),
        fontSize: 16.0,
        fontFamily: 'Georgia',
      ),
      floatLabelTextStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF678983),
        fontFamily: 'Georgia',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Создаем цветовую схему для текущего seedColor
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColors[_selectedColorSeed],
      brightness: Theme.of(context).brightness,
    );

    // Создаем тему в зависимости от настроек
    final theme = Theme.of(context).copyWith(
      colorScheme: colorScheme,
      extensions: [_useCustomTheme ? _getCustomTheme(context) : EditorThemeExtension.fromColorScheme(colorScheme)],
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Редактор документов - ${_colorNames[_selectedColorSeed]}'),
          actions: [
            IconButton(
              icon: Icon(_isEditMode ? Icons.preview : Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: _isEditMode ? 'Режим просмотра' : 'Режим редактирования',
            ),
            IconButton(icon: const Icon(Icons.color_lens), onPressed: _changeSeedColor, tooltip: 'Изменить цвет темы'),
            IconButton(
              icon: Icon(_useCustomTheme ? Icons.style : Icons.brightness_auto),
              onPressed: _toggleTheme,
              tooltip: _useCustomTheme ? 'Системная тема' : 'Пользовательская тема',
            ),
            if (_isEditMode)
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: _showPreview,
                tooltip: 'Открыть в отдельном окне',
              ),
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: _showSerializationExample,
              tooltip: 'Пример сериализации',
            ),
            IconButton(
              icon: const Icon(Icons.format_align_left),
              onPressed: _showFormatConversionExample,
              tooltip: 'Пример форматирования',
            ),
          ],
        ),
        body:
            _isEditMode
                ? CustomEditor(
                  initialDocument: _document,
                  onDocumentChanged: _onDocumentChanged,
                  fileToUrlConverter: (Uint8List fileData, String fileName) async {
                    // Пример имитации загрузки файла
                    await Future.delayed(const Duration(milliseconds: 800));
                    return 'https://example.com/images/$fileName';
                  },

              enableLogging: true,
                )
                : SingleChildScrollView(
                  child: Padding(padding: const EdgeInsets.all(16.0), child: DocumentViewer(document: _document)),
                ),
      ),
    );
  }
}
