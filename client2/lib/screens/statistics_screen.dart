import 'dart:async';
import 'package:flutter/material.dart';
import '../models/statistics.dart';
import '../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statsService = StatisticsService();
  Statistics? _statistics;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    // Обновляем статистику каждые 2 секунды
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadStatistics();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final stats = await _statsService.getStatistics();
    if (mounted) {
      setState(() {
        _statistics = stats;
      });
    }
  }

  Future<void> _resetStatistics() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс статистики'),
        content: const Text('Вы уверены, что хотите сбросить всю статистику?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _statsService.resetStatistics();
      await _loadStatistics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статистика сброшена')),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statistics ?? Statistics.empty();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _resetStatistics,
            tooltip: 'Сбросить статистику',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Google Speech-to-Text API
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Google Speech-to-Text API',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Прямое подключение к speech.googleapis.com',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Отправлено',
                    value: _formatBytes(stats.speechToTextSentBytes),
                    icon: Icons.upload,
                  ),
                  _StatRow(
                    label: 'Получено',
                    value: _formatBytes(stats.speechToTextReceivedBytes),
                    icon: Icons.download,
                  ),
                  _StatRow(
                    label: 'Всего',
                    value: _formatBytes(
                      stats.speechToTextSentBytes +
                          stats.speechToTextReceivedBytes,
                    ),
                    icon: Icons.data_usage,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // OpenAI API
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.smart_toy, color: Colors.green),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'OpenAI API',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Прямое подключение к api.openai.com',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Отправлено',
                    value: _formatBytes(stats.openAiSentBytes),
                    icon: Icons.upload,
                  ),
                  _StatRow(
                    label: 'Получено',
                    value: _formatBytes(stats.openAiReceivedBytes),
                    icon: Icons.download,
                  ),
                  _StatRow(
                    label: 'Всего',
                    value: _formatBytes(
                      stats.openAiSentBytes + stats.openAiReceivedBytes,
                    ),
                    icon: Icons.data_usage,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Распознавание
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_fields, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Распознавание',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Вопросов распознано',
                    value: stats.questionsDetected.toString(),
                    icon: Icons.help_outline,
                  ),
                  _StatRow(
                    label: 'Предложений распознано',
                    value: stats.sentencesRecognized.toString(),
                    icon: Icons.format_quote,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Информация
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _StatRow(
                    label: 'Последнее обновление',
                    value: _formatDateTime(stats.lastUpdated),
                    icon: Icons.access_time,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Кнопка сброса
          Center(
            child: ElevatedButton.icon(
              onPressed: _resetStatistics,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Сбросить всю статистику'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} сек назад';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ч назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} '
          '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

