import 'package:flutter/material.dart';
import 'package:flutter_editor/flutter_editor.dart';

/// Пример, демонстрирующий десериализацию из разных форматов (JSON, HTML, текст)
class FormatConversionExample extends StatefulWidget {
  const FormatConversionExample({super.key});

  @override
  State<FormatConversionExample> createState() => _FormatConversionExampleState();
}

class _FormatConversionExampleState extends State<FormatConversionExample> {
  late DocumentModel _document;
  final TextEditingController _inputController = TextEditingController();
  String _currentFormat = 'JSON';
  bool _isEditing = false;
  String _lastConversionResult = '';

  @override
  void initState() {
    super.initState();
    _document = _createSampleDocument();
    _updateInputText();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // Создаем пример документа
  DocumentModel _createSampleDocument() {
    return DocumentModel(
      elements: [
        TextElement(
          text: 'Пример конвертации форматов',
          style: TextStyleAttributes(fontSize: 24.0, bold: true, alignment: TextAlign.center),
        ),
        TextElement(
          text:
              'Этот пример показывает, как можно конвертировать документ между форматами JSON, HTML и обычным текстом.',
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
          ..applyStyle(TextStyleAttributes(bold: true), 17, 23)
          ..applyStyle(TextStyleAttributes(italic: true), 26, 35)
          ..applyStyle(TextStyleAttributes(link: 'https://flutter.dev'), 44, 50),
      ],
    );
  }

  // Обновляет текст в поле ввода в соответствии с текущим форматом
  void _updateInputText() {
    switch (_currentFormat) {
      case 'JSON':
        _inputController.text = _document.toJson();
        break;
      case 'HTML':
        _inputController.text = _document.toHtml();
        break;
      case 'Plain Text':
        // Преобразуем документ в простой текст
        _inputController.text =
            _document.elements.where((e) => e is TextElement).map((e) => (e as TextElement).text).join('\n\n');
        break;
    }
  }

  // Преобразует входной текст в DocumentModel в соответствии с выбранным форматом
  void _parseInput() {
    try {
      final inputText = _inputController.text;
      DocumentModel newDocument;

      switch (_currentFormat) {
        case 'JSON':
          newDocument = DocumentModel.fromJson(inputText);
          break;
        case 'HTML':
          newDocument = DocumentModel.fromHtml(inputText);
          break;
        case 'Plain Text':
          newDocument = DocumentModel.fromPlainText(inputText);
          break;
        default:
          throw Exception('Неизвестный формат: $_currentFormat');
      }

      setState(() {
        _document = newDocument;
        _isEditing = true;
        _lastConversionResult = 'Успешно преобразовано из формата $_currentFormat';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Документ успешно преобразован из $_currentFormat')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка преобразования: ${e.toString()}')));
      setState(() {
        _lastConversionResult = 'Ошибка преобразования: ${e.toString()}';
      });
    }
  }

  // Переключает режим отображения между редактором и просмотрщиком
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // Изменяет текущий формат и обновляет текст в поле ввода
  void _changeFormat(String? newFormat) {
    if (newFormat != null && newFormat != _currentFormat) {
      setState(() {
        _currentFormat = newFormat;
        _updateInputText();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конвертация форматов'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.preview_rounded : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'Режим просмотра' : 'Режим редактирования',
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель выбора формата
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Формат: '),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _currentFormat,
                  items: ['JSON', 'HTML', 'Plain Text'].map((format) {
                    return DropdownMenuItem<String>(value: format, child: Text(format));
                  }).toList(),
                  onChanged: _changeFormat,
                ),
                const Spacer(),
                if (!_isEditing) ElevatedButton(onPressed: _parseInput, child: const Text('Преобразовать')),
              ],
            ),
          ),

          // Основное содержимое
          Expanded(
            child: _isEditing
                ? CustomEditor(
                    initialDocument: _document,
                    onDocumentChanged: (document) {
                      setState(() {
                        _document = document;
                      });
                    },
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Введите или вставьте входные данные:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          height: 300,
                          child: TextField(
                            controller: _inputController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(8),
                              border: InputBorder.none,
                              hintText: 'Введите данные в выбранном формате...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Предварительный просмотр:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_lastConversionResult.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      _lastConversionResult,
                                      style: TextStyle(
                                        color: _lastConversionResult.contains('Ошибка')
                                            ? Colors.red
                                            : Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                DocumentViewer(
                                  document: _document,
                                  onImageTap: (String imageUrl, ImageElement imageElement) {
                                    // Обработка нажатия на изображение
                                    print('Нажатие на изображение: $imageUrl');
                                  },
                                  disableFloatOnNarrowScreens: true,
                                  narrowScreenThreshold: 600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _updateInputText();
                });
              },
              tooltip: 'Сохранить и просмотреть',
              child: const Icon(Icons.code),
            )
          : null,
    );
  }
}
