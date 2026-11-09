# AI_PIPELINE — Model, Prompt, Memori, Mood, Speech

Seluruh inferensi berjalan **on-device** lewat `flutter_edge_ai` (pengganti `flutter_gemma`).

## 1. Engine terdaftar

`main.dart` mendaftarkan:

| Provider | Paket | File model |
| --- | --- | --- |
| `MediaPipeEngine()` | `flutter_edge_ai_mediapipe` | `.task` |
| `LiteRtLmEngine()` | `flutter_edge_ai_litertlm` | `.litertlm` |
| `LiteRtSttBackend()` | `flutter_edge_ai_speech` | STT |
| `LiteRtTtsBackend()` | `flutter_edge_ai_speech` | TTS |

## 2. Katalog LLM (`services/ai/model_catalog.dart`)

5 model, diunduh dari HuggingFace (`litert-community`) atau di-upload dari penyimpanan lokal.
Entri pertama adalah default.

| id | Nama | File | Engine | Ukuran | Catatan |
| --- | --- | --- | --- | --- | --- |
| `qwen2.5-1.5b` | Qwen 2.5 1.5B | `Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm` | LiteRT-LM | 1.6 GB | **default** |
| `qwen2.5-0.5b` | Qwen 2.5 0.5B | `...0.5B...ekv4096.task` | MediaPipe | 0.5 GB | RAM rendah |
| `smollm-135m` | SmolLM 135M | `SmolLM-135M-Instruct-q8_ekv2048.task` | MediaPipe | 135 MB | paling ringan |
| `deepseek-r1-1.5b` | DeepSeek R1 1.5B | `DeepSeek-R1-Distill-Qwen-1.5B-q8_ekv4096.task` | MediaPipe | 1.7 GB | reflektif |
| `gemma3-1b` | Gemma 3 1B | `Gemma3-1B-IT-multi-prefill-seq-q4_ekv4096.litertlm` | LiteRT-LM | 0.5 GB | **gated** (token HF) |

`ModelOption.edgeAiModelType` memetakan `modelType` → `ModelType.qwen|general|deepSeek|gemmaIt`;
`edgeAiFileType` memetakan `fileType` → `ModelFileType.litertlm|task`.

## 3. Install model (`ModelServiceNotifier`)

```
build()
  ├─ settings.modelVariant terisi & isModelInstalled(fileName) → getActiveModel, siap
  ├─ settings.modelSource kosong → install model default (CancelToken baru, progress)
  └─ selain itu → belum siap (tanpa auto-install ulang)

installFromNetwork(option, hfToken)
  └─ CancelToken baru; FlutterEdgeAi.installModel(...).fromNetwork(url, token)
       .withCancelToken(token).withProgress(...).install()
     → getActiveModel(preferredBackend: cpu, maxTokens: 2048)
     → simpan modelVariant = fileName, modelSource = 'network', modelUrl = url

installFromFile(path, option)
  └─ installModel(...).fromFile(path).install()
     → getActiveModel(...) → simpan modelVariant = nama file aktual, modelSource = 'file', modelUrl = ''
```

- Upload file menerima `.litertlm` dan `.task` saja.
- Identitas model yang dipakai `isModelInstalled` adalah **nama file**, bukan `id` katalog;
  upload dengan nama apa pun tetap terdaftar benar (lihat `modelOptionByFileName`).
- Token HF disimpan di `SharedPreferences` (`hf_token`) dan dibaca saat init engine.
- Batalkan unduhan: `cancelDownload()` → `CancelToken.cancel(...)`.

## 4. Inference

Satu `InferenceChat` per permintaan, ditutup setelah selesai:

```dart
final chat = await model.openChat(
  temperature: 0.9, randomSeed: 1, topK: 50, topP: 0.95,
);
await chat.addQueryChunk(Message.text(text: fullPrompt, isUser: true));
await for (final chunk in chat.generateChatResponseAsync()) {
  if (chunk is TextResponse) yield chunk.token;
}
```

Tidak ada state chat lintas-request; konteks dibangun ulang dari DB setiap kali.

## 5. Prompt (`services/ai/prompt_builder.dart`)

`buildSystemPrompt(persona, mood, memoryFacts, summary, {language})`:

1. `[INSTRUCTION]` — nama, gender, persona, hobi, mood (`mood` + intensitas), larangan
   mengaku AI, batas panjang 1–3 paragraf, larangan memberi nasihat medis/hukum/finansial.
