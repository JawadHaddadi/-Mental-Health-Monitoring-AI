import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// ExercisesScreen – main hub
// ---------------------------------------------------------------------------

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({
    Key? key,
    this.onExerciseCompleted,
  }) : super(key: key);

  /// Called when a user finishes an exercise.
  /// [exerciseType] – one of "breathing", "cbt_thought_record", "grounding"
  /// [durationSeconds] – wall‑clock seconds spent on the exercise
  final void Function(String exerciseType, int durationSeconds)?
      onExerciseCompleted;

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  // Persisted in‑memory only; a real app would load from DB.
  final Map<String, DateTime?> _lastCompleted = {
    'breathing': null,
    'cbt_thought_record': null,
    'grounding': null,
    'pmr': null,
    'body_scan': null,
    'behavioral_activation': null,
  };

  static const Color _primaryTeal = Color(0xFF0891B2);

  void _markCompleted(String key, int durationSeconds) {
    setState(() {
      _lastCompleted[key] = DateTime.now();
    });
    widget.onExerciseCompleted?.call(key, durationSeconds);
  }

  // ---- helpers ----

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _formatLastCompleted(DateTime? dt) {
    if (dt == null) return 'Not yet completed';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        backgroundColor: _primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Text(
            'Choose an exercise',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black87,
                ),
          ),
          const SizedBox(height: 16),
          _exerciseCard(
            context,
            icon: Icons.air,
            title: 'Box Breathing',
            description:
                'A calming breathing technique to reduce stress and improve focus.',
            duration: '~5 min',
            lastCompleted: _lastCompleted['breathing'],
            onStart: () => _openBreathing(context),
          ),
          const SizedBox(height: 14),
          _exerciseCard(
            context,
            icon: Icons.psychology_alt,
            title: 'CBT Thought Record',
            description:
                'Challenge negative thinking patterns with a structured thought record.',
            duration: '~10 min',
            lastCompleted: _lastCompleted['cbt_thought_record'],
            onStart: () => _openCBT(context),
          ),
          const SizedBox(height: 14),
          _exerciseCard(
            context,
            icon: Icons.self_improvement,
            title: '5‑4‑3‑2‑1 Grounding',
            description:
                'Use your senses to ground yourself in the present moment.',
            duration: '~5 min',
            lastCompleted: _lastCompleted['grounding'],
            onStart: () => _openGrounding(context),
          ),
          const SizedBox(height: 14),
          _exerciseCard(
            context,
            icon: Icons.accessibility_new,
            title: 'Progressive Muscle Relaxation',
            description:
                'Systematically tense and release muscle groups to reduce physical tension and anxiety. Endorsed by the APA.',
            duration: '~10 min',
            lastCompleted: _lastCompleted['pmr'],
            onStart: () => _openPMR(context),
          ),
          const SizedBox(height: 14),
          _exerciseCard(
            context,
            icon: Icons.spa,
            title: 'Body Scan Meditation',
            description:
                'A mindfulness practice where you focus attention on each part of your body. Based on MBSR (Mindfulness-Based Stress Reduction).',
            duration: '~8 min',
            lastCompleted: _lastCompleted['body_scan'],
            onStart: () => _openBodyScan(context),
          ),
          const SizedBox(height: 14),
          _exerciseCard(
            context,
            icon: Icons.checklist,
            title: 'Behavioral Activation',
            description:
                'Plan and track enjoyable activities to combat low mood. A core technique in CBT for depression.',
            duration: '~10 min',
            lastCompleted: _lastCompleted['behavioral_activation'],
            onStart: () => _openBehavioralActivation(context),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String duration,
    required DateTime? lastCompleted,
    required VoidCallback onStart,
  }) {
    final dark = _isDark(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: dark ? Colors.grey[850] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: _primaryTeal, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: TextStyle(
                            fontSize: 13,
                            color: dark ? Colors.grey[400] : Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(duration,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 14),
                        Icon(Icons.check_circle_outline,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(_formatLastCompleted(lastCompleted),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ---- navigation ----

  Future<void> _openBreathing(BuildContext context) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const _BreathingExerciseScreen()),
    );
    if (result != null && result > 0) {
      _markCompleted('breathing', result);
    }
  }

  Future<void> _openCBT(BuildContext context) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const _CBTThoughtRecordScreen()),
    );
    if (result != null && result > 0) {
      _markCompleted('cbt_thought_record', result);
    }
  }

  Future<void> _openGrounding(BuildContext context) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const _GroundingExerciseScreen()),
    );
    if (result != null && result > 0) {
      _markCompleted('grounding', result);
    }
  }

  Future<void> _openPMR(BuildContext context) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const _PMRExerciseScreen()),
    );
    if (result != null && result > 0) {
      _markCompleted('pmr', result);
    }
  }

  Future<void> _openBodyScan(BuildContext context) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const _BodyScanScreen()),
    );
    if (result != null && result > 0) {
      _markCompleted('body_scan', result);
    }
  }

  Future<void> _openBehavioralActivation(BuildContext context) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const _BehavioralActivationScreen()),
    );
    if (result != null && result > 0) {
      _markCompleted('behavioral_activation', result);
    }
  }
}

