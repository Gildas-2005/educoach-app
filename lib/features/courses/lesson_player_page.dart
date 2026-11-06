import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/models/learning_models.dart';
import '../../core/session/learning_store.dart';
import '../../core/widgets/aurora_backdrop.dart';
import '../chat/open_chat.dart';

/// Lecteur d'une leçon, dans l'ordre :
///   1. théorie (slides)
///   2. exemples guidés
///   3. exercices interactifs avec correction affichée après réponse
///   4. écran de synthèse (XP gagné, précision)
class LessonPlayerPage extends StatefulWidget {
  const LessonPlayerPage({
    super.key,
    required this.lesson,
    required this.unit,
    required this.semester,
    required this.allSemesters,
  });

  final Lesson lesson;
  final Unit unit;
  final Semester semester;
  final List<Semester> allSemesters;

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  late final List<_Step> _steps = _buildSteps();
  int _index = 0;
  int _correctCount = 0;
  bool _finished = false;

  int get _exerciseCount => widget.lesson.exercises.length;

  List<_Step> _buildSteps() {
    final s = <_Step>[];
    for (var i = 0; i < widget.lesson.theory.length; i++) {
      s.add(
        _Step.theory(
          widget.lesson.theory[i],
          chapter: i + 1,
          total: widget.lesson.theory.length,
        ),
      );
    }
    s.add(_Step.takeaways(_keyTakeaways()));
    for (final e in widget.lesson.examples) {
      s.add(_Step.example(e));
    }
    for (var i = 0; i < widget.lesson.exercises.length; i++) {
      s.add(
        _Step.exercise(
          widget.lesson.exercises[i],
          index: i + 1,
          total: widget.lesson.exercises.length,
        ),
      );
    }
    return s;
  }

  /// Une idée-force par paragraphe de théorie : la première phrase,
  /// condensée. C'est le rappel espacé que l'étudiant retient vraiment.
  List<String> _keyTakeaways() {
    return [for (final t in widget.lesson.theory) _firstSentence(t)];
  }

  static String _firstSentence(String text) {
    final m = RegExp(r'[.!?]').firstMatch(text);
    final cut = m == null ? text : text.substring(0, m.start + 1);
    return cut.trim();
  }

  String get _phaseLabel => switch (_steps[_index].kind) {
    _StepKind.theory => 'Théorie',
    _StepKind.takeaways => 'Points clés',
    _StepKind.example => 'Exemple guidé',
    _StepKind.exercise => 'Exercice',
  };

  void _next() {
    if (_index >= _steps.length - 1) {
      setState(() => _finished = true);
      final accuracy = _exerciseCount == 0
          ? 0.0
          : _correctCount / _exerciseCount;
      final xp =
          (accuracy * widget.lesson.xpReward).round() + _correctCount * 5;
      LearningScope.of(context).recordLesson(
        widget.lesson,
        AttemptResult(
          correctCount: _correctCount,
          total: _exerciseCount,
          xpEarned: xp,
          finishedAt: DateTime.now(),
        ),
      );
      return;
    }
    setState(() => _index += 1);
  }

