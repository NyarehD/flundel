import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flundel/session/session_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionViewModelProvider);
    final viewModel = ref.read(sessionViewModelProvider.notifier);

    final durationOptions = [
      {'label': 'durations.min15'.tr(), 'seconds': 900},
      {'label': 'durations.min25'.tr(), 'seconds': 1500},
      {'label': 'durations.min45'.tr(), 'seconds': 2700},
      {'label': 'durations.min60'.tr(), 'seconds': 3600},
      {'label': 'durations.min90'.tr(), 'seconds': 5400},
      {'label': 'durations.no_end'.tr(), 'seconds': null},
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'app_title'.tr(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 24),

              // Presets selector
              Text(
                'Presets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: SoundscapePreset.builtInPresets.length,
                  itemBuilder: (context, index) {
                    final preset = SoundscapePreset.builtInPresets[index];
                    final isSelected =
                        sessionState.selectedPreset.id == preset.id;

                    return GestureDetector(
                      onTap: () => viewModel.selectPreset(preset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withValues(alpha: 0.05),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              _getPresetIcon(preset.id),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white54,
                            ),
                            Text(
                              preset.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Duration selector
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: durationOptions.map((opt) {
                  final seconds = opt['seconds'] as int?;
                  final label = opt['label'] as String;
                  final isSelected =
                      sessionState.selectedDurationSeconds == seconds;

                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => viewModel.selectDuration(seconds),
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Pomodoro toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('actions.pomodoro'.tr()),
                value: sessionState.pomodoroEnabled,
                onChanged: (val) => viewModel.togglePomodoro(val),
              ),

              const Spacer(),

              // Start Session Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: sessionState.isLoading
                      ? null
                      : () async {
                          await viewModel.startSession();
                          if (context.mounted) {
                            context.go('/focus');
                          }
                        },
                  child: sessionState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          'actions.start'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPresetIcon(String id) {
    switch (id) {
      case 'deep_work':
        return Icons.center_focus_strong;
      case 'coding':
        return Icons.code;
      case 'reading':
        return Icons.menu_book;
      case 'quiet_focus':
        return Icons.volume_off;
      case 'piano_focus':
        return Icons.piano;
      case 'night_focus':
        return Icons.nights_stay;
      default:
        return Icons.graphic_eq;
    }
  }
}
