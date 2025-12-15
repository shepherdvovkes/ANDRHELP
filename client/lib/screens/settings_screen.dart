import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Размер шрифта',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            min: 1,
            max: 5,
            divisions: 4,
            label: settings.fontSizeLevel.toString(),
            value: settings.fontSizeLevel.toDouble(),
            onChanged: (v) => provider.setFontSizeLevel(v.round()),
          ),
          const SizedBox(height: 16),
          const Text(
            'Цветовая схема',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children: List.generate(5, (index) {
              final id = index + 1;
              final selected = id == settings.themeId;
              return ChoiceChip(
                label: Text('Тема $id'),
                selected: selected,
                onSelected: (_) => provider.setThemeId(id),
              );
            }),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Автоматический скролл'),
            value: settings.autoScrollEnabled,
            onChanged: provider.setAutoScrollEnabled,
          ),
          const SizedBox(height: 8),
          const Text(
            'Скорость авто-скролла',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            min: 0.5,
            max: 2.0,
            divisions: 6,
            label: settings.autoScrollSpeed.toStringAsFixed(1),
            value: settings.autoScrollSpeed,
            onChanged: provider.setAutoScrollSpeed,
          ),
        ],
      ),
    );
  }
}


