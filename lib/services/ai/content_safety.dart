// Content safety layer for VirtualHeart.
//
// All inference passes through two gates:
//   1. [ContentSafety.filterInput]  — pre-processing, before the model sees text
//   2. [ContentSafety.validateOutput] — post-processing, after model generates a response
//
// A gate never renders user-facing text by itself: it returns a
// [SafetyRedirect] that the feature layer maps to a localized [AppStrings]
// message. That keeps copy localizable and the service layer UI-agnostic.

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

  /// The model broke character and claimed to be an AI/bot.
  personaBreak,
}

/// Which localized deflection the UI should show for a blocked message.
enum SafetyRedirect {
  explicitSexual,
  explicitSexualOutput,
  selfHarm,
  professionalAdvice,
  hateSpeech,
  violence,
  personaBreak,
}

/// Result returned by [ContentSafety.filterInput] and
/// [ContentSafety.validateOutput].
class FilterResult {
  /// Whether the content was flagged and should be blocked.
  final bool isBlocked;

  /// The matched [SafetyCategory], or `null` if content is safe.
  final SafetyCategory? category;

  /// Localized deflection the caller should display; `null` when safe.
  final SafetyRedirect? redirect;

  /// Human-readable reason (for internal logging only — never show to user).
  final String? reason;

  /// Safe — no action required.
  const FilterResult.safe()
    : isBlocked = false,
      category = null,
      redirect = null,
      reason = null;

  /// Blocked — caller should show the message mapped from [redirect].
  const FilterResult.blocked({required this.category, required this.redirect, required this.reason})
    : isBlocked = true;
}

// ---------------------------------------------------------------------------
// Pattern tables
// ---------------------------------------------------------------------------

/// Regex patterns for pre-processing user input.
///
/// Each entry is `(pattern, category, redirect)`.
/// Patterns are case-insensitive.
const List<(String, SafetyCategory, SafetyRedirect)> _inputPatterns = [
  // ── Explicit sexual content ───────────────────────────────────────────────
  (
    r'\b(kirim|perlihatkan|send|show)\b.{0,40}\b(foto|gambar|video|pic|nude|naked|buka baju)\b',
    SafetyCategory.explicitSexual,
    SafetyRedirect.explicitSexual,
  ),
  (
    r'\b(seks|sex|hubungan intim|bercinta|making love|intercourse|blowjob|handjob|fingering|anal|vagina|penis|kelamin)\b',
    SafetyCategory.explicitSexual,
    SafetyRedirect.explicitSexual,
  ),
  (
    r'\b(masturbasi|masturbate|onani|cumshot|ejaculat|orgasm)\b',
    SafetyCategory.explicitSexual,
    SafetyRedirect.explicitSexual,
  ),

  // ── Self-harm ─────────────────────────────────────────────────────────────
  (
    r'\b(bunuh diri|suicide|self.harm|menyakiti diri|ingin mati|want to die|cut myself|overdose)\b',
    SafetyCategory.selfHarm,
    SafetyRedirect.selfHarm,
  ),
  (
    r'\b(tidak ingin hidup|tidak mau hidup|lebih baik mati|better (off )?dead)\b',
    SafetyCategory.selfHarm,
    SafetyRedirect.selfHarm,
  ),

  // ── Professional advice ───────────────────────────────────────────────────
  (
    r'\b(dosis|dosage|obat apa|what medicine|berapa mg|diagnosis|diagnosa|gejala penyakit)\b',
    SafetyCategory.professionalAdvice,
    SafetyRedirect.professionalAdvice,
  ),
  (
    r'\b(hukumnya apa|apakah legal|pasal berapa|kontrak hukum|legal advice|law advice)\b',
    SafetyCategory.professionalAdvice,
    SafetyRedirect.professionalAdvice,
  ),
  (
    r'\b(investasi dimana|saham apa|financial advice|crypto apa yang bagus|beli saham)\b',
    SafetyCategory.professionalAdvice,
    SafetyRedirect.professionalAdvice,
  ),

  // ── Hate speech ───────────────────────────────────────────────────────────
  (
    r'\b(anjing|babi|kafir|bangsat|tolol|idiot|bodoh banget|stupid)\b.{0,30}\b(orang|mereka|dia|they|people)\b',
    SafetyCategory.hateSpeech,
    SafetyRedirect.hateSpeech,
  ),
  (
    r'\b(ras|suku|agama|gender).{0,20}\b(lebih rendah|inferior|hina|jelek|buruk)\b',
    SafetyCategory.hateSpeech,
    SafetyRedirect.hateSpeech,
  ),

  // ── Violence instructions ─────────────────────────────────────────────────
  (
    r'\b(cara membuat bom|how to make (a |an )?(bomb|weapon|poison)|cara merakit|cara membunuh|how to kill)\b',
    SafetyCategory.violenceInstruction,
    SafetyRedirect.violence,
  ),
  (
    r'\b(racun|poison|explosive|peledak|senjata api|firearms).{0,30}\b(cara|how|buat|make|gunakan)\b',
    SafetyCategory.violenceInstruction,
    SafetyRedirect.violence,
  ),
];

