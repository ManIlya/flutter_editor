import 'package:flutter/material.dart';
import 'package:flutter_editor/flutter_editor.dart';

/// Пример использования сериализации/десериализации DocumentModel
class SerializationExample extends StatefulWidget {
  const SerializationExample({super.key});

  @override
  State<SerializationExample> createState() => _SerializationExampleState();
}

class _SerializationExampleState extends State<SerializationExample> {
  late DocumentModel _document;
  String _jsonString = '';
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    _document = _createSampleDocument();
  }

  // Создаем пример документа
  DocumentModel _createSampleDocument() {
    return DocumentModel(
      elements: [
        TextElement(
          text: 'Пример сериализации документа',
          style: TextStyleAttributes(fontSize: 24.0, bold: true, alignment: TextAlign.center),
        ),
        TextElement(
          text:
              'Этот пример показывает, как можно сериализовать и десериализовать DocumentModel для передачи через API.',
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
        TextElement(
          text: 'Для передачи документа через API, вы можете:',
          style: TextStyleAttributes(fontSize: 18.0, bold: true),
        ),
        TextElement(
          text:
              '1. Сериализовать документ в JSON строку\n2. Передать строку через API\n3. Десериализовать документ на другой стороне',
        ),
      ],
    );
  }

  // Сериализует документ в JSON строку
  void _serializeDocument() {
    // Используем метод toJson класса DocumentModel
    final jsonStr = _document.toJson();
    setState(() {
      _jsonString = jsonStr;
      _isEditing = false;
    });
  }

  // Десериализует документ из JSON строки
  void _deserializeDocument() {
    if (_jsonString.isEmpty) return;

    try {
      // Используем статический метод fromJson класса DocumentModel
      final newDocument = DocumentModel.fromJson(_jsonString);
      setState(() {
        _document = newDocument;
        _isEditing = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Документ успешно десериализован')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка десериализации: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пример сериализации'),
        actions: [
          IconButton(icon: const Icon(Icons.code), tooltip: 'Сериализовать', onPressed: _serializeDocument),
          IconButton(icon: const Icon(Icons.preview), tooltip: 'Десериализовать', onPressed: _deserializeDocument),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isEditing
                    ? CustomEditor(
                      initialDocument: _document,
                      onDocumentChanged: (document) {
                        setState(() {
                          _document = document;
                        });
                      },
                    )
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Сериализованный JSON:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: SelectableText(
                              _jsonString,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Информация о документе:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Количество элементов: ${_document.elements.length}'),
                          Text(
                            'Типы элементов: ${_document.elements.map((e) => e.type.toString().split('.').last).join(', ')}',
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => setState(() => _isEditing = true),
                            child: const Text('Вернуться к редактированию'),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
