import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/db_helper.dart';
import '../models/assessment.dart';
import 'assessment_history_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({Key? key}) : super(key: key);

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  // ── Question banks ──────────────────────────────────────────────────
  final List<String> _phq9Questions = [
    "Little interest or pleasure in doing things",
    "Feeling down, depressed, or hopeless",
    "Trouble falling or staying asleep, or sleeping too much",
    "Feeling tired or having little energy",
    "Poor appetite or overeating",
    "Feeling bad about yourself — or that you are a failure or have let yourself or your family down",
    "Trouble concentrating on things, such as reading the newspaper or watching television",
    "Moving or speaking so slowly that other people could have noticed — or being so fidgety or restless that you have been moving around a lot more than usual",
    "Thoughts that you would be better off dead, or thoughts of hurting yourself in some way",
  ];

  final List<String> _gad7Questions = [
    "Feeling nervous, anxious, or on edge",
    "Not being able to stop or control worrying",
    "Worrying too much about different things",
    "Trouble relaxing",
    "Being so restless that it is hard to sit still",
    "Becoming easily annoyed or irritable",
    "Feeling afraid, as if something awful might happen",
  ];

  // PSS-10: Perceived Stress Scale
  final List<String> _pss10Questions = [
    "In the last month, how often have you been upset because of something that happened unexpectedly?",
    "In the last month, how often have you felt that you were unable to control the important things in your life?",
    "In the last month, how often have you felt nervous and stressed?",
    "In the last month, how often have you felt confident about your ability to handle your personal problems?",
    "In the last month, how often have you felt that things were going your way?",
    "In the last month, how often have you found that you could not cope with all the things that you had to do?",
    "In the last month, how often have you been able to control irritations in your life?",
    "In the last month, how often have you felt that you were on top of things?",
    "In the last month, how often have you been angered because of things that happened that were outside of your control?",
    "In the last month, how often have you felt difficulties were piling up so high that you could not overcome them?",
  ];

  // PSS-10 reverse-scored items (questions 4, 5, 7, 8 — zero-indexed: 3, 4, 6, 7)
  static const _pss10ReverseItems = {3, 4, 6, 7};

  // WHO-5: Well-Being Index
  final List<String> _who5Questions = [
    "I have felt cheerful and in good spirits",
    "I have felt calm and relaxed",
    "I have felt active and vigorous",
    "I woke up feeling fresh and rested",
    "My daily life has been filled with things that interest me",
  ];

  // DASS-21: Depression Anxiety Stress Scales
  final List<String> _dass21Questions = [
    // Depression subscale (items 3, 5, 10, 13, 16, 17, 21 in original — zero-indexed here)
    "I found it hard to wind down",                                    // S
    "I was aware of dryness of my mouth",                              // A
    "I couldn't seem to experience any positive feeling at all",       // D
    "I experienced breathing difficulty",                               // A
    "I found it difficult to work up the initiative to do things",     // D
    "I tended to over-react to situations",                            // S
    "I experienced trembling (e.g., in the hands)",                    // A
    "I felt that I was using a lot of nervous energy",                 // S
    "I was worried about situations in which I might panic",           // A
    "I felt that I had nothing to look forward to",                    // D
    "I found myself getting agitated",                                  // S
    "I found it difficult to relax",                                    // S
    "I felt down-hearted and blue",                                     // D
    "I was intolerant of anything that kept me from getting on",       // S
    "I felt I was close to panic",                                      // A
    "I was unable to become enthusiastic about anything",              // D
    "I felt I wasn't worth much as a person",                          // D
    "I felt that I was rather touchy",                                  // S
    "I was aware of the action of my heart (in absence of exercise)", // A
    "I felt scared without any good reason",                           // A
    "I felt that life was meaningless",                                 // D
  ];

  // DASS-21 subscale indices (0-indexed)
  // Depression: 2, 4, 9, 12, 15, 16, 20
  // Anxiety: 1, 3, 6, 8, 14, 18, 19
  // Stress: 0, 5, 7, 10, 11, 13, 17
  static const _dass21Depression = {2, 4, 9, 12, 15, 16, 20};
  static const _dass21Anxiety = {1, 3, 6, 8, 14, 18, 19};
  static const _dass21Stress = {0, 5, 7, 10, 11, 13, 17};

  List<String> get _questions {
    switch (_selectedTest) {
      case 'PHQ-9': return _phq9Questions;
      case 'GAD-7': return _gad7Questions;
      case 'PSS-10': return _pss10Questions;
      case 'WHO-5': return _who5Questions;
      case 'DASS-21': return _dass21Questions;
      default: return _phq9Questions;
    }
  }

  // ── Answer options per test ─────────────────────────────────────────
  List<Map<String, dynamic>> get _options {
    switch (_selectedTest) {
      case 'PSS-10':
        return [
          {'label': 'Never', 'score': 0},
          {'label': 'Almost never', 'score': 1},
          {'label': 'Sometimes', 'score': 2},
          {'label': 'Fairly often', 'score': 3},
          {'label': 'Very often', 'score': 4},
        ];
      case 'WHO-5':
        return [
          {'label': 'At no time', 'score': 0},
          {'label': 'Some of the time', 'score': 1},
          {'label': 'Less than half the time', 'score': 2},
          {'label': 'More than half the time', 'score': 3},
          {'label': 'Most of the time', 'score': 4},
          {'label': 'All of the time', 'score': 5},
        ];
      case 'DASS-21':
        return [
          {'label': 'Did not apply to me at all', 'score': 0},
          {'label': 'Applied to me some degree', 'score': 1},
          {'label': 'Applied to me a considerable degree', 'score': 2},
          {'label': 'Applied to me very much', 'score': 3},
        ];
      default: // PHQ-9 and GAD-7
        return [
          {'label': 'Not at all', 'score': 0},
          {'label': 'Several days', 'score': 1},
          {'label': 'More than half the days', 'score': 2},
          {'label': 'Nearly every day', 'score': 3},
        ];
    }
  }

  // ── State variables ─────────────────────────────────────────────────
  bool _testSelected = false;
  String _selectedTest = '';

  int _currentPage = 0;
  late List<int> _answers;
  late PageController _pageController;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _answers = [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────
  void _selectTest(String testName) {
    final questionCounts = {
      'PHQ-9': 9, 'GAD-7': 7, 'PSS-10': 10, 'WHO-5': 5, 'DASS-21': 21,
    };
    setState(() {
      _selectedTest = testName;
      _testSelected = true;
      _currentPage = 0;
      _showResults = false;
      _answers = List.filled(questionCounts[testName] ?? 9, -1);
      _pageController = PageController();
    });
  }

  void _onOptionSelected(int questionIndex, int score) {
    setState(() {
      _answers[questionIndex] = score;
    });

    // Crisis check: PHQ-9 question 9 (index 8) — self-harm
    if (_selectedTest == 'PHQ-9' && questionIndex == 8 && score > 0) {
      // Show crisis dialog immediately, auto-advance happens after dialog closes
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _showCrisisDialog();
      });
      return;
    }

    // Auto-advance after 400ms
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (questionIndex < _questions.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ── Crisis Dialog (Step 2) ──────────────────────────────────────────
  void _showCrisisDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'We noticed something important',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your answer suggests you may be having thoughts of '
                'self-harm. Please know you are not alone. '
                'Reach out for help immediately.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 20),
              // Crisis numbers card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crisis Helplines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPhoneRow(
                      '🇸🇦',
                      'KSA — Ministry of Health',
                      '920033360',
                    ),
                    const SizedBox(height: 10),
                    _buildPhoneRow(
                      '🌍',
                      'Global Helplines Directory',
                      'findahelpline.com',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // "Get Help Now" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // In production: launch phone dialer with url_launcher
                },
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Get Help Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // "I'm Safe, Continue" button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Continue the test — no auto-advance since this is the last question,
                  // user can tap "See Results" manually.
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("I'm Safe, Continue"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneRow(String flag, String label, String number) {
    return Row(
      children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Text(
                number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Compute the total score, handling reverse-scored items for PSS-10.
  int _computeScore() {
    if (_selectedTest == 'PSS-10') {
      int total = 0;
      for (int i = 0; i < _answers.length; i++) {
        if (_pss10ReverseItems.contains(i)) {
          total += (4 - _answers[i]); // reverse: 0→4, 1→3, 2→2, 3→1, 4→0
        } else {
          total += _answers[i];
        }
      }
      return total;
    }
    if (_selectedTest == 'WHO-5') {
      // WHO-5 raw score × 4 = percentage index (0-100)
      return _answers.reduce((a, b) => a + b) * 4;
    }
    return _answers.reduce((a, b) => a + b);
  }

  /// DASS-21 subscale scores (each × 2 for comparison with DASS-42 norms).
  Map<String, int> _dass21Subscales() {
    int dep = 0, anx = 0, str = 0;
    for (int i = 0; i < _answers.length; i++) {
      if (_dass21Depression.contains(i)) dep += _answers[i];
      if (_dass21Anxiety.contains(i)) anx += _answers[i];
      if (_dass21Stress.contains(i)) str += _answers[i];
    }
    return {'depression': dep * 2, 'anxiety': anx * 2, 'stress': str * 2};
  }

  void _goToResults() async {
    setState(() {
      _showResults = true;
    });

    // Save result to database
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      final totalScore = _computeScore();
      final now = DateTime.now().toIso8601String();
      final assessment = Assessment(
        userID: user.userID!,
        scaleType: _selectedTest,
        score: totalScore,
        date: now,
      );
      await DatabaseHelper.instance.createAssessment(assessment);
    }
  }

  void _resetTest() {
    setState(() {
      _testSelected = false;
      _selectedTest = '';
      _showResults = false;
      _answers = [];
      _currentPage = 0;
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _testSelected
              ? (_showResults ? '$_selectedTest Results' : '$_selectedTest Assessment')
              : 'Self Assessment',
        ),
        automaticallyImplyLeading: false,
        leading: _testSelected
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _resetTest,
              )
            : null,
      ),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: _testSelected
              ? (_showResults ? _buildResultsPage() : _buildPageView())
              : _buildSelectionScreen(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  TEST SELECTION SCREEN (kept from original)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSelectionScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Assessment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Clinically validated screening tools',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTestCard(
                  'PHQ-9',
                  Icons.mood,
                  Colors.blue.shade100,
                  Colors.blue.shade800,
                  'Depression',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTestCard(
                  'GAD-7',
                  Icons.psychology,
                  Colors.green.shade100,
                  Colors.green.shade800,
                  'Anxiety',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTestCard(
                  'PSS-10',
                  Icons.trending_up,
                  Colors.orange.shade100,
                  Colors.orange.shade800,
                  'Perceived Stress',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTestCard(
                  'WHO-5',
                  Icons.favorite_outline,
                  Colors.purple.shade100,
                  Colors.purple.shade800,
                  'Well-Being',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTestCard(
            'DASS-21',
            Icons.assessment,
            Colors.red.shade100,
            Colors.red.shade800,
            'Depression, Anxiety & Stress',
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssessmentHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text(
                'View Past Results',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    String testName,
    IconData icon,
    Color bgColor,
    Color iconColor,
    String subtitle,
  ) {
    return InkWell(
      onTap: () => _selectTest(testName),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 16),
            Text(
              testName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  TYPEFORM-STYLE PAGE VIEW  (Step 1)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPageView() {
    final totalQuestions = _questions.length;

    return Column(
      children: [
        // ── Progress bar ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / totalQuestions,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Question ${_currentPage + 1} of $totalQuestions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ── Question pages ──────────────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalQuestions,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildQuestionPage(index);
            },
          ),
        ),

        // ── Navigation buttons ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Previous button
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              if (_currentPage > 0) const SizedBox(width: 12),

              // Next / See Results button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _answers[_currentPage] == -1
                      ? null
                      : () {
                          if (_currentPage < totalQuestions - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _goToResults();
                          }
                        },
                  icon: Icon(
                    _currentPage == totalQuestions - 1
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _currentPage == totalQuestions - 1 ? 'See Results' : 'Next',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Single question page ──────────────────────────────────────────
  Widget _buildQuestionPage(int questionIndex) {
    final question = _questions[questionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Intro prompt (only on first page)
          if (questionIndex == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Over the last 2 weeks, how often have you been bothered by:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),

          // Question text
          Text(
            question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          // Answer option cards
          ...List.generate(_options.length, (optIdx) {
            final option = _options[optIdx];
            final isSelected = _answers[questionIndex] == option['score'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _onOptionSelected(questionIndex, option['score']),
                  child: Container(
                    width: double.infinity,
                    height: 56, // Fixed height per Step 1 constraints
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Score badge
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${option['score']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? Colors.white 
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Label
                        Expanded(
                          child: Text(
                            option['label'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Check icon
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  RESULTS PAGE (Step 3)
  // ══════════════════════════════════════════════════════════════════════

  /// Compute severity label + color for PHQ-9
  Map<String, dynamic> _phq9Severity(int score) {
    if (score <= 4) return {'label': 'Minimal', 'color': Colors.green};
    if (score <= 9) return {'label': 'Mild', 'color': Colors.lightGreen};
    if (score <= 14) return {'label': 'Moderate', 'color': Colors.orange};
    if (score <= 19) return {'label': 'Moderately Severe', 'color': Colors.deepOrange};
    return {'label': 'Severe', 'color': Colors.red};
  }

  /// Compute severity label + color for GAD-7
  Map<String, dynamic> _gad7Severity(int score) {
    if (score <= 4) return {'label': 'Minimal', 'color': Colors.green};
    if (score <= 9) return {'label': 'Mild', 'color': Colors.lightGreen};
    if (score <= 14) return {'label': 'Moderate', 'color': Colors.orange};
    return {'label': 'Severe', 'color': Colors.red};
  }

  /// PSS-10 severity (score range 0-40)
  Map<String, dynamic> _pss10Severity(int score) {
    if (score <= 13) return {'label': 'Low Stress', 'color': Colors.green};
    if (score <= 26) return {'label': 'Moderate Stress', 'color': Colors.orange};
    return {'label': 'High Stress', 'color': Colors.red};
  }

  /// WHO-5 severity (percentage 0-100)
  Map<String, dynamic> _who5Severity(int score) {
    if (score >= 72) return {'label': 'High Well-Being', 'color': Colors.green};
    if (score >= 50) return {'label': 'Moderate Well-Being', 'color': Colors.lightGreen};
    if (score >= 28) return {'label': 'Low Well-Being', 'color': Colors.orange};
    return {'label': 'Poor Well-Being', 'color': Colors.red};
  }

  /// DASS-21 overall severity based on total
  Map<String, dynamic> _dass21Severity(int totalRaw) {
    // totalRaw is sum of all 21 items (not doubled), use for overall display
    if (totalRaw <= 9) return {'label': 'Normal', 'color': Colors.green};
    if (totalRaw <= 18) return {'label': 'Mild', 'color': Colors.lightGreen};
    if (totalRaw <= 25) return {'label': 'Moderate', 'color': Colors.orange};
    if (totalRaw <= 33) return {'label': 'Severe', 'color': Colors.deepOrange};
    return {'label': 'Extremely Severe', 'color': Colors.red};
  }

  /// DASS-21 subscale severity label
  String _dass21SubscaleSeverity(String subscale, int score) {
    if (subscale == 'depression') {
      if (score <= 9) return 'Normal';
      if (score <= 13) return 'Mild';
      if (score <= 20) return 'Moderate';
      if (score <= 27) return 'Severe';
      return 'Extremely Severe';
    } else if (subscale == 'anxiety') {
      if (score <= 7) return 'Normal';
      if (score <= 9) return 'Mild';
      if (score <= 14) return 'Moderate';
      if (score <= 19) return 'Severe';
      return 'Extremely Severe';
    } else {
      // stress
      if (score <= 14) return 'Normal';
      if (score <= 18) return 'Mild';
      if (score <= 25) return 'Moderate';
      if (score <= 33) return 'Severe';
      return 'Extremely Severe';
    }
  }

  Color _dass21SubscaleColor(String severity) {
    switch (severity) {
      case 'Normal': return Colors.green;
      case 'Mild': return Colors.lightGreen;
      case 'Moderate': return Colors.orange;
      case 'Severe': return Colors.deepOrange;
      default: return Colors.red;
    }
  }

  /// Get severity for any test
  Map<String, dynamic> _getSeverity(int score) {
    switch (_selectedTest) {
      case 'PHQ-9': return _phq9Severity(score);
      case 'GAD-7': return _gad7Severity(score);
      case 'PSS-10': return _pss10Severity(score);
      case 'WHO-5': return _who5Severity(score);
      case 'DASS-21': return _dass21Severity(_answers.reduce((a, b) => a + b));
      default: return _phq9Severity(score);
    }
  }

  List<Widget> _buildDass21Rows() {
    final subs = _dass21Subscales();
    final entries = [
      {'name': 'Depression', 'key': 'depression', 'icon': Icons.mood_bad},
      {'name': 'Anxiety', 'key': 'anxiety', 'icon': Icons.psychology},
      {'name': 'Stress', 'key': 'stress', 'icon': Icons.trending_up},
    ];
    return entries.map((e) {
      final sc = subs[e['key'] as String]!;
      final sev = _dass21SubscaleSeverity(e['key'] as String, sc);
      final col = _dass21SubscaleColor(sev);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(e['icon'] as IconData, size: 20, color: col),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                e['name'] as String,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: col.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$sev ($sc)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: col),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _recommendation(String severity) {
    switch (severity) {
      case 'Minimal':
      case 'Low Stress':
      case 'High Well-Being':
      case 'Normal':
        return "You're doing well. Keep maintaining healthy habits.";
      case 'Mild':
      case 'Moderate Well-Being':
        return 'Consider talking to someone you trust about how you\'re feeling.';
      case 'Moderate':
      case 'Moderate Stress':
      case 'Low Well-Being':
        return 'We recommend speaking with a mental health professional.';
      default: // Severe / High Stress / Poor Well-Being / Extremely Severe
        return 'Please seek professional help as soon as possible.';
    }
  }

  Map<String, String> _encouragement(String severity) {
    switch (severity) {
      case 'Minimal':
      case 'Low Stress':
      case 'High Well-Being':
      case 'Normal':
        return {'emoji': '💪', 'text': 'Great job taking care of your mental health!'};
      case 'Mild':
      case 'Moderate Well-Being':
        return {'emoji': '🌱', 'text': 'Small steps every day make a big difference.'};
      case 'Moderate':
      case 'Moderate Stress':
      case 'Low Well-Being':
        return {'emoji': '🤝', 'text': 'Asking for help is a sign of strength, not weakness.'};
      default:
        return {'emoji': '❤️', 'text': 'You matter. Please reach out to someone today.'};
    }
  }

  void _retakeTest() {
    setState(() {
      _currentPage = 0;
      _showResults = false;
      _answers = List.filled(_questions.length, -1);
      _pageController = PageController();
    });
  }

  Widget _buildResultsPage() {
    final int score = _computeScore();
    final severity = _getSeverity(score);
    final String severityLabel = severity['label'];
    final Color severityColor = severity['color'];
    final String rec = _recommendation(severityLabel);
    final enc = _encouragement(severityLabel);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── 1. Score Circle ────────────────────────────────────────
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: severityColor, width: 6),
              color: severityColor.withValues(alpha: 0.08),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                Text(
                  _selectedTest,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: severityColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 2. Severity Badge ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              severityLabel,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: severityColor,
              ),
            ),
          ),

          // ── DASS-21 Subscale Breakdown ────────────────────────────
          if (_selectedTest == 'DASS-21') ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscale Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._buildDass21Rows(),
                ],
              ),
            ),
          ],

          // ── WHO-5 percentage note ─────────────────────────────────
          if (_selectedTest == 'WHO-5') ...[
            const SizedBox(height: 12),
            Text(
              'Score: $score% (raw: ${_answers.reduce((a, b) => a + b)}/25)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // ── 3. Recommendation Text ─────────────────────────────────
          Text(
            rec,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),

          const SizedBox(height: 24),

          // ── 4. Encouraging Message Card ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: severityColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Text(
                  enc['emoji']!,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    enc['text']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ── 5. Action Buttons ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _retakeTest,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retake Test'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetTest,
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text('Back to Tests'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
