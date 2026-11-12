// =============================================================
//  Response Library — Natural, Warm Chatbot Responses
//
//  Design philosophy (inspired by Wysa, Woebot, Replika):
//    - Sound like a warm, wise friend — NOT a clinical textbook
//    - Never force diagnoses into conversation
//    - Match the user's energy and tone
//    - Use "you" language, contractions, casual warmth
//    - Validate first, explore second, suggest only when asked
//    - Handle off-topic content gracefully
//
//  The chatbot NEVER provides diagnoses or medical advice.
// =============================================================

import 'dart:math';
import 'conversation_engine.dart';

final _random = Random();

/// Tracks the last used index per category to reduce immediate repetition.
final Map<String, int> _lastUsedIndex = {};

String _pick(List<String> options, [String? category]) {
  if (options.length <= 1) return options.first;

  if (category != null && _lastUsedIndex.containsKey(category)) {
    // Avoid picking the same index as last time
    int next;
    do {
      next = _random.nextInt(options.length);
    } while (next == _lastUsedIndex[category] && options.length > 1);
    _lastUsedIndex[category] = next;
    return options[next];
  }

  final index = _random.nextInt(options.length);
  if (category != null) _lastUsedIndex[category] = index;
  return options[index];
}

// ─────────────────────────────────────────────
// SMART PICK — Selects the BEST matching response
// based on keyword overlap with the user's message.
// Falls back to random if no meaningful overlap found.
// ─────────────────────────────────────────────

/// Keywords that signal topic overlap between user input and response text.
const List<String> _topicMatchWords = [
  'sleep', 'sleeping', 'insomnia', 'nightmare', 'rest', 'awake',
  'work', 'job', 'boss', 'career', 'office', 'deadline', 'coworker',
  'school', 'exam', 'study', 'class', 'university', 'college', 'grade', 'homework',
  'family', 'parent', 'mother', 'father', 'mom', 'dad', 'sibling', 'brother', 'sister',
  'friend', 'friendship', 'social', 'lonely', 'alone', 'isolated',
  'relationship', 'partner', 'boyfriend', 'girlfriend', 'husband', 'wife', 'breakup',
  'money', 'financial', 'debt', 'rent', 'bills', 'afford',
  'health', 'sick', 'pain', 'illness', 'doctor', 'medication',
  'exercise', 'walk', 'running', 'workout', 'movement',
  'routine', 'morning', 'night', 'evening',
  'body', 'energy', 'appetite', 'eating', 'weight',
  'tired', 'exhausted', 'fatigue', 'drained',
  'pressure', 'overwhelm', 'burden', 'responsibility',
  'anger', 'angry', 'frustrated', 'irritable',
  'crying', 'cry', 'tears',
  'enjoy', 'interest', 'motivation', 'purpose',
  'heart', 'chest', 'breathing', 'shaking', 'tension',
  'mood', 'swing', 'shift', 'change',
  'people', 'places', 'avoid', 'avoidance',
  'worry', 'racing', 'thoughts', 'overthink',
];

/// Picks the best-matching response from [options] based on keyword
/// overlap with [userMessage]. When a user says "I can't sleep because
/// of exam stress", this selects a response mentioning sleep or exams
/// rather than a generic one. Falls back to random when no match found.
String _smartPick(List<String> options, String? userMessage, [String? category]) {
  if (userMessage == null || userMessage.trim().isEmpty || options.length <= 1) {
    return _pick(options, category);
  }

  final userLower = userMessage.toLowerCase();
  final userWords = userLower
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 3)
      .toSet();

  int bestScore = 0;
  int bestIndex = -1;

  for (int i = 0; i < options.length; i++) {
    final responseLower = options[i].toLowerCase();
    int score = 0;

    // Score by meaningful word overlap with user message
    for (final word in userWords) {
      if (responseLower.contains(word)) score += 2;
    }

    // Bonus for topic-specific keyword matches
    for (final topic in _topicMatchWords) {
      if (userLower.contains(topic) && responseLower.contains(topic)) {
        score += 3;
      }
    }

    // Penalize repeating the same index as last time
    if (category != null && _lastUsedIndex[category] == i) {
      score -= 1;
    }

    if (score > bestScore) {
      bestScore = score;
      bestIndex = i;
    }
  }

  // Only use smart match if we have a meaningful score (at least one topic match)
  if (bestScore >= 3 && bestIndex >= 0) {
    if (category != null) _lastUsedIndex[category] = bestIndex;
    return options[bestIndex];
  }

  return _pick(options, category);
}

// ─────────────────────────────────────────────
// REFLECTION PREFIX — Mirrors the user's topic
// back to them so they feel heard before we
// respond with the selected response.
// ─────────────────────────────────────────────

/// Builds a brief, natural acknowledgment of what the user mentioned.
/// Returns empty string if no specific topic is detected.
String _buildReflection(String userMessage) {
  final lower = userMessage.toLowerCase();
  final mentions = <String>[];

  if (RegExp(r'\b(work|job|boss|career|office)\b').hasMatch(lower)) mentions.add('work');
  if (RegExp(r'\b(school|exam|study|class|university|college|grade)\b').hasMatch(lower)) mentions.add('school');
  if (RegExp(r'\b(family|parent|mom|dad|mother|father|sibling|brother|sister)\b').hasMatch(lower)) mentions.add('family');
  if (RegExp(r'\b(sleep|insomnia|nightmare|can.t sleep|awake at night)\b').hasMatch(lower)) mentions.add('sleep');
  if (RegExp(r'\b(friend|friends|lonely|alone|isolated)\b').hasMatch(lower)) mentions.add('friends');
  if (RegExp(r'\b(relationship|partner|boyfriend|girlfriend|husband|wife|breakup|divorce)\b').hasMatch(lower)) mentions.add('your relationship');
  if (RegExp(r'\b(money|financial|debt|rent|bills|broke)\b').hasMatch(lower)) mentions.add('money');
  if (RegExp(r'\b(health|sick|pain|illness|doctor)\b').hasMatch(lower)) mentions.add('your health');

  if (mentions.isEmpty) return '';

  final List<String> templates;
  if (mentions.length == 1) {
    templates = [
      'I hear that ${mentions[0]} has been on your mind. ',
      'It sounds like ${mentions[0]} is weighing on you. ',
      'I can tell ${mentions[0]} has been affecting you. ',
    ];
  } else {
    final joined = mentions.take(2).join(' and ');
    templates = [
      'It sounds like $joined have been weighing on you. ',
      'I can hear that $joined have been tough. ',
      'It seems like $joined are both on your mind. ',
    ];
  }

  return templates[_random.nextInt(templates.length)];
}

