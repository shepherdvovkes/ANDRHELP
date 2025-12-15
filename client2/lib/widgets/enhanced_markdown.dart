import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Расширенный Markdown виджет с поддержкой LaTeX, графиков и Mermaid
class EnhancedMarkdown extends StatelessWidget {
  final String data;
  final double baseFontSize;
  final TextStyle? textStyle;

  const EnhancedMarkdown({
    super.key,
    required this.data,
    required this.baseFontSize,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Обрабатываем специальные блоки перед передачей в MarkdownBody
    final processedData = _processSpecialBlocks(data);
    
    return MarkdownBody(
      data: processedData,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(fontSize: baseFontSize),
        code: TextStyle(
          fontSize: baseFontSize * 0.9,
          fontFamily: 'monospace',
          backgroundColor: Colors.grey.shade200,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        blockquote: TextStyle(
          fontSize: baseFontSize,
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade700,
        ),
        h1: TextStyle(fontSize: baseFontSize * 1.5, fontWeight: FontWeight.bold),
        h2: TextStyle(fontSize: baseFontSize * 1.3, fontWeight: FontWeight.bold),
        h3: TextStyle(fontSize: baseFontSize * 1.1, fontWeight: FontWeight.bold),
      ),
      onTapLink: (text, href, title) {
        // Можно добавить обработку ссылок
      },
    );
  }

  /// Обрабатывает специальные блоки (Mermaid, LaTeX) и заменяет их на виджеты
  String _processSpecialBlocks(String data) {
    // Пока просто возвращаем данные как есть
    // В будущем можно добавить обработку специальных блоков
    return data;
  }
}

/// Виджет для отображения блока кода с кнопкой копирования
class CodeBlockWidget extends StatelessWidget {
  final String code;
  final String? language;
  final double baseFontSize;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
    required this.baseFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != null && language!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.code, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    language!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: baseFontSize * 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    color: Colors.grey.shade400,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Код скопирован')),
                      );
                    },
                    tooltip: 'Копировать',
                  ),
                ],
              ),
            ),
          SelectableText(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: baseFontSize * 0.85,
              color: Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения Mermaid диаграммы
class MermaidBlockWidget extends StatelessWidget {
  final String mermaidCode;

  const MermaidBlockWidget({
    super.key,
    required this.mermaidCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 4),
              Text(
                'Mermaid Diagram',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            mermaidCode,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                color: Colors.blue.shade700,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: mermaidCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Код Mermaid скопирован')),
                  );
                },
                tooltip: 'Копировать',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '💡 Скопируйте код в Mermaid Live Editor для просмотра',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения LaTeX формулы
class LatexBlockWidget extends StatelessWidget {
  final String latex;
  final double baseFontSize;

  const LatexBlockWidget({
    super.key,
    required this.latex,
    required this.baseFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              latex,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: baseFontSize * 0.9,
                color: Colors.purple.shade900,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            color: Colors.purple.shade700,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: latex));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Формула скопирована')),
              );
            },
            tooltip: 'Копировать формулу',
          ),
        ],
      ),
    );
  }
}