  void _onExerciseResult(bool correct) {
    if (correct) setState(() => _correctCount += 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_finished) {
      return _SummaryView(
        lesson: widget.lesson,
        correct: _correctCount,
        total: _exerciseCount,
      );
    }
    final step = _steps[_index];
    final progress = (_index + 1) / _steps.length;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              '${widget.unit.title} · ${widget.semester.label}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Demander au prof',
            onPressed: () => openLessonChat(
              context,
              courseCode: widget.lesson.courseCode,
              unit: widget.unit,
              lesson: widget.lesson,
            ),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      _steps[_index].kind.icon,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '$_phaseLabel · étape ${_index + 1} sur ${_steps.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()} %',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: Motion.normal,
        switchInCurve: Motion.emphasized,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: _StepView(step: step, onResult: _onExerciseResult),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: FilledButton(
            onPressed: _next,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(switch (step.kind) {
              _ when _index == _steps.length - 1 => 'Terminer la leçon',
              _StepKind.exercise => 'Exercice suivant',
              _StepKind.takeaways => 'Je passe aux exemples',
              _StepKind.example => 'Continuer',
              _StepKind.theory => 'J\'ai compris',
            }),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
//  Une étape du parcours (théorie / points clés / exemple / exercice)
// ==================================================================
enum _StepKind { theory, takeaways, example, exercise }

extension _StepKindUi on _StepKind {
  IconData get icon => switch (this) {
    _StepKind.theory => Icons.menu_book_rounded,
    _StepKind.takeaways => Icons.key_rounded,
    _StepKind.example => Icons.lightbulb_rounded,
    _StepKind.exercise => Icons.school_rounded,
  };
}

class _Step {
  _Step.theory(this.text, {required this.chapter, required int total})
    : kind = _StepKind.theory,
      example = null,
      exercise = null,
      points = null,
      totalChapters = total,
      exerciseIndex = 0,
      exerciseTotal = 0;
  _Step.takeaways(this.points)
    : kind = _StepKind.takeaways,
      text = null,
      example = null,
      exercise = null,
      chapter = 0,
      totalChapters = 0,
      exerciseIndex = 0,
      exerciseTotal = 0;
  _Step.example(this.example)
    : kind = _StepKind.example,
      text = null,
      exercise = null,
      points = null,
      chapter = 0,
      totalChapters = 0,
      exerciseIndex = 0,
      exerciseTotal = 0;
  _Step.exercise(this.exercise, {required int index, required int total})
    : kind = _StepKind.exercise,
      text = null,
      example = null,
      points = null,
      chapter = 0,
      totalChapters = 0,
      exerciseIndex = index,
      exerciseTotal = total;

  final _StepKind kind;
  final String? text;
  final Example? example;
  final Exercise? exercise;
  final List<String>? points;
  final int chapter;
  final int totalChapters;
  final int exerciseIndex;
  final int exerciseTotal;

  bool get isExercise => kind == _StepKind.exercise;
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step, required this.onResult});
  final _Step step;
  final void Function(bool correct) onResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: switch (step.kind) {
        _StepKind.theory => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionChip(
              label: 'Théorie ${step.chapter}/${step.totalChapters}',
              color: theme.colorScheme.primary,
              icon: Icons.menu_book_rounded,
            ),
            const SizedBox(height: 12),
            Text(
              step.text!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ],
        ),
        _StepKind.takeaways => _TakeawaysBody(points: step.points!),
        _StepKind.example => _ExampleBody(example: step.example!),
        _StepKind.exercise => _ExerciseCard(
          key: ValueKey(step.exercise!.id),
          exercise: step.exercise!,
          position: '${step.exerciseIndex}/${step.exerciseTotal}',
          onResult: onResult,
        ),
      },
    );
  }
}