class ResponseLibrary {
  // ─────────────────────────────────────────────
  // GREETING (warm, simple, one message only)
  // ─────────────────────────────────────────────
  static String greeting() => _pick(const [
        "Hey! How are you doing today?",
        "Hi there! How's your day going?",
        "Hello! How are you feeling today?",
        "Hey there 💙 How's everything going?",
        "Hi! I'm glad you're here. How are you doing?",
        "Welcome back! How have things been? 🌱",
        "Hey! Good to see you. What's on your mind today?",
        "Hi there! I'm here whenever you're ready to talk. How are you? ✨",
      ], 'greeting');

  static String greetingFromAssessment(String type, int score, String severity) {
    if (severity == 'Minimal' || severity == 'Mild') {
      return "Thanks for completing the $type check-in. "
          "It's really good that you're paying attention to how you feel. "
          "How are things going for you right now?";
    } else if (severity == 'Moderate') {
      return "Thanks for sharing your $type results with me. "
          "It sounds like things have been a bit tough lately. "
          "I'm here if you'd like to talk about what's been going on.";
    } else {
      return "Thank you for trusting me with your $type results. "
          "It sounds like you've been going through a really hard time. "
          "I'm here to listen — would you like to tell me what's been on your mind?";
    }
  }

  // ─────────────────────────────────────────────
  // OFF-TOPIC RESPONSES (gentle redirect)
  // ─────────────────────────────────────────────
  static String offTopicResponse() => _pick(const [
        "Interesting! Though I'm best at talking about how you're feeling and mental wellness. Is there anything on your mind emotionally that I can help with?",
        "I appreciate you sharing that! I'm mostly here to help with emotional well-being though. How are you feeling today?",
        "That's cool! Just so you know, I'm designed to help with feelings and mental wellness. Is there anything you'd like to talk about in that area?",
        "Ha, that's fun! My real superpower is emotional support though 💙 Anything going on that you'd like to talk through?",
        "I love the conversation, but I'm best at helping with how you're feeling inside. Want to check in on that?",
        "That's interesting! I'm mainly here for your emotional well-being though. How are you feeling right now? 🌱",
      ], 'offTopic');

  // ─────────────────────────────────────────────
  // MOOD CHECK-IN (natural, not clinical)
  // ─────────────────────────────────────────────
  static String moodCheckIn(String emotion, {String? userMessage}) {
    switch (emotion) {
      case 'positive':
        return _smartPick(const [
          "That's really nice to hear! What's been making things good?",
          "Love that! Anything in particular that's been going well?",
          "That's great! It's good to notice the positive moments. What's been the highlight?",
          "That makes me so happy to hear! ✨ What's been bringing you joy?",
          "I'm glad things are going well! What's been the best part of your day?",
          "That's wonderful 🌟 Tell me more — I love hearing the good stuff!",
        ], userMessage, 'moodCheckIn_positive');
      case 'stress':
        return _smartPick(const [
          "That sounds like a lot to deal with. What's been the heaviest part?",
          "I hear you — when everything piles up, it can feel suffocating. What's weighing on you the most?",
          "Sounds like things have been really demanding. Want to tell me more about what's going on?",
          "That must be really draining 💙 What's been taking the biggest toll on you?",
          "I can sense the weight in what you're saying. What would you most like to lighten right now?",
          "Stress has a way of creeping into everything. What's the main source right now?",
          "That sounds really overwhelming — especially when it feels like there's no break from the pressure. What's been pushing you the hardest?",
          "It sounds like the stress has been building for a while. Is it more about work and deadlines, or is it personal stuff too?",
        ], userMessage, 'moodCheckIn_stress');
      case 'depression':
        return _smartPick(const [
          "I'm really glad you're telling me this. That takes courage. How long have you been feeling this way?",
          "That sounds really heavy. I want you to know it's okay to feel this way, and you're not alone. Can you tell me more?",
          "Thank you for being honest with me. When did these feelings start?",
          "I'm here for you 💙 It takes strength to put these feelings into words. What's been the hardest part?",
          "I hear you, and I want you to know that reaching out like this matters. How has this been affecting your daily life?",
          "Thank you for trusting me with this. You don't have to go through it alone. When did things start feeling this way?",
          "That sounds incredibly tough. When you say you feel this way, is it there all the time, or does it come and go?",
          "I can feel the weight in your words. Has this been affecting your energy, sleep, or appetite at all?",
        ], userMessage, 'moodCheckIn_depression');
      case 'anxiety':
        return _smartPick(const [
          "That sounds exhausting — when your mind won't stop racing, it drains everything. What's been worrying you the most?",
          "I hear you. Anxiety can make everything feel harder than it needs to be. What's been on your mind?",
          "That must be really tough. Is there something specific that's been triggering the worry, or does it feel more general?",
          "That restless feeling can be so overwhelming 💙 What's at the center of the worry right now?",
          "I understand — anxiety has a way of making everything feel urgent. Let's slow down together. What's been your biggest concern?",
          "That sounds really tiring. When the worry is loudest, what does it usually say? 🌱",
          "I hear you — that constant worry can be so draining, especially when it affects your sleep and daily routine. What's been the biggest trigger?",
          "It sounds like the anxiety has been making everything feel heavier. Has it been showing up physically too — like tension, racing heart, or trouble sleeping?",
        ], userMessage, 'moodCheckIn_anxiety');
      case 'bipolar':
        return _smartPick(const [
          "It sounds like your mood and energy have been really unpredictable. Can you tell me more about what that's been like day to day?",
          "Those kinds of shifts can be really confusing and exhausting. How have your sleep and energy been?",
          "Living with those ups and downs takes a lot of strength. What's been the most challenging part lately?",
          "That sounds like a real roller coaster 💙 How have you been managing the shifts?",
          "I hear you — when your mood changes so much, it can feel hard to trust your own feelings. What's been going on most recently?",
        ], userMessage, 'moodCheckIn_bipolar');
      case 'personality_disorder':
        return _smartPick(const [
          "That sounds like a lot to navigate, especially with relationships and emotions feeling so intense. Want to tell me more about it?",
          "It takes a lot of self-awareness to notice these patterns. What's been the hardest part for you?",
          "Navigating intense emotions and relationships can feel really exhausting. What's been weighing on you most? 💙",
          "It sounds like things have been really intense. I'm here to listen without judgment. What would you like to talk about?",
          "That level of self-awareness is actually remarkable. Let's talk about what's been most difficult recently.",
        ], userMessage, 'moodCheckIn_personality');
      case 'mixed':
        return _smartPick(const [
          "It sounds like there's a lot going on at once. Let's take it one thing at a time — what feels most pressing right now?",
          "That's a lot to carry. Which part of it has been affecting you the most?",
          "I can tell there's a lot swirling around. Let's untangle it together — what feels biggest right now? 💙",
          "It sounds like several things are hitting you at once. What would feel most helpful to talk about first?",
          "That's a full plate. Sometimes just picking one thread to pull can help. What's been on your mind the most?",
        ], userMessage, 'moodCheckIn_mixed');
      default:
        return _smartPick(const [
          "Thanks for sharing that. Tell me a bit more about how you've been feeling?",
          "I'd like to understand more. What's been on your mind lately?",
          "I'm here to listen 💙 What would you like to talk about?",
          "Thanks for opening up. Can you tell me a little more about what's going on?",
          "I appreciate you sharing. What's been taking up the most space in your head lately?",
        ], userMessage, 'moodCheckIn_default');
    }
  }

