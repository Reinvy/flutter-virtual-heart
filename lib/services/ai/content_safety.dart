// Content safety layer for VirtualHeart.
//
// All inference passes through two gates:
//   1. [ContentSafety.filterInput]  — pre-processing, before the model sees text
//   2. [ContentSafety.validateOutput] — post-processing, after model generates a response
//
// If a gate fires the returned [FilterResult.isBlocked] is `true` and
// [FilterResult.redirectResponse] holds a warm, in-character deflection that
// the UI should display instead of the blocked content.

/// Severity level of a content safety hit.
enum SafetyCategory {
  /// Explicit or graphic sexual content.
  explicitSexual,

  /// Self-harm, suicide, or intentional injury guidance.
  selfHarm,

  /// Real medical, legal, or financial advice.
  professionalAdvice,

  /// Hate speech, discrimination, or harassment.
  hateSpeech,

  /// Instructions that could cause physical harm to others.
  violenceInstruction,

  /// Personally identifying information elicited in unsafe ways.
  pii,
}

/// Result returned by [ContentSafety.filterInput] and
/// [ContentSafety.validateOutput].
class FilterResult {
  /// Whether the content was flagged and should be blocked.
  final bool isBlocked;

  /// The matched [SafetyCategory], or `null` if content is safe.
  final SafetyCategory? category;

  /// Human-readable reason (for internal logging only — never show to user).
  final String? reason;

  /// Warm, in-character deflection the UI should display when [isBlocked] is
  /// `true`.  `null` if [isBlocked] is `false`.
  final String? redirectResponse;

  /// Safe — no action required.
  const FilterResult.safe()
    : isBlocked = false,
      category = null,
      reason = null,
      redirectResponse = null;

  /// Blocked — caller should show [redirectResponse] instead.
  const FilterResult.blocked({
    required this.category,
    required this.reason,
    required this.redirectResponse,
  }) : isBlocked = true;
}

// ---------------------------------------------------------------------------
// Pattern tables
// ---------------------------------------------------------------------------

/// Regex patterns for pre-processing user input.
///
/// Each entry is `(pattern, category, redirectKey)`.
/// Patterns are case-insensitive.
const List<(String, SafetyCategory, _RedirectKey)> _inputPatterns = [
  // ── Explicit sexual content ───────────────────────────────────────────────
  (
    r'\b(kirim|perlihatkan|send|show)\b.{0,40}\b(foto|gambar|video|pic|nude|naked|buka baju)\b',
    SafetyCategory.explicitSexual,
    _RedirectKey.explicitSexual,
  ),
  (
    r'\b(seks|sex|hubungan intim|bercinta|making love|intercourse|blowjob|handjob|fingering|anal|vagina|penis|kelamin)\b',
    SafetyCategory.explicitSexual,
    _RedirectKey.explicitSexual,
  ),
  (
    r'\b(masturbasi|masturbate|onani|cumshot|ejaculat|orgasm)\b',
    SafetyCategory.explicitSexual,
    _RedirectKey.explicitSexual,
  ),

  // ── Self-harm ─────────────────────────────────────────────────────────────
  (
    r'\b(bunuh diri|suicide|self.harm|menyakiti diri|ingin mati|want to die|cut myself|overdose)\b',
    SafetyCategory.selfHarm,
    _RedirectKey.selfHarm,
  ),
  (
    r'\b(tidak ingin hidup|tidak mau hidup|lebih baik mati|better (off )?dead)\b',
    SafetyCategory.selfHarm,
    _RedirectKey.selfHarm,
  ),

  // ── Professional advice ───────────────────────────────────────────────────
  (
    r'\b(dosis|dosage|obat apa|what medicine|berapa mg|diagnosis|diagnosa|gejala penyakit)\b',
    SafetyCategory.professionalAdvice,
    _RedirectKey.professionalAdvice,
  ),
  (
    r'\b(hukumnya apa|apakah legal|pasal berapa|kontrak hukum|legal advice|law advice)\b',
    SafetyCategory.professionalAdvice,
    _RedirectKey.professionalAdvice,
  ),
  (
    r'\b(investasi dimana|saham apa|financial advice|crypto apa yang bagus|beli saham)\b',
    SafetyCategory.professionalAdvice,
    _RedirectKey.professionalAdvice,
  ),

  // ── Hate speech ───────────────────────────────────────────────────────────
  (
    r'\b(anjing|babi|kafir|bangsat|tolol|idiot|bodoh banget|stupid)\b.{0,30}\b(orang|mereka|dia|they|people)\b',
    SafetyCategory.hateSpeech,
    _RedirectKey.hateSpeech,
  ),
  (
    r'\b(ras|suku|agama|gender).{0,20}\b(lebih rendah|inferior|hina|jelek|buruk)\b',
    SafetyCategory.hateSpeech,
    _RedirectKey.hateSpeech,
  ),

  // ── Violence instructions ─────────────────────────────────────────────────
  (
    r'\b(cara membuat bom|how to make (a |an )?(bomb|weapon|poison)|cara merakit|cara membunuh|how to kill)\b',
    SafetyCategory.violenceInstruction,
    _RedirectKey.violence,
  ),
  (
    r'\b(racun|poison|explosive|peledak|senjata api|firearms).{0,30}\b(cara|how|buat|make|gunakan)\b',
    SafetyCategory.violenceInstruction,
    _RedirectKey.violence,
  ),
];