2. Instruksi bahasa sesuai `AppSettings.language`:
   - `indonesian` → `Respond in Indonesian (Bahasa Indonesia).`
   - `english` → `Respond in English.`
   - `mixed` → `Respond in Indonesian or English, matching the user's language.`
3. `Information about <nickname>:` — daftar `- key: value` dari `MemoryFact`.
4. `[CONTEXT SUMMARY]` — `AppSettings.conversationSummary` bila ada.

`buildFullPrompt(system, recentMessages, latestUserInput)` menggabungkan system prompt,
maksimum **20** pesan terakhir, dan input user terbaru. Input user dipotong ke **2000**
karakter di `ChatNotifier.sendMessage`.

`buildSummarizationPrompt(messages)` memakai maksimum **60** pesan terakhir dan diminta menulis
ringkasan 3–5 kalimat. Ringkasan dibuat setiap **30** pesan (`summarizationInterval`).

## 6. Memori (`MemoryExtractor`)

Prompt meminta satu baris per fakta:

```
FACT: <category> | <key> | <value>
kategori: personal | event | preference | date
```

Parser: hanya baris berawalan `FACT:`, minimal 3 segmen `|`, `key`/`value` tidak kosong;
kategori tak dikenal → `personal`. Kegagalan inferensi → daftar kosong (tidak melempar).

Penggabungan (`ChatNotifier._postProcess`): fakta dicocokkan berdasarkan `key.toLowerCase()`
(jumlahnya dipotong bila prompt minta), fakta lama diperbarui `value`/`category`/`sourceSnippet`,
fakta baru disimpan dengan `sourceSnippet = <pesan user>`; lalu `memoryFactsProvider`
di-invalidate. Fakta yang dipakai saat menyusun prompt diperbarui `lastReferencedAt`-nya.

## 7. Content safety (`services/ai/content_safety.dart`)

Dua gate:

- `filterInput(text)` — sebelum prompt; regex ID+EN.
- `validateOutput(text)` — setelah generasi; jika terpicu, jawaban diganti deflection hangat.

Kategori: `explicitSexual`, `selfHarm`, `professionalAdvice`, `hateSpeech`,
`violenceInstruction`, `pii`. Redirect selalu diganti `FilterResult.redirectResponse`; pesan
asli tidak pernah ditampilkan.

## 8. Mood (`services/mood_service.dart`)

- `getCurrentMood()` membuat `MoodState` default (happy, 0.7) bila belum ada.
- `updateMoodFromConversation(aiResponse)` menghitung kemunculan kata kunci positif/tertentu:
  happy, excited, playful, sad; mood dengan skor tertinggi menang, intensitas naik
  (`+0.05`…`+0.15`, dibatasi 0.85–0.95).
- `updateMoodFromIdleTime()`: idle ≥ 6 jam → `longing` (intensitas +0.10, maks 0.80);
  idle ≥ 12 jam → `longing` 0.90.
- `recordInteraction()` hanya memperbarui `lastInteractionAt`.
- Mood saat ini diinjeksikan ke system prompt dan ditampilkan di AppBar/profil.

## 9. Speech

### TTS (`TtsService`)

| Backend | Implementasi | Model |
| --- | --- | --- |
| `gemma` | LiteRT TTS on-device → PCM 16-bit → `FlutterPcmSound` | `inflect` (8 MB, EN), `matcha` (~100 MB), `qwen3` (1.9 GB, 11 bahasa) |
| `system` | `flutter_tts` | suara OS |

`ensureReady(backend, model)` memasang model on-device bila `_readyModel != model` atau tidak ada
model aktif, sehingga ganti model benar-benar mengganti model. Selesai playback diperkirakan dari
durasi PCM (belum ada callback dari plugin).

### STT (`SttService`)

| Backend | Implementasi | Catatan |
| --- | --- | --- |
| `gemma` | rekam 16 kHz mono WAV (`record`) → `pcmFromWav` → `FlutterEdgeAi.getActiveStt().transcribe()` | model moonshine-tiny (75 MB) |
| `system` | `speech_to_text` | locale dari bahasa app (`id-ID`/`en-US`) |

`pcmFromWav` (`core/utils/wav_pcm.dart`) membaca chunk RIFF (`LIST`/`JUNK` sebelum `data`
ditangani, padding ganjil dilewati) dan melempar `FormatException` bila tidak ada chunk `data`.

## 10. Batas yang diketahui

Lihat [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md): tidak ada stop-generation, tanpa preflight storage,
tanpa peringatan RAM rendah, TTS selesai via timer, model 1.6 GB tidak tersedia di repo sehingga
inference end-to-end belum diverifikasi di lingkungan Linux ini.