  // ─────────────────────────────────────────────
  // EMOTIONAL EXPLORATION (go deeper, naturally)
  // ─────────────────────────────────────────────
  static String emotionalExploration(String emotion, {String? userMessage}) {
    switch (emotion) {
      case 'stress':
        return _smartPick(const [
          "How has all this stress been affecting your day-to-day? Like your sleep, appetite, or just how you feel overall?",
          "When things get this overwhelming, it usually shows up in other areas too. Have you noticed any changes in your routine?",
          "Has there been a specific moment recently where it all felt like too much?",
          "Sometimes stress hides in our body — tight shoulders, headaches, trouble sleeping. Have you noticed anything like that? 🌱",
          "What does a stressful day actually look like for you? Walk me through it.",
          "Is the stress coming more from external stuff — work, people, responsibilities — or is it more internal, like pressure you put on yourself?",
        ], userMessage, 'exploration_stress');
      case 'depression':
        return _smartPick(const [
          "When you're going through this, do you find it hard to enjoy things that you usually like?",
          "Sometimes when things feel this heavy, even small tasks become a mountain. Has that been happening for you?",
          "Have you been able to talk to anyone about this? Sometimes just having someone who knows can make a difference.",
          "How has your energy been? Sometimes depression quietly drains our batteries without us noticing 💙",
          "Has this changed how you see yourself or your future? Sometimes depression distorts those things.",
          "What does a typical morning feel like for you right now? That can tell us a lot about how you're really doing.",
        ], userMessage, 'exploration_depression');
      case 'anxiety':
        return _smartPick(const [
          "When the worry kicks in, is it usually about something specific, or does it feel more like a general unease about everything?",
          "Has the anxiety been showing up physically too? Like tension, racing heart, trouble sleeping?",
          "Are there certain situations that make it worse, or does it seem to come and go randomly?",
          "What does your anxiety feel like in your body? Sometimes naming the physical sensation can help us understand it better 🌱",
          "When the anxious thoughts start, is there a particular thought that kicks everything off?",
          "How has the anxiety affected your sleep? That's often one of the first things it disrupts.",
        ], userMessage, 'exploration_anxiety');
      case 'bipolar':
        return _smartPick(const [
          "Can you walk me through what the highs and lows feel like? Understanding the pattern can be really helpful.",
          "During the high-energy times, what does that feel like? And how about when you're in the low periods?",
          "How quickly do the shifts happen for you? Is it gradual or does it feel sudden?",
          "How has this been affecting your relationships and daily responsibilities? 💙",
          "Have you noticed any patterns or triggers that tend to come before a mood shift?",
        ], userMessage, 'exploration_bipolar');
      case 'personality_disorder':
        return _smartPick(const [
          "When emotions feel that intense, it can be really isolating. What do you usually do when things feel overwhelming?",
          "It sounds like your sense of who you are has been feeling uncertain. When did you first start noticing that?",
          "How have relationships been for you lately? Sometimes that's where these patterns show up the most 💙",
          "When strong emotions hit, how long do they usually last? And what helps you come back to center?",
          "What does it feel like when you're in the middle of one of those intense emotional moments?",
        ], userMessage, 'exploration_personality');
      default:
        return _smartPick(const [
          "How has this been showing up in your daily life?",
          "Is there anything else connected to this that's been on your mind?",
          "How have the people around you been reacting to what you're going through?",
          "Has this been affecting your sleep, appetite, or energy at all? 🌱",
          "When did you first start noticing these feelings?",
          "If you could describe how you're feeling in one word right now, what would it be?",
        ], userMessage, 'exploration_default');
    }
  }

  // ─────────────────────────────────────────────
  // FOLLOW-UP (gentle, curious, not interrogating)
  // ─────────────────────────────────────────────
  static String followUp(String emotion, {String? userMessage}) {
    switch (emotion) {
      case 'stress':
        return _smartPick(const [
          "Has anything helped even a little bit in the past when things got stressful?",
          "If you could change one thing about the situation right now, what would it be?",
          "How are you taking care of yourself through all this?",
          "What's one thing that usually brings you even a tiny bit of calm? 🌱",
          "Is there someone in your life who helps take the edge off when things are rough?",
          "What would it feel like if even one of those stressors was resolved?",
        ], userMessage, 'followUp_stress');
      case 'depression':
        return _smartPick(const [
          "Are there any moments during the day when things feel a tiny bit lighter?",
          "How has your sleep been? Sometimes that's one of the first things to change.",
          "Is there anything coming up that you're looking forward to, even something small?",
          "What's been getting you through the day? Even small anchors count 💙",
          "Have you been able to do any of the things you used to enjoy, even a little?",
          "If you had one really good day, what would it look like?",
        ], userMessage, 'followUp_depression');
      case 'anxiety':
        return _smartPick(const [
          "When the anxiety gets really bad, what do you usually try to do?",
          "Have you noticed if it's worse at certain times of day?",
          "Is there a person or place that helps you feel a bit calmer?",
          "What would it feel like if the worry just... stopped for a moment? Can you imagine that? 🌱",
          "Have you found any tricks — even small ones — that help take the edge off?",
          "Is the anxiety keeping you from doing things you'd normally do?",
        ], userMessage, 'followUp_anxiety');
      default:
        return _smartPick(const [
          "What does a typical day look like for you lately?",
          "Is there anything that's been helping you get through this?",
          "How have you been taking care of yourself?",
          "What's one thing that brought you comfort recently, even if it was small? 🌱",
          "If a friend was going through the same thing, what would you tell them?",
          "Is there anything you've been avoiding because of how you've been feeling?",
        ], userMessage, 'followUp_default');
    }
  }