class _TakeawaysBody extends StatelessWidget {
  const _TakeawaysBody({required this.points});
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionChip(
          label: 'Points clés à retenir',
          color: theme.colorScheme.primary,
          icon: Icons.key_rounded,
        ),
        const SizedBox(height: 6),
        Text(
          'Relis ces idées : si tu les maîtrises déjà, '
          'tu peux passer directement à la suite.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, p) in points.indexed)
          FadeSlideIn(
            delay: Duration(milliseconds: 90 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ExampleBody extends StatelessWidget {
  const _ExampleBody({required this.example});
  final Example example;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionChip(
          label: 'Exemple guidé',
          color: Color(0xFF00897B),
          icon: Icons.lightbulb_rounded,
        ),
        const SizedBox(height: 12),
        Text(
          example.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          example.body,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        if (example.code != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              example.code!,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFE2E8F0),
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
        if (example.footnote != null) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  example.footnote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

// ==================================================================
//  Carte d'exercice interactive avec correction
// ==================================================================
class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.onResult,
    this.position = '',
  });
  final Exercise exercise;
  final void Function(bool correct) onResult;
  final String position;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  final Set<String> _picked = <String>{};
  late final List<String> _ordered = _scramble(widget.exercise.orderItems);
  final TextEditingController _textCtrl = TextEditingController();
  bool _checked = false;
  bool _isCorrect = false;

  /// Mélange déterministe (graine = contenu de la liste) : un même
  /// exercice se présente toujours dans le même ordre mélangé, mais
  /// jamais dans l'ordre correct — sinon l'exercice d'ordonnancement
  /// serait gagné sans effort.
  static List<String> _scramble(List<String> items) {
    if (items.length < 2) return List.of(items);
    final rnd = math.Random(items.join().hashCode);
    final out = List<String>.of(items)..shuffle(rnd);
    final isSolved = out.every((e) => out.indexOf(e) == items.indexOf(e));
    if (isSolved) {
      final tmp = out[0];
      out[0] = out[1];
      out[1] = tmp;
    }
    return out;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  bool get _multiSelect =>
      widget.exercise.type == ExerciseType.qcm &&
      widget.exercise.options.where((o) => o.correct).length > 1;

  bool _evaluate() {
    final ex = widget.exercise;
    switch (ex.type) {
      case ExerciseType.qcm:
        final correct = ex.options
            .where((o) => o.correct)
            .map((o) => o.id)
            .toSet();
        return _picked.length == correct.length &&
            _picked.every(correct.contains);
      case ExerciseType.trueFalse:
        if (_picked.isEmpty) return false;
        return _picked.first.toLowerCase() ==
            (ex.expectedAnswer ?? '').toLowerCase();
      case ExerciseType.textInput:
      case ExerciseType.fillBlank:
        final n = _normal(_textCtrl.text);
        if (n.isEmpty) return false;
        if (ex.acceptedAnswers.any((a) => _normal(a) == n)) return true;
        return _normal(ex.expectedAnswer ?? '') == n;
      case ExerciseType.ordering:
        for (var i = 0; i < ex.orderItems.length; i++) {
          if (_ordered[i] != ex.orderItems[i]) return false;
        }
        return true;
    }
  }

  static String _normal(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r"['’]"), '');

  void _submit() {
    final ok = _evaluate();
    setState(() {
      _checked = true;
      _isCorrect = ok;
    });
    widget.onResult(ok);
  }

  bool get _canCheck {
    switch (widget.exercise.type) {
      case ExerciseType.qcm:
      case ExerciseType.trueFalse:
        return _picked.isNotEmpty;
      case ExerciseType.textInput:
      case ExerciseType.fillBlank:
        return _textCtrl.text.trim().isNotEmpty;
      case ExerciseType.ordering:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionChip(
          label: widget.position.isEmpty
              ? 'Exercice · ${_typeLabel(ex.type)}'
              : 'Exercice ${widget.position} · ${_typeLabel(ex.type)}',
          color: const Color(0xFFF4511E),
          icon: Icons.school_rounded,
        ),
        const SizedBox(height: 12),
        Text(
          ex.prompt,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        if (ex.hint != null) ...[
          const SizedBox(height: 6),
          Text(
            '💡 ${ex.hint}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _body(ex),
        const SizedBox(height: 16),
        if (!_checked)
          FilledButton.icon(
            onPressed: _canCheck ? _submit : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Vérifier'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          )
        else
          PopBounce(
            child: _CorrectionBanner(exercise: ex, correct: _isCorrect),
          ),
      ],
    );
  }

  Widget _body(Exercise ex) {
    switch (ex.type) {
      case ExerciseType.qcm:
      case ExerciseType.trueFalse:
        return Column(
          children: [
            for (final opt in ex.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionTile(
                  option: opt,
                  selected: _picked.contains(opt.id),
                  checked: _checked,
                  onTap: () {
                    if (_checked) return;
                    setState(() {
                      if (_multiSelect) {
                        if (_picked.contains(opt.id)) {
                          _picked.remove(opt.id);
                        } else {
                          _picked.add(opt.id);
                        }
                      } else {
                        _picked
                          ..clear()
                          ..add(opt.id);
                      }
                    });
                  },
                ),
              ),
          ],
        );
      case ExerciseType.textInput:
      case ExerciseType.fillBlank:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ex.blankTemplate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ex.blankTemplate!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            TextField(
              controller: _textCtrl,
              readOnly: _checked,
              decoration: const InputDecoration(
                hintText: 'Ta réponse…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case ExerciseType.ordering:
        return _OrderingBoard(
          items: _ordered,
          locked: _checked,
          expected: ex.orderItems,
          onSwap: (a, b) => setState(() {
            final tmp = _ordered[a];
            _ordered[a] = _ordered[b];
            _ordered[b] = tmp;
          }),
        );
    }
  }
}

String _typeLabel(ExerciseType t) => switch (t) {
  ExerciseType.qcm => 'Choix multiple',
  ExerciseType.trueFalse => 'Vrai / Faux',
  ExerciseType.textInput => 'Réponse libre',
  ExerciseType.ordering => 'À remettre en ordre',
  ExerciseType.fillBlank => 'À compléter',
};

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.checked,
    required this.onTap,
  });
  final ExerciseOption option;
  final bool selected;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showVerdict = checked && (selected || option.correct);
    final Color border;
    final Color bg;
    if (showVerdict) {
      if (option.correct) {
        border = const Color(0xFF2E7D32);
        bg = const Color(0xFF2E7D32).withValues(alpha: 0.12);
      } else if (selected) {
        border = const Color(0xFFC62828);
        bg = const Color(0xFFC62828).withValues(alpha: 0.10);
      } else {
        border = theme.colorScheme.outlineVariant;
        bg = Colors.white;
      }
    } else if (selected) {
      border = theme.colorScheme.primary;
      bg = theme.colorScheme.primary.withValues(alpha: 0.08);
    } else {
      border = theme.colorScheme.outlineVariant;
      bg = Colors.white;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: selected ? 2 : 1.2),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : (showVerdict && option.correct
                        ? Icons.check_circle_outline_rounded
                        : Icons.radio_button_unchecked_rounded),
              color: border,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderingBoard extends StatelessWidget {
  const _OrderingBoard({
    required this.items,
    required this.locked,
    required this.expected,
    required this.onSwap,
  });
  final List<String> items;
  final bool locked;
  final List<String> expected;
  final void Function(int a, int b) onSwap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (i, item) in items.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!locked) ...[
                  IconButton(
                    onPressed: i == 0 ? null : () => onSwap(i, i - 1),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  ),
                  IconButton(
                    onPressed: i == items.length - 1
                        ? null
                        : () => onSwap(i, i + 1),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  ),
                ] else
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CorrectionBanner extends StatelessWidget {
  const _CorrectionBanner({required this.exercise, required this.correct});
  final Exercise exercise;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return AnimatedContainer(
      duration: Motion.normal,
      curve: Motion.emphasized,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct
                    ? Icons.celebration_rounded
                    : Icons.replay_circle_filled_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Bonne réponse  ·  +${exercise.xp} XP' : 'Correction',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exercise.explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
//  Écran de synthèse
// ==================================================================
class _SummaryView extends StatefulWidget {
  const _SummaryView({
    required this.lesson,
    required this.correct,
    required this.total,
  });
  final Lesson lesson;
  final int correct;
  final int total;

  @override
  State<_SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<_SummaryView> {
  bool _celebrate = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final accuracy = widget.total == 0 ? 0.0 : widget.correct / widget.total;
    if (accuracy >= 0.6) {
      _timer = Timer(const Duration(milliseconds: 240), () {
        if (mounted) setState(() => _celebrate = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = widget.total == 0 ? 0.0 : widget.correct / widget.total;
    final passed = accuracy >= 0.6;
    final xp = (accuracy * widget.lesson.xpReward).round() + widget.correct * 5;
    final allCorrect = widget.correct == widget.total;
    return Scaffold(
      body: Stack(
        children: [
          // AuroraBackdrop fournit déjà son propre Positioned.fill :
          // le replier dans un Positioned créerait un conflit de
          // ParentDataWidgets (deux Positioned rivaux sur le même rendu).
          AuroraBackdrop(
            primary: passed ? const Color(0xFF43A047) : const Color(0xFFFB8C00),
            accentA: const Color(0xFF7C4DFF),
            accentB: const Color(0xFF00BCD4),
          ),
          if (_celebrate) const ConfettiBurst(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: PopBounce(
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: passed
                                ? [
                                    const Color(0xFF66BB6A),
                                    const Color(0xFF1B5E20),
                                  ]
                                : [
                                    const Color(0xFFFFA726),
                                    const Color(0xFFE65100),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (passed
                                          ? const Color(0xFF43A047)
                                          : const Color(0xFFFB8C00))
                                      .withValues(alpha: 0.45),
                              blurRadius: 34,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          passed
                              ? Icons.emoji_events_rounded
                              : Icons.school_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: Text(
                      passed
                          ? (allCorrect ? 'Sans faute !' : 'Leçon validée 🎉')
                          : 'Encore un petit effort',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: Text(
                      widget.lesson.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 360),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatBubble(
                          icon: Icons.bolt_rounded,
                          label: 'XP gagné',
                          value: xp.toDouble(),
                          color: const Color(0xFFF9A825),
                          delay: const Duration(milliseconds: 420),
                        ),
                        _StatBubble(
                          icon: Icons.center_focus_strong_rounded,
                          label: 'Précision',
                          value: accuracy * 100,
                          suffix: ' %',
                          color: const Color(0xFF00ACC1),
                          delay: const Duration(milliseconds: 520),
                        ),
                        _StatBubble(
                          icon: Icons.task_alt_rounded,
                          label: 'Bonnes réponses',
                          value: widget.correct.toDouble(),
                          suffix: '/${widget.total}',
                          color: const Color(0xFF43A047),
                          delay: const Duration(milliseconds: 620),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 560),
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        passed
                            ? 'Continuer mon parcours'
                            : 'Réessayer plus tard',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
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

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix = '',
    this.delay = Duration.zero,
  });
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final String suffix;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        PopBounce(
          delay: delay,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedCounter(
          value: value,
          suffix: suffix,
          delay: delay,
          duration: Motion.slow,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
