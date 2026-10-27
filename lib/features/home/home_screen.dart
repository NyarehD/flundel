import 'package:easy_localization/easy_localization.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flundel/session/session_view_model.dart';
import 'package:flundel/visualization/visualization_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionViewModelProvider);
    final viewModel = ref.read(sessionViewModelProvider.notifier);
    final selected =
        sessionState.currentSession?.preset ?? sessionState.selectedPreset;
    final selectedDuration = sessionState.isActive
        ? sessionState.currentSession?.durationSeconds
        : sessionState.selectedDurationSeconds;
    final pomodoroEnabled = sessionState.isActive
        ? sessionState.currentSession?.isPomodoro ?? false
        : sessionState.pomodoroEnabled;
    final selectionEnabled = !sessionState.isActive && !sessionState.isLoading;
    final options = [
      ('durations.min15'.tr(), 900),
      ('durations.min25'.tr(), 1500),
      ('durations.min45'.tr(), 2700),
      ('durations.min60'.tr(), 3600),
      ('durations.min90'.tr(), 5400),
      ('durations.no_end'.tr(), null),
    ];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 46,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70),
                        ),
                        child: Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'app_title'.tr().toUpperCase(),
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 3.2,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    height: constraints.maxHeight < 700 ? 188 : 226,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, entrance, child) => Opacity(
                        opacity: entrance,
                        child: Transform.scale(
                          scale: 0.985 + entrance * 0.015,
                          child: child,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 460),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Stack(
                          key: ValueKey(selected.id),
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: VisualizationWidget(
                                presetId: selected.id,
                                preview: true,
                                animatePreview: true,
                              ),
                            ),
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.12),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.72),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 15,
                              right: 16,
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'home.preview_label'.tr().toUpperCase(),
                                  maxLines: 1,
                                  softWrap: false,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9,
                                    letterSpacing: 2.1,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 15,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      alignment: Alignment.centerLeft,
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'presets.${selected.id}'.tr(),
                                        maxLines: 1,
                                        softWrap: false,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 27,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${SoundscapePreset.builtInPresets.indexWhere((preset) => preset.id == selected.id) + 1} / 06',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    height: 66,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: SoundscapePreset.builtInPresets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final preset = SoundscapePreset.builtInPresets[index];
                        final isSelected = selected.id == preset.id;
                        return Semantics(
                          button: true,
                          enabled: selectionEnabled,
                          selected: isSelected,
                          label: 'presets.${preset.id}'.tr(),
                          child: GestureDetector(
                            onTap: selectionEnabled
                                ? () => viewModel.selectPreset(preset)
                                : null,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 70,
                                minHeight: 48,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white70
                                        : Colors.white.withValues(alpha: 0.12),
                                    width: isSelected ? 1 : 0.6,
                                  ),
                                  color: const Color(0xFF080808),
                                ),
                                child: ClipRect(
                                  child: VisualizationWidget(
                                    presetId: preset.id,
                                    preview: true,
                                    animatePreview: isSelected,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 27),
                  _SectionLabel('home.duration'.tr()),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final isSelected = selectedDuration == option.$2;
                      return _DurationOption(
                        label: option.$1,
                        selected: isSelected,
                        onTap: selectionEnabled
                            ? () => viewModel.selectDuration(option.$2)
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'actions.pomodoro'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: pomodoroEnabled,
                        onChanged: selectionEnabled
                            ? viewModel.togglePomodoro
                            : null,
                        activeTrackColor: Colors.white70,
                        activeThumbColor: Colors.black,
                        inactiveTrackColor: Colors.white12,
                        inactiveThumbColor: Colors.white54,
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: sessionState.isLoading
                          ? null
                          : sessionState.isActive
                          ? () => context.go('/focus')
                          : () async {
                              await viewModel.startSession();
                              if (context.mounted &&
                                  ref.read(sessionViewModelProvider).isActive) {
                                context.go('/focus');
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white38,
                        shape: const RoundedRectangleBorder(
                          
                        ),
                        side: BorderSide.none,
                      ),
                      child: sessionState.isLoading
                          ? const SizedBox.square(
                              dimension: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.7,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              sessionState.isActive
                                  ? 'actions.return_to_session'.tr()
                                  : 'actions.start'.tr(),
                              style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {

  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: Colors.white54,
      fontSize: 9,
      letterSpacing: 2.1,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _DurationOption extends StatelessWidget {

  const _DurationOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    selected: selected,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 48, minWidth: 66),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.white70 : Colors.white24,
            width: selected ? 1 : 0.7,
          ),
          color: selected ? Colors.white : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}