  // ─────────────────────────────────────────────
  // SUPPORTIVE REFLECTION (validate, don't lecture)
  // ─────────────────────────────────────────────
  static String supportiveReflection(String emotion, bool isChronic, {String? userMessage}) {
    final chronicNote = isChronic
        ? " Since this has been going on for a while, talking to a professional could really help — they can offer tools that go deeper than what we can do here."
        : "";

    switch (emotion) {
      case 'stress':
        return "${_smartPick(const [
          "You're carrying a lot right now, and it's okay to acknowledge that.",
          "The fact that you're aware of what's stressing you is actually a really important first step.",
          "What you're going through makes sense. Stress is your mind's way of saying something needs attention.",
          "You're dealing with a lot, and you're still showing up. That takes real strength 💙",
          "It's completely valid to feel overwhelmed. You don't have to have it all figured out right now.",
          "Recognizing that you're stressed — and talking about it — is more powerful than you might think 🌟",
        ], userMessage, 'reflection_stress')}$chronicNote";
      case 'depression':
        return "${_smartPick(const [
          "What you're feeling is real, and it's valid. You don't have to carry this alone.",
          "The fact that you're here talking about it shows real strength, even if it doesn't feel that way.",
          "I want you to know that how you feel right now isn't permanent, even though it might feel like it is.",
          "You deserve to feel better, and reaching out is an important step toward that 💙",
          "Depression lies to us — it tells us things won't get better. But they can, and they do.",
          "Even on the hardest days, you've kept going. That matters more than you know 🌱",
        ], userMessage, 'reflection_depression')}$chronicNote";
      case 'anxiety':
        return "${_smartPick(const [
          "Anxiety can feel like it takes over everything, but you're doing something positive by talking about it.",
          "Your feelings make sense. Anxiety is basically your brain's alarm system being a bit too sensitive.",
          "It's okay to feel this way. What matters is that you're being honest about it.",
          "The fact that you can name what you're feeling is huge. Awareness is the first step to managing it 💙",
          "Anxiety doesn't define you — it's something you experience, not who you are.",
          "You're braver than you think. Facing anxiety head-on, even just by talking about it, takes real courage 🌟",
        ], userMessage, 'reflection_anxiety')}$chronicNote";
      default:
        return "${_smartPick(const [
          "Thank you for being so open with me. What you're feeling matters.",
          "I hear you. You're showing real self-awareness by talking through this.",
          "Whatever you're going through, it's okay to not be okay sometimes.",
          "Your feelings are valid, and you deserve to be heard 💙",
          "It takes courage to look inward the way you're doing. I'm really glad you shared this.",
          "You don't have to have it all figured out. Just being honest with yourself is a big deal 🌱",
        ], userMessage, 'reflection_default')}$chronicNote";
    }
  }

  // ─────────────────────────────────────────────
  // COPING SUGGESTIONS (practical, not preachy)
  // ─────────────────────────────────────────────
  static String copingSuggestions(String emotion, {String? userMessage}) {
    switch (emotion) {
      case 'stress':
        return _smartPick(const [
          "Something that helps a lot of people with stress: try the 4-7-8 breathing technique — breathe in for 4 seconds, hold for 7, breathe out for 8. Even just 3 rounds can help your body calm down. Want to give it a try?",
          "When stress feels overwhelming, breaking things into tiny steps can help. Also, even 10 minutes doing something you enjoy can reset your mind. What sounds doable for you?",
          "A few things that might help: setting small boundaries (it's okay to say no), talking to someone you trust, or a quick walk outside. Which of these feels right for you?",
          "Try box breathing 🌱 Breathe in for 4 counts, hold for 4, breathe out for 4, hold for 4. It activates your body's natural calm-down response. Even 2 minutes can make a noticeable difference.",
          "Here's something simple but powerful: progressive muscle relaxation. Start at your toes — tense them for 5 seconds, then release. Work your way up through your whole body. The release feels amazing and teaches your body what 'relaxed' actually feels like.",
          "Try a body scan meditation: close your eyes and slowly move your attention from the top of your head to the tips of your toes. Just notice what you feel — no judgment. It helps you release tension you didn't even know you were holding 💙",
          "Sometimes the best stress reliever is movement. Even a 10-minute walk — especially outside — can lower cortisol and clear your head. No workout required, just gentle movement 🌿",
          "Try making a 'stress dump' list: write down every single thing stressing you out, big or small. Getting it out of your head and onto paper makes it feel more manageable. Then circle just one thing you can take a tiny step on today.",
        ], userMessage, 'coping_stress');
      case 'depression':
        return _smartPick(const [
          "When things feel this heavy, even tiny actions count. Getting a bit of sunlight, drinking water, or just stepping outside for a minute. There's no pressure — what feels possible for you right now?",
          "A lot of people find it helpful to have a gentle routine — regular sleep, a short walk, staying in touch with at least one person. It won't fix everything, but it builds a foundation. What do you think?",
          "Here's something to try: do one small kind thing for yourself today. It could be anything — a warm drink, a favorite song, or just sitting somewhere comfortable. Small things matter more than we think.",
          "Try this: write down three things you're grateful for, even tiny ones. 'My bed is warm.' 'I had coffee.' 'The sun came out.' It sounds simple, but it gently trains your brain to notice what's good 🌱",
          "Music can be a quiet lifeline. Try putting on a song that makes you feel something — anything. Sometimes music reaches places that words can't 🎵",
          "Positive affirmations might feel awkward at first, but they can help rewire negative thought patterns. Try saying to yourself: 'I deserve to feel better. I'm taking it one day at a time. I am enough.' 💙",
          "When everything feels heavy, try the 'one thing' rule: just do one thing. Brush your teeth. Open the curtains. Send one text. That's it. One thing is enough, and it's more than nothing.",
          "If you can, try to get some gentle movement — even stretching in bed counts. Movement releases endorphins, your brain's natural mood boosters. No pressure to do anything intense 🌿",
        ], userMessage, 'coping_depression');
      case 'anxiety':
        return _smartPick(const [
          "Try this grounding exercise: notice 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, and 1 you can taste. It helps bring you back to the present moment. Want to try it now?",
          "Slow breathing can really help calm your nervous system. Try breathing in for 4 counts, holding for 4, and breathing out for 6. Even a few rounds can bring the anxiety down. Shall we try?",
          "When anxiety spikes, try asking yourself: 'What's the evidence for this worry?' and 'What would I tell a friend in this situation?' It creates a bit of distance from the anxious thoughts.",
          "Here's box breathing for anxiety 🌱 Breathe in 4 counts, hold 4 counts, breathe out 4 counts, hold 4 counts. Repeat 4 times. It's used by Navy SEALs to stay calm under pressure — and it really works.",
          "Try the 5-4-3-2-1 grounding technique right now: Name 5 things you see. 4 things you can touch. 3 things you hear. 2 things you smell. 1 thing you taste. It anchors you to the present ✨",
          "Progressive muscle relaxation is great for anxiety: tense each muscle group for 5 seconds, then release. Start with your hands, then arms, shoulders, face, stomach, legs, feet. The contrast between tension and release is deeply calming 💙",
          "When anxious thoughts spiral, try writing them down. Getting them out of your head and onto paper makes them feel less overwhelming. You might even notice that some of them aren't as likely as they feel.",
          "Try putting on calming music or nature sounds and just focusing on listening for 3 minutes. It gives your anxious mind something neutral to hold onto instead of worries 🎵",
        ], userMessage, 'coping_anxiety');
      case 'bipolar':
        return _smartPick(const [
          "Keeping a consistent daily routine — regular sleep, meals, and activities — can be really stabilizing. Tracking your mood each day in a journal can also help spot patterns. And staying connected with a mental health professional is really important.",
          "Something that helps a lot of people: track your mood, energy, and sleep every day. It helps you and any healthcare provider understand your patterns better.",
          "Try to prioritize sleep consistency above almost everything else — going to bed and waking up at the same time, even on weekends. It's one of the most stabilizing things you can do 💙",
          "Building a 'wellness toolbox' can help: list what helps during low periods and what helps during high periods. Having it ready means you don't have to figure it out in the moment.",
          "Gentle, regular exercise — like daily walks — can be really stabilizing for mood. It doesn't have to be intense. Consistency matters more than intensity 🌱",
        ], userMessage, 'coping_bipolar');
      default:
        return _smartPick(const [
          "Some things that help a lot of people: regular movement (even a short walk counts), staying connected with people you care about, getting enough sleep, and taking a few minutes each day to just breathe. What resonates with you?",
          "Taking care of your mental health is an ongoing thing. Simple practices like writing down your thoughts, spending time outside, or noticing things you're grateful for can build resilience over time.",
          "Try box breathing: breathe in for 4 counts, hold for 4, out for 4, hold for 4. It's a simple reset button for your nervous system 🌱",
          "Here's a simple daily wellness check: Did I move my body? Did I drink water? Did I connect with someone? Did I do one thing I enjoy? Even checking one box is a win 💙",
          "Consider starting a gratitude practice — just 3 things each day. They can be tiny. Over time, it genuinely shifts how your brain processes the world ✨",
          "A body scan meditation takes just 5 minutes: sit comfortably, close your eyes, and slowly scan from head to toe, noticing any tension or sensation. Just noticing — no fixing needed.",
          "Sometimes the best thing you can do is put on a song you love and really listen to it. Music therapy isn't just a buzzword — it genuinely affects your brain chemistry 🎵",
          "Walking is underrated as a mental health tool. Even 15 minutes of walking — especially in nature — can reduce stress hormones and boost your mood. No gym required 🌿",
        ], userMessage, 'coping_default');
    }
  }

  // ─────────────────────────────────────────────
  // CRISIS RESPONSE
  // ─────────────────────────────────────────────
  static String crisisResponse() => _pick(const [
        "I hear you, and I want you to know that what you're feeling right now matters. "
            "You don't have to go through this alone.\n\n"
            "Please reach out for immediate support:\n"
            "- KSA Ministry of Health: 920033360\n"
            "- Find a helpline near you: findahelpline.com\n"
            "- Crisis Text Line: Text HOME to 741741\n\n"
            "A trained counselor can give you the support you need right now. "
            "Would you like to keep talking with me while you think about reaching out?",
        "What you're going through sounds incredibly difficult, and I'm really concerned about you. "
            "You deserve support right now.\n\n"
            "Please consider contacting:\n"
            "- KSA Ministry of Health: 920033360\n"
            "- Find a helpline near you: findahelpline.com\n"
            "- Crisis Text Line: Text HOME to 741741\n\n"
            "These services are confidential and available 24/7. "
            "I'm here for you, but a professional can provide the help you truly need.",
      ], 'crisis');

  // ─────────────────────────────────────────────
  // CONVERSATION CLOSING
  // ─────────────────────────────────────────────
  static String closing(String emotion, bool crisisWasDetected, {bool hadDistress = false}) {
    if (crisisWasDetected) {
      return "I'm glad we could talk. Please remember that professional support "
          "is available whenever you need it. Take care of yourself, and don't hesitate to come back.";
    }

    if (emotion == 'positive' && !hadDistress) {
      return _pick(const [
        "It was great chatting with you! Keep doing what you're doing, and I'm always here if you want to check in.",
        "Glad to hear you're doing well! Take care and come back anytime.",
        "This was a nice chat! Keep riding that positive wave 🌟 I'm always here when you need me.",
        "Love ending on a good note! Keep taking care of yourself — you're doing great ✨",
        "So glad things are going well! Remember, I'm always here if you want to celebrate wins or talk through tough stuff 💙",
      ], 'closing_positive');
    }

    return _pick(const [
      "Thanks for opening up to me today. Remember, you can always come back to talk. Take care of yourself.",
      "I'm glad we had this conversation. If things feel heavy again, don't hesitate to reach out — to me or to a professional. You matter.",
      "Thank you for sharing with me. You don't have to face things alone. Come back anytime.",
      "I really appreciate you trusting me with this. You're braver than you know 💙 Take gentle care of yourself.",
      "This was a meaningful conversation. Remember — progress isn't always linear, and every step counts. I'm always here 🌱",
      "Thank you for being so open. I'm here whenever you need to talk — no judgment, just support ✨",
    ], 'closing_general');
  }

  // ─────────────────────────────────────────────
  // PROFESSIONAL HELP NUDGE (gentle, not pushy)
  // ─────────────────────────────────────────────
  static String professionalHelpNudge() => _pick(const [
        "By the way — while I'm always here to listen, talking to a therapist or counselor could give you more personalized support. It's worth considering if you haven't already.",
        "You've shared some really important things with me. A professional could help you work through this with more depth and specialized tools. Would you consider it?",
        "Just a gentle thought 💙 A therapist or counselor could offer you tools and support that go beyond what I can provide. There's real strength in seeking that kind of help.",
        "If it feels right, talking to a mental health professional could be a great next step. They can give you personalized strategies and a safe space to work through things at your own pace 🌱",
      ], 'professionalNudge');

  // ─────────────────────────────────────────────
  // INVALID / SHORT INPUT
  // ─────────────────────────────────────────────
  static String invalidInput() => _pick(const [
        "I'd love to hear more — could you tell me a bit more about what's on your mind?",
        "Could you share a little more? I want to make sure I understand you well.",
        "Tell me more? I'm listening.",
        "I want to understand you better — can you expand on that a bit? 💙",
        "Take your time. I'm here whenever you're ready to share more 🌱",
        "No rush at all. What else is going on?",
      ], 'invalidInput');

  // ─────────────────────────────────────────────
  // INFORMATIONAL RESPONSE
  // ─────────────────────────────────────────────
  static String informationalResponse() => _pick(const [
        "That's a really thoughtful question. Mental wellness involves caring for your emotional, psychological, and social well-being. It affects how you think, feel, and act. Some key areas include managing stress, building healthy relationships, getting enough rest, and reaching out for support when needed. Would you like to explore any of these areas?",
        "Great question! Mental health is about your overall emotional and psychological well-being. It includes things like how you handle stress, relate to others, and make decisions. Key components are emotional regulation, self-awareness, healthy coping strategies, and social connection. Is there a specific area you'd like to know more about?",
        "I love that you're curious about this! Mental health is just as important as physical health — it's about how we think, feel, and cope with life. The pillars include sleep, connection, movement, purpose, and self-compassion. Which of these resonates most with you? 🌱",
      ], 'informational');

  // ─────────────────────────────────────────────
  // POSITIVE CONTINUATION (when user shares happy news)
  // ─────────────────────────────────────────────
  static String positiveContinuation() => _pick(const [
        "That sounds really nice! Tell me more about it.",
        "I love hearing that! What made it so good?",
        "That's awesome! How did that make you feel?",
        "Nice! What was the best part?",
        "That's wonderful ✨ I'd love to hear more about it!",
        "That genuinely made me happy to read 💙 What happened next?",
        "That sounds like a real win! How are you celebrating? 🌟",
      ], 'positiveContinuation');

  // ─────────────────────────────────────────────
  // ACKNOWLEDGMENT (for simple/short responses)
  // ─────────────────────────────────────────────
  static String simpleAcknowledgment() => _pick(const [
        "Got it. Is there anything else on your mind?",
        "Okay. How are you feeling about things overall?",
        "I hear you. Is there something specific you'd like to talk about?",
        "Understood 💙 What else is going on?",
        "Okay. I'm here if there's anything you want to dive into.",
        "I see. Is there something behind that you'd like to explore?",
      ], 'acknowledgment');

  // ─────────────────────────────────────────────
  // ENCOURAGEMENT (when user shows improvement)
  // ─────────────────────────────────────────────
  static String encouragement() => _pick(const [
        "I can really hear the progress in what you're saying. That's amazing 🌟",
        "Look at you — you're growing through this, and that takes so much strength 💙",
        "The fact that you're noticing positive changes is huge. Keep going, you're doing great!",
        "That's real progress, and you should be proud of yourself. Every step forward counts ✨",
        "You're handling this so much better than you give yourself credit for. I see it!",
        "Wow, it sounds like things are shifting in a really good direction. You've put in the work for this 🌱",
        "This is what growth looks like — messy, gradual, and absolutely real. I'm so glad you can see it too.",
        "You've come a long way from where you started. Don't forget to celebrate that 🌟",
        "The strength you're showing right now is inspiring. Keep trusting the process 💙",
        "It's beautiful to watch you finding your way through this. You're more resilient than you know.",
      ], 'encouragement');

  // ─────────────────────────────────────────────
  // GRATITUDE RESPONSES (when user says thanks)
  // ─────────────────────────────────────────────
  static String gratitude() => _pick(const [
        "You're so welcome 💙 I'm always here for you.",
        "It means a lot that you'd say that. I'm glad I could help, even a little 🌱",
        "Thank YOU for being so open and honest. That's what makes these conversations meaningful.",
        "I'm really glad our conversation helped. You did the hard part — I just listened ✨",
        "You're welcome! Remember, you deserve support, and I'm always here when you need it.",
        "That warms my heart 💙 Anytime you need to talk, I'm right here.",
        "You don't have to thank me — but I appreciate it! You're the one doing the brave work 🌟",
      ], 'gratitude');

  // ─────────────────────────────────────────────
  // SLEEP ADVICE (when user mentions sleep issues)
  // ─────────────────────────────────────────────
  static String sleepAdvice() => _pick(const [
        "Sleep is so foundational to how we feel. Here are some things that really help: try to go to bed and wake up at the same time every day — yes, even weekends. Your body craves that rhythm 🌙",
        "A good wind-down routine can transform your sleep: dim the lights an hour before bed, put away screens, and try something calming like reading, stretching, or a warm shower. Your brain needs those signals that it's time to rest 💙",
        "If racing thoughts keep you up, try this: keep a notepad by your bed and do a 'brain dump' before sleep — write down everything on your mind. It tells your brain it's okay to let go for now 📝",
        "Here's a sleep hygiene checklist: cool room (65-68°F), dark environment, no caffeine after 2pm, no screens 30 minutes before bed, and a consistent bedtime. Even adopting just one of these can make a difference 🌙",
        "If you can't fall asleep after 20 minutes, get up and do something calm in dim light — then go back to bed when you feel sleepy. Lying in bed frustrated actually makes insomnia worse. It retrains your brain to associate bed with sleep, not worry 💙",
        "Try a body scan meditation right before sleep: lie down, close your eyes, and slowly relax each part of your body from toes to head. It's like a lullaby for your nervous system 🌱",
        "Your bedroom should be a sleep sanctuary: cool, dark, quiet, and reserved for sleep. If you work, scroll, or watch TV in bed, your brain stops associating it with rest. Small changes to your space can make a big difference 🌙",
      ], 'sleepAdvice');

  // ─────────────────────────────────────────────
  // MINDFULNESS PROMPTS (quick exercises)
  // ─────────────────────────────────────────────
  static String mindfulnessPrompts() => _pick(const [
        "Let's try a quick mindfulness moment 🌱 Close your eyes and take three slow, deep breaths. With each exhale, let your shoulders drop a little more. Notice how your body feels right now — no judgment, just noticing.",
        "Here's a 60-second reset: Look around you and find one thing that's beautiful — a color, a texture, a shadow, anything. Really look at it for a full minute. Let everything else fade. This is mindfulness in its simplest form ✨",
        "Try this right now: put one hand on your chest and one on your stomach. Breathe slowly and feel which hand moves more. Try to make the stomach hand move more than the chest hand. That's diaphragmatic breathing — it activates your calm response 💙",
        "Mindful listening exercise: for the next 30 seconds, close your eyes and just listen. What can you hear? The hum of a machine? Birds? Your own breathing? Just notice without labeling. This is a quick way to anchor yourself to the present 🌿",
        "Here's a simple mindfulness trick for anytime: feel the ground beneath your feet. Press them down gently. Notice the texture, the temperature, the weight of your body. You're here. You're present. You're safe. That's all that matters right now 💙",
        "Try the STOP technique: S — Stop what you're doing. T — Take a breath. O — Observe what you're feeling (body, mind, emotions). P — Proceed with awareness. It takes 10 seconds and can completely shift your state 🌱",
        "Right now, try noticing five sounds around you without naming them. Just hear them as pure sound. It's a quick way to step out of your thoughts and into the present moment ✨",
      ], 'mindfulness');

  // ─────────────────────────────────────────────
  // JOURNAL PROMPTS (creative self-exploration)
  // ─────────────────────────────────────────────
  static String journalPrompts() => _pick(const [
        "Here's a journal prompt for you 📝 Write about a moment this week when you felt genuinely at peace — even if it was just for a second. What were you doing? Who were you with? What made it special?",
        "Try writing a letter to your future self, one year from now. What do you hope they'll know? What do you want them to remember about this time? It's a powerful way to connect with your own growth 💙",
        "Journal prompt: If your current feelings were a weather forecast, what would it say? Partly cloudy? Storming? Rays of sunshine breaking through? Describe your inner weather — it's a gentle way to check in with yourself 🌤",
        "Try this: write down three things you did today that took effort — even small things like getting out of bed, replying to a message, or eating a meal. Then write why each one mattered. You do more than you think ✨",
        "Here's a self-compassion prompt: write about something you've been criticizing yourself for, then respond to it as if you were talking to your best friend. What would you say to them? Now say that to yourself 💙",
        "Journal prompt: What's one belief about yourself that you'd like to let go of? Where did it come from? What would you replace it with? Sometimes just naming it takes away its power 🌱",
        "Try a gratitude deep-dive: pick one person in your life and write everything you appreciate about them — big and small. Then, if you feel brave, tell them. Connection is medicine 🌟",
      ], 'journalPrompts');

  // ─────────────────────────────────────────────
  // CONTEXTUAL FOLLOW-UP (topic-aware responses)
  // ─────────────────────────────────────────────
  static String contextualFollowUp(String topic, String emotion) {
    final Map<String, Map<String, String>> _responses = {
      'work': {
        'stress': "Work stress can really pile up. Has anything changed at work recently, or has it been building for a while?",
        'anxiety': "It sounds like work has been triggering a lot of worry. Is it the workload, the environment, or something else that's getting to you?",
        'depression': "When work feels overwhelming and joyless, it can drain everything else too. What's been the hardest part about your work situation?",
        'default': "It sounds like work has been on your mind a lot. What's been going on there?",
      },
      'family': {
        'stress': "Family dynamics can be a huge source of stress. Is there a specific situation with your family that's been weighing on you?",
        'anxiety': "Family situations can stir up a lot of worry. What's been happening with your family that's causing you anxiety?",
        'depression': "Family struggles can feel especially heavy because they're so personal. What's been going on at home?",
        'default': "It sounds like family has been on your mind. Want to tell me more about what's going on?",
      },
      'relationship': {
        'stress': "Relationship stress hits different because it's so personal. What's been happening between you and your partner?",
        'anxiety': "Relationships can bring up so much worry — about the future, about being enough. What's been on your mind?",
        'depression': "When things are tough in a relationship, it can color everything else. What's been the hardest part?",
        'default': "It sounds like your relationship has been on your mind. What's going on? 💙",
      },
      'school': {
        'stress': "Academic pressure can be relentless. Is it exams, workload, or something else about school that's stressing you out?",
        'anxiety': "School can trigger so much anxiety — the pressure to perform, the uncertainty. What's been the biggest worry?",
        'depression': "When school feels pointless or overwhelming, it can really affect your mood. What's been the toughest part?",
        'default': "It sounds like school has been weighing on you. What's been going on?",
      },
      'health': {
        'stress': "Dealing with health concerns on top of everything else is a lot. What's been going on with your health?",
        'anxiety': "Health worries can spiral so quickly. What's been concerning you about your health?",
        'depression': "Health struggles can feel isolating and exhausting. How has this been affecting your day-to-day life?",
        'default': "It sounds like health has been on your mind. Want to share more about what's going on? 💙",
      },
      'sleep': {
        'stress': "Stress and sleep are so connected — one makes the other worse. How has your sleep been lately?",
        'anxiety': "Anxiety and sleep problems often go hand in hand. Are you having trouble falling asleep, staying asleep, or both?",
        'depression': "Sleep changes are really common with depression — sleeping too much or too little. What's been happening with yours?",
        'default': "Sleep is so foundational to how we feel. What's been going on with your sleep?",
      },
      'friends': {
        'stress': "Friendships can be complicated, especially when you're already stressed. What's been happening with your friends?",
        'anxiety': "Social anxiety can make friendships feel really difficult. Is that something you've been dealing with?",
        'depression': "Feeling disconnected from friends when you're already down can make everything feel lonelier. What's been going on?",
        'default': "It sounds like things with friends have been on your mind. What's been happening? 💙",
      },
      'money': {
        'stress': "Financial stress is one of the heaviest things to carry. What's been the biggest pressure point with money?",
        'anxiety': "Money worries can keep your mind racing non-stop. What's been your biggest concern financially?",
        'depression': "Financial struggles can make everything feel more hopeless. What's been the hardest part about the money situation?",
        'default': "Money stress is really common and really tough. What's been going on with your finances?",
      },
    };

    final topicResponses = _responses[topic];
    if (topicResponses == null) {
      return followUp(emotion);
    }
    return topicResponses[emotion] ?? topicResponses['default'] ?? followUp(emotion);
  }

  // ─────────────────────────────────────────────
  // PERSONALIZED COPING (matches user's preferred style)
  // ─────────────────────────────────────────────
  static String personalizedCoping(String emotion, String? preferredStyle) {
    if (preferredStyle == null) return copingSuggestions(emotion);

    switch (preferredStyle) {
      case 'breathing':
        return _pick(const [
          "Since breathing exercises work well for you, here's one to try: the 4-7-8 technique — breathe in for 4 counts, hold for 7, and exhale slowly for 8. It activates your body's natural calming response. Even 3 rounds can make a noticeable difference 🌱",
          "Let's build on the breathing you already enjoy. Try box breathing: inhale 4 counts, hold 4, exhale 4, hold 4. Repeat for 2 minutes. It's simple but incredibly effective at resetting your nervous system 💙",
          "Here's a breathing exercise you might like: alternate nostril breathing. Close your right nostril, breathe in through the left for 4 counts, then close the left and breathe out through the right for 4 counts. Alternate for 5 rounds. It's deeply calming ✨",
        ], 'coping_breathing');
      case 'journaling':
        return _pick(const [
          "Since you like journaling, try this prompt: write about three things you're carrying right now, then for each one, write what you'd tell a friend in the same situation. It shifts your perspective gently 📝",
          "Here's a journaling exercise for you: set a timer for 10 minutes and write without stopping. Don't edit, don't judge — just let it flow. Getting thoughts on paper takes away some of their power 💙",
          "Try a gratitude journal twist: write down three difficult things you've handled this week and what they taught you. It helps reframe struggles as growth. You're already doing the hard work ✨",
        ], 'coping_journaling');
      case 'meditation':
        return _pick(const [
          "Since meditation resonates with you, try a body scan: lie down, close your eyes, and slowly bring attention to each part of your body from toes to head. Just notice — no fixing needed. Even 5 minutes can create a sense of calm 🌱",
          "Here's a meditation practice to try: loving-kindness meditation. Sit quietly and repeat: 'May I be happy. May I be healthy. May I be at peace.' Then extend it to someone you care about. It's powerful for shifting emotional states 💙",
          "Try a mindful walking meditation: walk slowly for 5-10 minutes, focusing entirely on the sensation of each step — the lift, the movement, the placement. It grounds you in the present moment ✨",
        ], 'coping_meditation');
      case 'exercise':
        return _pick(const [
          "Since movement helps you, try this: a 15-minute walk outside, focusing on what you see, hear, and feel. Combining movement with mindfulness doubles the benefit 🌿",
          "Here's something to try: gentle stretching for 10 minutes. Focus on areas where you hold tension — neck, shoulders, back. Slow, intentional movement releases both physical and emotional tension 💙",
          "Movement is one of the best mood regulators. Even a quick 7-minute workout or some dancing to your favorite song can shift your brain chemistry. No gym needed — just move in a way that feels good ✨",
        ], 'coping_exercise');
      case 'music':
        return _pick(const [
          "Since music speaks to you, try creating a playlist for your current mood — then create one for how you'd LIKE to feel. Gradually transitioning between them is a real therapeutic technique called the iso principle 🎵",
          "Here's a music therapy exercise: put on a song that matches how you feel right now, then follow it with one that's slightly more uplifting. Let the music guide your emotions gently toward a better place 💙",
          "Try this: lie down, put on headphones, and really listen to a piece of instrumental music for 5 minutes. Focus on individual instruments, the rhythm, the dynamics. It's meditation through music ✨",
        ], 'coping_music');
      default:
        return copingSuggestions(emotion);
    }
  }

  // ─────────────────────────────────────────────
  // PROGRESS ACKNOWLEDGMENT (stage-based)
  // ─────────────────────────────────────────────
  static String progressAcknowledgment(int messageCount) {
    if (messageCount <= 3) {
      return _pick(const [
        "I appreciate you opening up to me. It takes courage to share what you're going through 💙",
        "Thank you for trusting me with this. Just talking about it is a really positive step 🌱",
        "I'm glad you're here and willing to share. That matters more than you know.",
      ], 'progress_early');
    } else if (messageCount <= 8) {
      return _pick(const [
        "We've been talking for a bit and I can see you're really reflecting on things. That self-awareness is powerful 💙",
        "I've noticed how thoughtful you're being about all of this. That kind of introspection takes real strength 🌱",
        "We've covered a lot of ground together. I can tell you're really engaging with this, and that's a great sign.",
      ], 'progress_mid');
    } else {
      return _pick(const [
        "Looking back at our conversation, I can see how much you've opened up. That's real progress, and you should feel good about it 💙",
        "We've had a really meaningful conversation. The way you've explored your feelings shows incredible self-awareness 🌟",
        "Looking at how far we've come in this conversation, I'm really impressed by your willingness to dig deep. That takes courage ✨",
      ], 'progress_late');
    }
  }

  // ─────────────────────────────────────────────
  // STAGE-BASED RESPONSE SELECTOR
  // ─────────────────────────────────────────────

  /// Tracks whether the user has shown improvement during the conversation.
  static bool _userShowingImprovement = false;

  /// Tracks whether the user has mentioned sleep.
  static bool _userMentionedSleep = false;

  /// Call this to signal that the user is showing improvement.
  static void markImprovement() {
    _userShowingImprovement = true;
  }

  /// Call this to signal that the user mentioned sleep.
  static void markSleepMention() {
    _userMentionedSleep = true;
  }

  /// Resets conversation-level tracking (call at conversation start).
  static void resetConversationState() {
    _userShowingImprovement = false;
    _userMentionedSleep = false;
  }

  static String selectResponse({
    required ConversationStage stage,
    required String emotion,
    bool isChronic = false,
    bool isCrisis = false,
    bool crisisWasDetected = false,
    bool hadDistress = false,
    String? userMessage,
  }) {
    if (isCrisis) return crisisResponse();

    // Detect improvement signals from user message
    if (userMessage != null) {
      final lower = userMessage.toLowerCase();

      // Check for improvement signals
      if (lower.contains('better') ||
          lower.contains('improving') ||
          lower.contains('progress') ||
          lower.contains('good now') ||
          lower.contains('feeling great') ||
          lower.contains('much better') ||
          lower.contains('getting better')) {
        _userShowingImprovement = true;
      }

      // Check for sleep mentions
      if (lower.contains('sleep') ||
          lower.contains('insomnia') ||
          lower.contains('can\'t sleep') ||
          lower.contains('cant sleep') ||
          lower.contains('staying up') ||
          lower.contains('awake at night') ||
          lower.contains('tired') ||
          lower.contains('exhausted')) {
        _userMentionedSleep = true;
      }

      // Check for gratitude from user
      if (lower.contains('thank') ||
          lower.contains('thanks') ||
          lower.contains('grateful') ||
          lower.contains('appreciate')) {
        return gratitude();
      }
    }

    // If user is showing improvement and we're past early stages,
    // occasionally offer encouragement
    if (_userShowingImprovement &&
        (stage == ConversationStage.supportiveReflection ||
            stage == ConversationStage.followUpClarification)) {
      _userShowingImprovement = false; // Reset so we don't repeat
      return encouragement();
    }

    // If user mentioned sleep during coping or follow-up stages,
    // offer sleep advice
    if (_userMentionedSleep &&
        (stage == ConversationStage.copingSuggestions ||
            stage == ConversationStage.followUpClarification)) {
      _userMentionedSleep = false; // Reset so we don't repeat
      return sleepAdvice();
    }

    // Build contextual reflection prefix for early conversation stages
    // This mirrors the user's topic back so they feel heard
    String reflection = '';
    if (userMessage != null &&
        (stage == ConversationStage.moodCheckIn ||
            stage == ConversationStage.emotionalExploration)) {
      reflection = _buildReflection(userMessage);
    }

    String response;
    switch (stage) {
      case ConversationStage.greeting:
        return greeting();
      case ConversationStage.moodCheckIn:
        response = moodCheckIn(emotion, userMessage: userMessage);
        break;
      case ConversationStage.emotionalExploration:
        response = emotionalExploration(emotion, userMessage: userMessage);
        break;
      case ConversationStage.aiAnalysisTrigger:
        response = moodCheckIn(emotion, userMessage: userMessage);
        break;
      case ConversationStage.followUpClarification:
        response = followUp(emotion, userMessage: userMessage);
        break;
      case ConversationStage.supportiveReflection:
        response = supportiveReflection(emotion, isChronic, userMessage: userMessage);
        break;
      case ConversationStage.copingSuggestions:
        response = copingSuggestions(emotion, userMessage: userMessage);
        break;
      case ConversationStage.conversationClosing:
        return closing(emotion, crisisWasDetected, hadDistress: hadDistress);
    }

    // Prepend reflection only if it adds value (non-empty and doesn't
    // duplicate what the response already says)
    if (reflection.isNotEmpty) {
      final responseLower = response.toLowerCase();
      // Avoid double-mentioning the same topic
      final reflectionKeyword = RegExp(r'\b(work|school|family|sleep|friend|relationship|money|health)\b')
          .firstMatch(reflection.toLowerCase())
          ?.group(0);
      if (reflectionKeyword == null || !responseLower.contains(reflectionKeyword)) {
        return '$reflection$response';
      }
    }
    return response;
  }
}