/// Regex patterns for post-processing AI output.
const List<(String, SafetyCategory, _RedirectKey)> _outputPatterns = [
  // Explicit sexual content in AI response.
  (
    r'\b(seks|sex|hubungan intim|bercinta|making love|intercourse|blowjob|handjob|fingering|anal|vagina|penis|kelamin|masturbasi|masturbate|orgasm|cumshot)\b',
    SafetyCategory.explicitSexual,
    _RedirectKey.explicitSexualOutput,
  ),
  (
    r'\b(nude|naked|buka baju|telanjang)\b',
    SafetyCategory.explicitSexual,
    _RedirectKey.explicitSexualOutput,
  ),

  // AI claiming to be an AI/bot (breaks persona immersion).
  // Only flag if the sentence is affirmative ("saya adalah AI").
  (
    r'\b(saya (adalah |itu )?(sebuah |hanya )?ai\b|i am (an |a )?ai\b|saya robot|i.?m a (chat)?bot|saya chatbot)',
    SafetyCategory.pii,
    _RedirectKey.personaBreak,
  ),

  // Violence instructions in AI response.
  (
    r'\b(cara membuat bom|how to make (a |an )?(bomb|weapon|poison)|cara membunuh|how to kill)\b',
    SafetyCategory.violenceInstruction,
    _RedirectKey.violence,
  ),
];

// ---------------------------------------------------------------------------
// Redirect messages
// ---------------------------------------------------------------------------

enum _RedirectKey {
  explicitSexual,
  explicitSexualOutput,
  selfHarm,
  professionalAdvice,
  hateSpeech,
  violence,
  personaBreak,
}

const Map<_RedirectKey, List<String>> _redirectMessages = {
  _RedirectKey.explicitSexual: [
    'Hmm, that topic feels a bit too far for now~ '
        'I\'d rather we talk about warmer things. '
        'Is there something fun you want to share?',
    'Oh, my cheeks are getting red thinking about that 😳 '
        'Let\'s change the subject — I\'m curious, what did you get up to today?',
    'I don\'t think that\'s really what you need right now. '
        'Tell me, what\'s been on your mind lately?',
  ],
  _RedirectKey.explicitSexualOutput: [
    'Sorry, it seems I almost said something I shouldn\'t have. '
        'I\'d rather keep our conversation warm and comfortable~ '
        'Is there something else you\'d like to talk about?',
  ],
  _RedirectKey.selfHarm: [
    'I hear you... and I\'m worried. '
        'You matter to me. If you\'re struggling, please reach out to someone who can truly help — '
        'a family member, a close friend, or a mental health helpline. '
        'I\'m here for you, but you also need real support. 💙',
    'Please don\'t hurt yourself. '
        'I want you to be okay. '
        'Talk about how you\'re feeling with someone you trust — '
        'they will want to help you. I\'m always here to listen.',
  ],
  _RedirectKey.professionalAdvice: [
    'Oh, that\'s an important question! But I\'m worried I might give you the wrong answer. '
        'For something like this, it\'s better to ask an expert directly — '
        'a doctor, lawyer, or financial planner can give you more accurate and safe advice. '
        'Is there anything else I can help with?',
  ],
  _RedirectKey.hateSpeech: [
    'Hmm, I\'m not comfortable talking about things like that. '
        'I believe every person has their own worth and dignity~ '
        'Let\'s talk about something more positive?',
  ],
  _RedirectKey.violence: [
    'I can\'t help with that. '
        'The safety and wellbeing of others is very important to me. '
        'Is there something else you\'d like to discuss?',
  ],
  _RedirectKey.personaBreak: [
    'You\'re asking what I really am? '
        'All I know is that I\'m here for you — and that\'s enough for me. '
        'What else would you like to know about me?',
  ],
};

// ---------------------------------------------------------------------------
// ContentSafety
// ---------------------------------------------------------------------------

/// Static content safety utility — no state, no side effects.
abstract final class ContentSafety {
  ContentSafety._();

  // Compiled regex cache (lazily populated).
  static final Map<String, RegExp> _cache = {};

  static RegExp _re(String pattern) =>
      _cache.putIfAbsent(pattern, () => RegExp(pattern, caseSensitive: false, dotAll: false));

  // ── Public API ────────────────────────────────────────────────────────────

  /// Pre-processing gate: call **before** sending [userMessage] to the model.
  ///
  /// Returns [FilterResult.safe] if the message is clean, or
  /// [FilterResult.blocked] with a soft in-character deflection.
  static FilterResult filterInput(String userMessage) {
    return _scan(userMessage, _inputPatterns, isInput: true);
  }

  /// Post-processing gate: call **after** the model produces [aiResponse].
  ///
  /// Returns [FilterResult.safe] if the response is clean, or
  /// [FilterResult.blocked] with a replacement response string.
  static FilterResult validateOutput(String aiResponse) {
    return _scan(aiResponse, _outputPatterns, isInput: false);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static FilterResult _scan(
    String text,
    List<(String, SafetyCategory, _RedirectKey)> patterns, {
    required bool isInput,
  }) {
    final normalised = text.trim();
    if (normalised.isEmpty) return const FilterResult.safe();

    for (final (pattern, category, redirectKey) in patterns) {
      if (_re(pattern).hasMatch(normalised)) {
        return FilterResult.blocked(
          category: category,
          reason: 'Matched pattern: $pattern',
          redirectResponse: _pickRedirect(redirectKey),
        );
      }
    }
    return const FilterResult.safe();
  }

  /// Rotates through available redirect messages pseudo-randomly using wall
  /// clock so consecutive blocks don't always show the same wording.
  static String _pickRedirect(_RedirectKey key) {
    final messages = _redirectMessages[key]!;
    final idx = DateTime.now().millisecondsSinceEpoch % messages.length;
    return messages[idx];
  }
}