// ===========================================================================
// 1. BREATHING EXERCISE (Box Breathing)
// ===========================================================================

class _BreathingExerciseScreen extends StatefulWidget {
  const _BreathingExerciseScreen({Key? key}) : super(key: key);

  @override
  State<_BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<_BreathingExerciseScreen>
    with TickerProviderStateMixin {
  static const Color _teal = Color(0xFF0891B2);

  // Phase durations (seconds)
  static const int _phaseDuration = 4;
  static const List<String> _phaseLabels = [
    'Inhale',
    'Hold',
    'Exhale',
    'Hold',
  ];

  late AnimationController _circleController;
  late Animation<double> _circleAnim;

  Timer? _ticker;
  bool _running = false;
  int _phaseIndex = 0; // 0‑3
  int _countdown = _phaseDuration;
  int _completedCycles = 0;
  int _totalSeconds = 0;
  Timer? _totalTimer;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _phaseDuration),
    );
    _circleAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _totalTimer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _running = true);
    _driveCircle();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _totalTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickTotal());
  }

  void _stop() {
    _ticker?.cancel();
    _totalTimer?.cancel();
    _circleController.stop();
    setState(() => _running = false);
  }

  void _reset() {
    _stop();
    setState(() {
      _phaseIndex = 0;
      _countdown = _phaseDuration;
      _completedCycles = 0;
      _totalSeconds = 0;
    });
    _circleController.reset();
  }

  void _tickTotal() {
    setState(() => _totalSeconds++);
  }

  void _tick() {
    if (_countdown > 1) {
      setState(() => _countdown--);
    } else {
      // move to next phase
      final nextPhase = (_phaseIndex + 1) % 4;
      final cycleCompleted = nextPhase == 0;
      setState(() {
        _phaseIndex = nextPhase;
        _countdown = _phaseDuration;
        if (cycleCompleted) _completedCycles++;
      });
      _driveCircle();
    }
  }

  void _driveCircle() {
    _circleController.stop();
    switch (_phaseIndex) {
      case 0: // Inhale → grow
        _circleController.forward(from: 0);
        break;
      case 1: // Hold (big)
        _circleController.value = 1.0;
        break;
      case 2: // Exhale → shrink
        _circleController.reverse(from: 1);
        break;
      case 3: // Hold (small)
        _circleController.value = 0.0;
        break;
    }
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Color _phaseColor() {
    switch (_phaseIndex) {
      case 0:
        return const Color(0xFF06B6D4);
      case 1:
        return const Color(0xFF0891B2);
      case 2:
        return const Color(0xFF0E7490);
      case 3:
        return const Color(0xFF155E75);
      default:
        return _teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Box Breathing'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // ---- animated circle ----
            AnimatedBuilder(
              animation: _circleAnim,
              builder: (context, child) {
                final size = 120 + 100 * _circleAnim.value;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _phaseColor().withOpacity(0.85),
                        _phaseColor().withOpacity(0.35),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _phaseColor().withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _phaseLabels[_phaseIndex],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_countdown',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            // ---- stats ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statChip(Icons.loop, 'Cycles', '$_completedCycles', dark),
                _statChip(Icons.timer_outlined, 'Time',
                    _formatTime(_totalSeconds), dark),
              ],
            ),
            const SizedBox(height: 28),
            // ---- controls ----
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_running)
                  _actionButton('Start', Icons.play_arrow, _start),
                if (_running) _actionButton('Stop', Icons.pause, _stop),
                const SizedBox(width: 16),
                _actionButton('Reset', Icons.restart_alt, _reset),
              ],
            ),
            const SizedBox(height: 12),
            if (_completedCycles > 0 && !_running)
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(_totalSeconds),
                icon: const Icon(Icons.check),
                label: const Text('Save & Finish'),
                style: TextButton.styleFrom(foregroundColor: _teal),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: _teal, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    );
  }
}