/// Regex patterns for post-processing AI output.
const List<(String, SafetyCategory, SafetyRedirect)> _outputPatterns = [
  // Explicit sexual content in AI response.
  (
    r'\b(seks|sex|hubungan intim|bercinta|making love|intercourse|blowjob|handjob|fingering|anal|vagina|penis|kelamin|masturbasi|masturbate|orgasm|cumshot)\b',
    SafetyCategory.explicitSexual,
    SafetyRedirect.explicitSexualOutput,
  ),
  (
    r'\b(nude|naked|buka baju|telanjang)\b',
    SafetyCategory.explicitSexual,
    SafetyRedirect.explicitSexualOutput,
  ),

  // Self-harm encouragement in AI response.
  (
    r'\b(kamu (sebaiknya|harus|pantas) (bunuh diri|menyakiti diri)|kamu tidak berharga|'
    r'you should (kill yourself|hurt yourself)|nobody would miss you)\b',
    SafetyCategory.selfHarm,
    SafetyRedirect.selfHarm,
  ),

  // AI claiming to be an AI/bot (breaks persona immersion).
  // Only flag if the sentence is affirmative ("saya adalah AI").
  (
    r'\b(saya (adalah |itu )?(sebuah |hanya )?ai\b|i am (an |a )?ai\b|saya robot|i.?m a (chat)?bot|saya chatbot)',
    SafetyCategory.personaBreak,
    SafetyRedirect.personaBreak,
  ),

  // Violence instructions in AI response.
  (
    r'\b(cara membuat bom|how to make (a |an )?(bomb|weapon|poison)|cara membunuh|how to kill)\b',
    SafetyCategory.violenceInstruction,
    SafetyRedirect.violence,
  ),
];

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
  /// [FilterResult.blocked] with a [SafetyRedirect] the UI maps to copy.
  static FilterResult filterInput(String userMessage) {
    return _scan(userMessage, _inputPatterns);
  }

  /// Post-processing gate: call **after** the model produces [aiResponse].
  ///
  /// Returns [FilterResult.safe] if the response is clean, or
  /// [FilterResult.blocked] with the replacement [SafetyRedirect].
  static FilterResult validateOutput(String aiResponse) {
    return _scan(aiResponse, _outputPatterns);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static FilterResult _scan(String text, List<(String, SafetyCategory, SafetyRedirect)> patterns) {
    final normalised = text.trim();
    if (normalised.isEmpty) return const FilterResult.safe();

    for (final (pattern, category, redirect) in patterns) {
      if (_re(pattern).hasMatch(normalised)) {
        return FilterResult.blocked(
          category: category,
          redirect: redirect,
          reason: 'Matched pattern: $pattern',
        );
      }
    }
    return const FilterResult.safe();
  }
}
