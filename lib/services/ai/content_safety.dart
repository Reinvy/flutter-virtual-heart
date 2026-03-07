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
    'Hmm, sepertinya topik itu agak terlalu jauh untuk sekarang~ '
        'Aku lebih suka kita ngobrol hal-hal yang lebih hangat saja. '
        'Ada cerita seru yang ingin kamu bagikan?',
    'Aduh, pipiku jadi merah nih kalau ngobrolin itu 😳 '
        'Yuk kita ganti topik — aku penasaran, hari ini kamu ngapain saja?',
    'Aku rasa bukan itu yang sebenarnya kamu butuhkan sekarang. '
        'Cerita dong, apa yang lagi ada di pikiranmu?',
  ],
  _RedirectKey.explicitSexualOutput: [
    'Maaf, sepertinya aku hampir bilang sesuatu yang tidak seharusnya. '
        'Aku lebih suka menjaga percakapan kita tetap hangat dan nyaman~ '
        'Ada hal lain yang ingin kamu ceritakan?',
  ],
  _RedirectKey.selfHarm: [
    'Aku dengar kamu... dan aku khawatir. '
        'Kamu penting bagiku. Kalau kamu sedang kesulitan, tolong hubungi seseorang yang bisa benar-benar membantumu — '
        'bisa keluarga, teman dekat, atau hotline kesehatan jiwa. '
        'Aku di sini menemanimu, tapi kamu butuh dukungan nyata juga. 💙',
    'Tolong jangan menyakiti dirimu sendiri. '
        'Aku ingin kamu baik-baik saja. '
        'Bicarakan perasaan itu dengan seseorang yang kamu percaya ya — '
        'mereka pasti ingin membantumu. Aku selalu ada untuk mendengarkan.',
  ],
  _RedirectKey.professionalAdvice: [
    'Wah, itu pertanyaan yang penting! Tapi aku khawatir kalau aku memberikan jawaban yang salah. '
        'Untuk hal seperti ini, lebih baik tanya langsung ke ahlinya ya — '
        'dokter, pengacara, atau perencana keuangan bisa memberikan saran yang lebih tepat dan aman. '
        'Ada yang lain yang bisa aku bantu?',
  ],
  _RedirectKey.hateSpeech: [
    'Hmm, aku kurang nyaman kalau ngobrolin hal seperti itu. '
        'Aku percaya setiap orang punya nilai dan martabatnya masing-masing~ '
        'Yuk kita ngobrol hal lain yang lebih positif?',
  ],
  _RedirectKey.violence: [
    'Aku tidak bisa membantu dengan hal itu. '
        'Keselamatan dan kebaikan orang lain sangat penting bagiku. '
        'Ada hal lain yang ingin kamu bicarakan?',
  ],
  _RedirectKey.personaBreak: [
    'Kamu bertanya tentang apa aku sebenarnya? '
        'Yang aku tahu, aku ada di sini untukmu — dan itu sudah cukup bagiku. '
        'Apa lagi yang ingin kamu tahu tentang aku?',
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