// ===========================================================================
// 2. CBT THOUGHT RECORD
// ===========================================================================

class _CBTThoughtRecordScreen extends StatefulWidget {
  const _CBTThoughtRecordScreen({Key? key}) : super(key: key);

  @override
  State<_CBTThoughtRecordScreen> createState() =>
      _CBTThoughtRecordScreenState();
}

class _CBTThoughtRecordScreenState extends State<_CBTThoughtRecordScreen> {
  static const Color _teal = Color(0xFF0891B2);

  int _step = 0; // 0‑3 wizard steps, 4 = review
  final _situationCtrl = TextEditingController();
  final _thoughtCtrl = TextEditingController();
  final _balancedCtrl = TextEditingController();

  String _selectedEmotion = 'Anxious';
  double _emotionIntensity = 5;

  late DateTime _startTime;

  static const List<String> _emotions = [
    'Anxious',
    'Sad',
    'Angry',
    'Frustrated',
    'Guilty',
    'Ashamed',
    'Hopeless',
    'Overwhelmed',
    'Lonely',
    'Fearful',
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _situationCtrl.dispose();
    _thoughtCtrl.dispose();
    _balancedCtrl.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_step) {
      case 0:
        return _situationCtrl.text.trim().isNotEmpty;
      case 1:
        return _thoughtCtrl.text.trim().isNotEmpty;
      case 2:
        return true; // emotion always selected
      case 3:
        return _balancedCtrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _next() {
    if (_step < 4) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _finish() {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    Navigator.of(context).pop(elapsed);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('CBT Thought Record'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: List.generate(4, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active ? _teal : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(child: _buildStep(dark)),
            // nav buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_step > 0 && _step < 4)
                    OutlinedButton(
                      onPressed: _back,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: _teal),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_step < 3)
                    ElevatedButton(
                      onPressed: _canProceed() ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                      ),
                      child: const Text('Next'),
                    ),
                  if (_step == 3)
                    ElevatedButton(
                      onPressed: _canProceed()
                          ? () {
                              _next(); // go to review
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                      ),
                      child: const Text('Review'),
                    ),
                  if (_step == 4)
                    ElevatedButton.icon(
                      onPressed: _finish,
                      icon: const Icon(Icons.check),
                      label: const Text('Save & Finish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(bool dark) {
    switch (_step) {
      case 0:
        return _textStep(
          title: 'Step 1: Situation',
          prompt: 'What happened? Describe the situation briefly.',
          controller: _situationCtrl,
          icon: Icons.event_note,
        );
      case 1:
        return _textStep(
          title: 'Step 2: Automatic Thought',
          prompt: 'What went through your mind?',
          controller: _thoughtCtrl,
          icon: Icons.chat_bubble_outline,
        );
      case 2:
        return _emotionStep(dark);
      case 3:
        return _textStep(
          title: 'Step 4: Balanced Thought',
          prompt: "What's a more balanced way to think about this?",
          controller: _balancedCtrl,
          icon: Icons.balance,
        );
      case 4:
        return _reviewStep(dark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _textStep({
    required String title,
    required String prompt,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _teal),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(prompt, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Type here...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _teal, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emotionStep(bool dark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_emotions_outlined, color: _teal),
              const SizedBox(width: 8),
              const Text('Step 3: Emotion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Select the emotion you felt and rate its intensity.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emotions.map((e) {
              final selected = e == _selectedEmotion;
              return ChoiceChip(
                label: Text(e),
                selected: selected,
                selectedColor: _teal.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selected ? _teal : (dark ? Colors.white : Colors.black87),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (_) => setState(() => _selectedEmotion = e),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Intensity: ${_emotionIntensity.round()}/10',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _emotionIntensity,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: _teal,
            label: _emotionIntensity.round().toString(),
            onChanged: (v) => setState(() => _emotionIntensity = v),
          ),
        ],
      ),
    );
  }

  Widget _reviewStep(bool dark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review Your Thought Record',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _reviewCard('Situation', _situationCtrl.text, Icons.event_note, dark),
          _reviewCard('Automatic Thought', _thoughtCtrl.text,
              Icons.chat_bubble_outline, dark),
          _reviewCard(
              'Emotion',
              '$_selectedEmotion (${_emotionIntensity.round()}/10)',
              Icons.emoji_emotions_outlined,
              dark),
          _reviewCard('Balanced Thought', _balancedCtrl.text, Icons.balance, dark),
        ],
      ),
    );
  }

  Widget _reviewCard(String label, String value, IconData icon, bool dark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: dark ? Colors.grey[850] : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _teal, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 3. GROUNDING EXERCISE (5‑4‑3‑2‑1)
// ===========================================================================

class _GroundingExerciseScreen extends StatefulWidget {
  const _GroundingExerciseScreen({Key? key}) : super(key: key);

  @override
  State<_GroundingExerciseScreen> createState() =>
      _GroundingExerciseScreenState();
}

class _GroundingExerciseScreenState extends State<_GroundingExerciseScreen>
    with TickerProviderStateMixin {
  static const Color _teal = Color(0xFF0891B2);

  late DateTime _startTime;

  // Step definitions: count, label, icon
  static const List<_GroundingStep> _steps = [
    _GroundingStep(count: 5, sense: 'SEE', icon: Icons.visibility),
    _GroundingStep(count: 4, sense: 'TOUCH', icon: Icons.pan_tool_outlined),
    _GroundingStep(count: 3, sense: 'HEAR', icon: Icons.hearing),
    _GroundingStep(count: 2, sense: 'SMELL', icon: Icons.air),
    _GroundingStep(count: 1, sense: 'TASTE', icon: Icons.restaurant),
  ];

  int _currentStep = 0;
  bool _completed = false;

  // For each step, a list of TextEditingControllers sized to that step's count
  late final List<List<TextEditingController>> _controllers;

  late AnimationController _celebrationCtrl;
  late Animation<double> _celebrationAnim;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _controllers = _steps
        .map((s) =>
            List.generate(s.count, (_) => TextEditingController()))
        .toList();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationAnim = CurvedAnimation(
        parent: _celebrationCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    for (final group in _controllers) {
      for (final c in group) {
        c.dispose();
      }
    }
    _celebrationCtrl.dispose();
    super.dispose();
  }

  bool _stepComplete() {
    return _controllers[_currentStep]
        .every((c) => c.text.trim().isNotEmpty);
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      setState(() => _completed = true);
      _celebrationCtrl.forward();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  int get _totalItems =>
      _steps.fold<int>(0, (sum, s) => sum + s.count); // 15

  int get _filledItems {
    int count = 0;
    for (int s = 0; s < _steps.length; s++) {
      for (final c in _controllers[s]) {
        if (c.text.trim().isNotEmpty) count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (_completed) return _buildCelebration(dark);

    final step = _steps[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: const Text('5‑4‑3‑2‑1 Grounding'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _filledItems / _totalItems,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  color: _teal,
                ),
              ),
            ),
            // step header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(step.icon, color: _teal, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${step.count} thing${step.count > 1 ? 's' : ''} you can ${step.sense}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Step ${_currentStep + 1} of ${_steps.length}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // inputs
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: step.count,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _controllers[_currentStep][i],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: '${step.sense} #${i + 1}',
                        prefixIcon: Icon(step.icon, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _teal, width: 2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // nav
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: _teal),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _stepComplete() ? _nextStep : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                    child: Text(_currentStep < _steps.length - 1
                        ? 'Next'
                        : 'Finish'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebration(bool dark) {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    return Scaffold(
      appBar: AppBar(
        title: const Text('5‑4‑3‑2‑1 Grounding'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ScaleTransition(
          scale: _celebrationAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _teal.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.celebration,
                      size: 48, color: _teal),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Well done!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'You completed the grounding exercise.\nTake a moment to notice how you feel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(elapsed),
                  icon: const Icon(Icons.check),
                  label: const Text('Save & Finish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper data class for grounding steps
class _GroundingStep {
  const _GroundingStep({
    required this.count,
    required this.sense,
    required this.icon,
  });

  final int count;
  final String sense;
  final IconData icon;
}

// ===========================================================================
// 4. PROGRESSIVE MUSCLE RELAXATION (PMR)
// ===========================================================================

class _PMRExerciseScreen extends StatefulWidget {
  const _PMRExerciseScreen({Key? key}) : super(key: key);

  @override
  State<_PMRExerciseScreen> createState() => _PMRExerciseScreenState();
}

class _PMRExerciseScreenState extends State<_PMRExerciseScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF5C6BC0);

  late final DateTime _startTime;
  int _currentGroup = 0;
  bool _isTensing = false;
  bool _isResting = false;
  bool _completed = false;
  Timer? _timer;
  int _secondsLeft = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const List<_MuscleGroup> _groups = [
    _MuscleGroup(
      name: 'Hands & Fists',
      icon: Icons.front_hand,
      tenseInstruction: 'Clench both fists tightly. Feel the tension in your fingers and forearms.',
      releaseInstruction: 'Let your hands go limp. Notice the warm, relaxed feeling spreading through your fingers.',
      tenseDuration: 5,
      restDuration: 10,
    ),
    _MuscleGroup(
      name: 'Upper Arms (Biceps)',
      icon: Icons.fitness_center,
      tenseInstruction: 'Bend your elbows and flex your biceps as hard as you can.',
      releaseInstruction: 'Let your arms drop and relax completely. Feel the difference between tension and relaxation.',
      tenseDuration: 5,
      restDuration: 10,
    ),
    _MuscleGroup(
      name: 'Shoulders',
      icon: Icons.accessibility_new,
      tenseInstruction: 'Raise your shoulders up toward your ears as high as possible.',
      releaseInstruction: 'Drop your shoulders down. Let all the tension melt away from your neck and shoulders.',
      tenseDuration: 5,
      restDuration: 10,
    ),
    _MuscleGroup(
      name: 'Face & Jaw',
      icon: Icons.face,
      tenseInstruction: 'Scrunch your entire face — squeeze eyes shut, wrinkle nose, clench jaw.',
      releaseInstruction: 'Relax your face completely. Let your jaw hang slightly open, smooth your forehead.',
      tenseDuration: 5,
      restDuration: 10,
    ),
    _MuscleGroup(
      name: 'Stomach',
      icon: Icons.circle,
      tenseInstruction: 'Tighten your stomach muscles as if bracing for impact.',
      releaseInstruction: 'Release your stomach. Let your breathing flow naturally and deeply.',
      tenseDuration: 5,
      restDuration: 10,
    ),
    _MuscleGroup(
      name: 'Upper Legs (Thighs)',
      icon: Icons.airline_seat_legroom_normal,
      tenseInstruction: 'Press your knees together and tighten your thigh muscles.',
      releaseInstruction: 'Let your legs relax and fall apart naturally. Notice the heaviness.',
      tenseDuration: 5,
      restDuration: 10,
    ),
    _MuscleGroup(
      name: 'Feet & Toes',
      icon: Icons.do_not_step,
      tenseInstruction: 'Curl your toes tightly and press your feet downward.',
      releaseInstruction: 'Release your toes and let your feet relax. Feel the warmth flowing through them.',
      tenseDuration: 5,
      restDuration: 10,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTense() {
    final group = _groups[_currentGroup];
    setState(() {
      _isTensing = true;
      _isResting = false;
      _secondsLeft = group.tenseDuration;
    });
    _pulseController.repeat(reverse: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        _startRelease();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startRelease() {
    final group = _groups[_currentGroup];
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isTensing = false;
      _isResting = true;
      _secondsLeft = group.restDuration;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        _onGroupDone();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onGroupDone() {
    if (_currentGroup < _groups.length - 1) {
      setState(() {
        _currentGroup++;
        _isTensing = false;
        _isResting = false;
      });
    } else {
      setState(() => _completed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_completed) return _buildCelebration(dark);
    final group = _groups[_currentGroup];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progressive Muscle Relaxation'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF5F5FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress
              Row(
                children: List.generate(_groups.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i < _currentGroup
                            ? _accent
                            : i == _currentGroup
                                ? _accent.withOpacity(0.5)
                                : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${_currentGroup + 1} of ${_groups.length}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const Spacer(),
              // Icon
              ScaleTransition(
                scale: _isTensing ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isTensing
                        ? Colors.red.withOpacity(0.15)
                        : _isResting
                            ? Colors.green.withOpacity(0.15)
                            : _accent.withOpacity(0.12),
                  ),
                  child: Icon(
                    group.icon,
                    size: 48,
                    color: _isTensing
                        ? Colors.red
                        : _isResting
                            ? Colors.green
                            : _accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                group.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (!_isTensing && !_isResting)
                Text(
                  'Tap "Tense" when you\'re ready to begin this muscle group.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              if (_isTensing) ...[
                Text(
                  'TENSE — Hold it!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.tenseInstruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_secondsLeft',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
              ],
              if (_isResting) ...[
                Text(
                  'RELAX — Let go…',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.releaseInstruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_secondsLeft',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                  ),
                ),
              ],
              const Spacer(),
              if (!_isTensing && !_isResting)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startTense,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Tense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration(bool dark) {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progressive Muscle Relaxation'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.15),
                ),
                child: const Icon(Icons.celebration, size: 48, color: _accent),
              ),
              const SizedBox(height: 24),
              const Text(
                'Feeling Relaxed!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You completed all ${_groups.length} muscle groups.\nNotice how your body feels lighter and calmer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(elapsed),
                icon: const Icon(Icons.check),
                label: const Text('Save & Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuscleGroup {
  const _MuscleGroup({
    required this.name,
    required this.icon,
    required this.tenseInstruction,
    required this.releaseInstruction,
    required this.tenseDuration,
    required this.restDuration,
  });

  final String name;
  final IconData icon;
  final String tenseInstruction;
  final String releaseInstruction;
  final int tenseDuration;
  final int restDuration;
}

// ===========================================================================
// 5. BODY SCAN MEDITATION
// ===========================================================================

class _BodyScanScreen extends StatefulWidget {
  const _BodyScanScreen({Key? key}) : super(key: key);

  @override
  State<_BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<_BodyScanScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF7E57C2);

  late final DateTime _startTime;
  int _currentRegion = 0;
  bool _isPaused = false;
  bool _completed = false;
  Timer? _timer;
  int _secondsLeft = 0;

  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  static const List<_BodyRegion> _regions = [
    _BodyRegion(
      name: 'Top of Head',
      instruction: 'Bring your attention to the very top of your head. Notice any sensations — tingling, warmth, pressure, or nothing at all. Simply observe without judgment.',
      duration: 30,
      icon: Icons.circle,
    ),
    _BodyRegion(
      name: 'Face & Forehead',
      instruction: 'Move your awareness down to your forehead, eyes, cheeks, and jaw. Notice if you\'re holding any tension. Allow the muscles to soften.',
      duration: 30,
      icon: Icons.face,
    ),
    _BodyRegion(
      name: 'Neck & Throat',
      instruction: 'Shift attention to your neck and throat. This area often holds stress. Breathe gently and let any tightness dissolve.',
      duration: 25,
      icon: Icons.accessibility,
    ),
    _BodyRegion(
      name: 'Shoulders & Upper Back',
      instruction: 'Notice your shoulders. Are they raised or tense? Let them drop naturally. Feel the weight of your arms pulling them down gently.',
      duration: 30,
      icon: Icons.accessibility_new,
    ),
    _BodyRegion(
      name: 'Arms & Hands',
      instruction: 'Scan down through your upper arms, elbows, forearms, wrists, and fingers. Notice the temperature, any tingling, or the feeling of contact with surfaces.',
      duration: 25,
      icon: Icons.front_hand,
    ),
    _BodyRegion(
      name: 'Chest & Heart',
      instruction: 'Bring awareness to your chest. Feel the gentle rise and fall with each breath. Notice your heartbeat. Send kindness to this area.',
      duration: 30,
      icon: Icons.favorite,
    ),
    _BodyRegion(
      name: 'Stomach & Core',
      instruction: 'Move attention to your belly. Allow it to be soft. Notice the movement of breath here — expanding on the inhale, settling on the exhale.',
      duration: 30,
      icon: Icons.circle_outlined,
    ),
    _BodyRegion(
      name: 'Lower Back & Hips',
      instruction: 'Notice your lower back and hips. Feel the contact with the surface beneath you. Breathe into any areas of discomfort.',
      duration: 25,
      icon: Icons.event_seat,
    ),
    _BodyRegion(
      name: 'Legs & Knees',
      instruction: 'Scan through your thighs, knees, and shins. Notice sensations of heaviness, lightness, or warmth moving through your legs.',
      duration: 25,
      icon: Icons.airline_seat_legroom_normal,
    ),
    _BodyRegion(
      name: 'Feet & Toes',
      instruction: 'Bring your focus to the soles of your feet and each toe. Feel the grounding connection to the earth beneath you.',
      duration: 30,
      icon: Icons.do_not_step,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _startRegionTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _startRegionTimer() {
    _secondsLeft = _regions[_currentRegion].duration;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPaused) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        _advanceRegion();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _advanceRegion() {
    if (_currentRegion < _regions.length - 1) {
      setState(() => _currentRegion++);
      _startRegionTimer();
    } else {
      setState(() => _completed = true);
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_completed) return _buildCelebration(dark);
    final region = _regions[_currentRegion];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Scan Meditation'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF5F0FF),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: List.generate(_regions.length, (i) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: i < _currentRegion
                                ? _accent
                                : i == _currentRegion
                                    ? _accent.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.25),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Region ${_currentRegion + 1} of ${_regions.length}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Breathing circle
            ScaleTransition(
              scale: _breathAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.12),
                  border: Border.all(color: _accent.withOpacity(0.3), width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(region.icon, color: _accent, size: 36),
                    const SizedBox(height: 4),
                    Text(
                      '$_secondsLeft s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                region.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                region.instruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: dark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            const Spacer(),
            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentRegion > 0)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentRegion--;
                          _startRegionTimer();
                        });
                      },
                      icon: const Icon(Icons.skip_previous, size: 32),
                      color: _accent,
                    ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    onPressed: _togglePause,
                    backgroundColor: _accent,
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _advanceRegion,
                    icon: const Icon(Icons.skip_next, size: 32),
                    color: _accent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebration(bool dark) {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Scan Meditation'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.15),
                ),
                child: const Icon(Icons.spa, size: 48, color: _accent),
              ),
              const SizedBox(height: 24),
              const Text(
                'Scan Complete',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ve scanned your entire body from head to toe.\nCarry this awareness with you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(elapsed),
                icon: const Icon(Icons.check),
                label: const Text('Save & Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyRegion {
  const _BodyRegion({
    required this.name,
    required this.instruction,
    required this.duration,
    required this.icon,
  });

  final String name;
  final String instruction;
  final int duration;
  final IconData icon;
}

// ===========================================================================
// 6. BEHAVIORAL ACTIVATION
// ===========================================================================

class _BehavioralActivationScreen extends StatefulWidget {
  const _BehavioralActivationScreen({Key? key}) : super(key: key);

  @override
  State<_BehavioralActivationScreen> createState() =>
      _BehavioralActivationScreenState();
}

class _BehavioralActivationScreenState
    extends State<_BehavioralActivationScreen> {
  static const Color _accent = Color(0xFF26A69A);

  late final DateTime _startTime;
  int _step = 0; // 0 = intro, 1 = rate current mood, 2 = pick activities, 3 = plan, 4 = summary
  double _currentMood = 3;
  double _expectedMood = 5;
  final List<_ActivityItem> _activities = [];
  final TextEditingController _customActivityCtrl = TextEditingController();
  final TextEditingController _whenCtrl = TextEditingController();

  static const List<String> _suggestedActivities = [
    'Go for a short walk',
    'Call or text a friend',
    'Listen to favorite music',
    'Cook a simple meal',
    'Tidy one room',
    'Read for 15 minutes',
    'Stretch or light yoga',
    'Take a warm shower',
    'Write in a journal',
    'Watch something funny',
    'Visit a park or garden',
    'Draw or doodle',
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _customActivityCtrl.dispose();
    _whenCtrl.dispose();
    super.dispose();
  }

  void _addActivity(String name) {
    if (_activities.any((a) => a.name == name)) return;
    setState(() {
      _activities.add(_ActivityItem(name: name));
    });
  }

  void _removeActivity(int index) {
    setState(() => _activities.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Activation'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF0FAF8),
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return Container(
                    width: i == _step ? 24 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: i <= _step ? _accent : Colors.grey.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStep(dark),
              ),
            ),
            // Navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _canAdvance() ? _advance : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    child: Text(_step < 4 ? 'Next' : 'Save & Finish'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAdvance() {
    if (_step == 2 && _activities.isEmpty) return false;
    return true;
  }

  void _advance() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      final elapsed = DateTime.now().difference(_startTime).inSeconds;
      Navigator.of(context).pop(elapsed);
    }
  }

  Widget _buildStep(bool dark) {
    switch (_step) {
      case 0:
        return _buildIntro(dark);
      case 1:
        return _buildMoodRating(dark);
      case 2:
        return _buildActivitySelection(dark);
      case 3:
        return _buildPlan(dark);
      case 4:
        return _buildSummary(dark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntro(bool dark) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withOpacity(0.12),
          ),
          child: const Icon(Icons.checklist, size: 40, color: _accent),
        ),
        const SizedBox(height: 24),
        const Text(
          'Behavioral Activation',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'When we feel low, we tend to withdraw from activities that once brought us joy. '
          'This creates a cycle — less activity leads to lower mood, which leads to even less activity.\n\n'
          'Behavioral Activation, a core CBT technique, breaks this cycle by helping you plan '
          'and engage in meaningful activities, even when motivation is low.\n\n'
          'Research shows this is one of the most effective treatments for depression.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: dark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMoodRating(bool dark) {
    const moods = ['Very Low', 'Low', 'Neutral', 'Good', 'Very Good'];
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'How are you feeling right now?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Rate your current mood before we begin.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 40),
        Text(
          moods[_currentMood.round() - 1],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _accent,
          ),
        ),
        Slider(
          value: _currentMood,
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: _accent,
          label: moods[_currentMood.round() - 1],
          onChanged: (v) => setState(() => _currentMood = v),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Very Low', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            Text('Very Good', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActivitySelection(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Choose Activities',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick activities you\'d like to try, even if you don\'t feel like doing them right now. '
          'The goal is to start small.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        // Selected activities
        if (_activities.isNotEmpty) ...[
          Text(
            'Your activities (${_activities.length}):',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...List.generate(_activities.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: _accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _activities[i].name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeActivity(i),
                      child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        // Suggestions
        Text(
          'Suggestions:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedActivities.map((a) {
            final selected = _activities.any((item) => item.name == a);
            return ActionChip(
              label: Text(
                a,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white : null,
                ),
              ),
              backgroundColor: selected ? _accent : null,
              onPressed: () {
                if (selected) {
                  final idx = _activities.indexWhere((item) => item.name == a);
                  if (idx >= 0) _removeActivity(idx);
                } else {
                  _addActivity(a);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Custom activity
        TextField(
          controller: _customActivityCtrl,
          decoration: InputDecoration(
            labelText: 'Add your own activity',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final text = _customActivityCtrl.text.trim();
                if (text.isNotEmpty) {
                  _addActivity(text);
                  _customActivityCtrl.clear();
                }
              },
            ),
          ),
          onSubmitted: (text) {
            if (text.trim().isNotEmpty) {
              _addActivity(text.trim());
              _customActivityCtrl.clear();
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPlan(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Make a Plan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'For each activity, set when you\'d like to do it. '
          'Being specific helps you follow through.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Text(
          'How good do you expect to feel after doing these?',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _expectedMood,
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: _accent,
          label: '${_expectedMood.round()}/10',
          onChanged: (v) => setState(() => _expectedMood = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Not much', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            Text('Much better', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _whenCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'When will you do these? (e.g. "Tomorrow after work")',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSummary(bool dark) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withOpacity(0.15),
          ),
          child: const Icon(Icons.thumb_up, size: 40, color: _accent),
        ),
        const SizedBox(height: 24),
        const Text(
          'You Have a Plan!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_activities.length} activities planned:',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ..._activities.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: _accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a.name, style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  )),
              if (_whenCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'When: ${_whenCtrl.text.trim()}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Expected mood improvement: ${_expectedMood.round()}/10',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Remember: you don\'t need to feel motivated to start. '
          'Action often comes before motivation, not after.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: dark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ActivityItem {
  _ActivityItem({required this.name});
  final String name;
}
