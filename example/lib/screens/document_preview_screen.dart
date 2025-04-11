import 'package:flutter/material.dart';
import 'package:flutter_editor/flutter_editor.dart';


/// Экран предварительного просмотра документа
class DocumentPreviewScreen extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onEditPressed;

  const DocumentPreviewScreen({super.key, required this.document, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр документа'),
        actions: [
          if (onEditPressed != null)
            IconButton(icon: const Icon(Icons.edit), onPressed: onEditPressed, tooltip: 'Редактировать'),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16.0), child: DocumentViewer(document: document)),
      ),
    );
  }
}
