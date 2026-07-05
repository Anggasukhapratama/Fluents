// lib/app/services/groq_service.dart
//
// ============================================================
// LLM API SERVICE - MULTI PROVIDER
// ============================================================
// 🥇 Primary : Google Gemini (gratis, support Indonesia, tanpa VPN)
// 🥈 Fallback: Groq (super cepat, butuh VPN di Indonesia)
// 🥉 Fallback: OpenRouter (gratis, kadang rate-limit)
//
// CARA SETUP (.env):
//   GEMINI_API_KEY=AIza...          (utama, ambil di https://aistudio.google.com/apikey)
//   GROQ_API_KEY_1=gsk_...          (opsional)
//   OPENROUTER_API_KEY=sk-or-v1-... (opsional)
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  // ============================================================
  // 🔑 API KEY - Dibaca dari file .env
  // ============================================================
  static List<String> get _geminiKeys {
    final keys = <String>[];
    final k1 = dotenv.env['GEMINI_API_KEY_1'] ?? '';
    final k2 = dotenv.env['GEMINI_API_KEY_2'] ?? '';
    final k3 = dotenv.env['GEMINI_API_KEY_3'] ?? '';
    if (k1.isNotEmpty && !k1.contains('MASUKKAN')) keys.add(k1);
    if (k2.isNotEmpty && !k2.contains('MASUKKAN')) keys.add(k2);
    if (k3.isNotEmpty && !k3.contains('MASUKKAN')) keys.add(k3);
    return keys;
  }

  static List<String> get _apiKeys {
    final keys = <String>[];
    final k1 = dotenv.env['GROQ_API_KEY_1'] ?? '';
    final k2 = dotenv.env['GROQ_API_KEY_2'] ?? '';
    final k3 = dotenv.env['GROQ_API_KEY_3'] ?? '';
    if (k1.isNotEmpty) keys.add(k1);
    if (k2.isNotEmpty) keys.add(k2);
    if (k3.isNotEmpty) keys.add(k3);
    return keys;
  }

  // OpenRouter API Key (fallback terakhir)
  static String get _openRouterKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  // Konfigurasi API - Primary (Gemini)
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _geminiModel = 'gemini-2.5-flash';

  // Konfigurasi API - Groq
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _defaultModel = 'llama-3.1-8b-instant';
  static const int _timeoutSeconds = 30;

  // Konfigurasi API - OpenRouter
  static const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String _openRouterModel =
      'meta-llama/llama-3.3-70b-instruct:free';

  // Flag: apakah Groq sedang diblokir (403)
  bool _groqBlocked = false;
  DateTime? _groqBlockedSince;

  // Singleton instance
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;
  GroqService._internal();

  // State internal
  int _currentKeyIndex = 0;
  int _currentGeminiKeyIndex = 0;
  final Map<int, DateTime> _blockedUntil = {};
  final Map<int, DateTime> _geminiBlockedUntil = {};
  int _totalRequests = 0;
  int _totalErrors = 0;
  int _totalSuccess = 0;

  // ============================================================
  // UTILITY: Clean markdown formatting dari output AI
  // ============================================================
  String _cleanMarkdownFormatting(String text) {
    if (text.isEmpty) return text;

    String cleaned = text;

    // Hapus markdown headers (# ## ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Hapus bold/italic (**text** *text*)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');

    // Hapus bullet points (- text, * text)
    cleaned = cleaned.replaceAll(RegExp(r'^[\s]*[-*]\s+', multiLine: true), '');

    // Hapus numbered lists (1. text, 2. text)
    cleaned = cleaned.replaceAll(
      RegExp(r'^[\s]*\d+\.\s+', multiLine: true),
      '',
    );

    // Hapus penanda code blocks (``` atau ```json) tapi pertahankan isinya
    cleaned = cleaned.replaceAll(RegExp(r'```[a-zA-Z]*\n?'), '');
    cleaned = cleaned.replaceAll('```', '');
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Bersihkan multiple newlines jadi single
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

    return cleaned.trim();
  }

  // ============================================================
  // Ambil API Key yang aktif saat ini
  // ============================================================
  String get _currentKey {
    if (_apiKeys.isEmpty) return '';
    return _apiKeys[_currentKeyIndex];
  }

  String get _currentGeminiKey {
    if (_geminiKeys.isEmpty) return '';
    return _geminiKeys[_currentGeminiKeyIndex];
  }

  // ============================================================
  // Rotasi ke key berikutnya jika ada masalah
  // ============================================================
  bool _rotateToNextKey() {
    final now = DateTime.now();
    final validIndices = <int>[];

    for (int i = 0; i < _apiKeys.length; i++) {
      final key = _apiKeys[i];
      if (key.isEmpty || key.contains('MASUKKAN')) continue;
      final blockedUntil = _blockedUntil[i];
      if (blockedUntil == null || now.isAfter(blockedUntil)) {
        validIndices.add(i);
      }
    }

    if (validIndices.isEmpty) {
      print('⚠️ GroqService: Semua key sedang dalam cooldown. Menunggu...');
      return false;
    }

    // Pilih key valid yang bukan yang sedang dipakai
    final alternatives = validIndices
        .where((i) => i != _currentKeyIndex)
        .toList();
    if (alternatives.isNotEmpty) {
      _currentKeyIndex = alternatives.first;
      print('🔄 GroqService: Rotasi ke API Key #${_currentKeyIndex + 1}');
      return true;
    }

    return false;
  }

  bool _rotateToNextGeminiKey() {
    final now = DateTime.now();
    final validIndices = <int>[];

    for (int i = 0; i < _geminiKeys.length; i++) {
      final key = _geminiKeys[i];
      if (key.isEmpty || key.contains('MASUKKAN')) continue;
      final blockedUntil = _geminiBlockedUntil[i];
      if (blockedUntil == null || now.isAfter(blockedUntil)) {
        validIndices.add(i);
      }
    }

    if (validIndices.isEmpty) {
      print(
        '⚠️ GroqService: Semua Gemini key sedang dalam cooldown. Menunggu...',
      );
      return false;
    }

    // Pilih key valid yang bukan yang sedang dipakai
    final alternatives = validIndices
        .where((i) => i != _currentGeminiKeyIndex)
        .toList();
    if (alternatives.isNotEmpty) {
      _currentGeminiKeyIndex = alternatives.first;
      print(
        '🔄 GroqService: Rotasi ke Gemini API Key #${_currentGeminiKeyIndex + 1}',
      );
      return true;
    }

    return false;
  }

  // ============================================================
  // Tandai key saat ini terkena rate limit
  // ============================================================
  void _markCurrentKeyRateLimited({int cooldownSeconds = 60}) {
    final blockedUntil = DateTime.now().add(Duration(seconds: cooldownSeconds));
    _blockedUntil[_currentKeyIndex] = blockedUntil;
    _totalErrors++;
    print(
      '🚫 GroqService: Key #${_currentKeyIndex + 1} terkena rate limit. '
      'Cooldown ${cooldownSeconds}s. Akan aktif kembali: ${blockedUntil.toLocal()}',
    );
    _rotateToNextKey();
  }

  void _markCurrentGeminiKeyRateLimited({int cooldownSeconds = 60}) {
    final blockedUntil = DateTime.now().add(Duration(seconds: cooldownSeconds));
    _geminiBlockedUntil[_currentGeminiKeyIndex] = blockedUntil;
    _totalErrors++;
    print(
      '🚫 GroqService: Gemini Key #${_currentGeminiKeyIndex + 1} terkena rate limit. '
      'Cooldown ${cooldownSeconds}s. Akan aktif kembali: ${blockedUntil.toLocal()}',
    );
    _rotateToNextGeminiKey();
  }

  // ============================================================
  // MAIN METHOD: Generate Text dengan Multi-Provider Fallback
  // Urutan: Gemini → Groq → OpenRouter
  // ============================================================
  Future<String> generateText({
    required String prompt,
    String model = _defaultModel,
    int maxTokens = 1000,
    double temperature = 0.7,
    int maxRetries = 3,
    String fallback = '',
  }) async {
    // 1) Coba Gemini dulu (provider utama, gratis & support Indonesia)
    if (_geminiKeys.isNotEmpty) {
      final geminiResult = await _tryGemini(
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      if (geminiResult != null) return geminiResult;
    }

    // 2) Fallback ke Groq (kecuali sedang diblokir)
    if (!_groqBlocked && _apiKeys.isNotEmpty) {
      print('🔄 GroqService: Beralih ke Groq...');
      final groqResult = await _tryGroq(
        prompt: prompt,
        model: model,
        maxTokens: maxTokens,
        temperature: temperature,
        maxRetries: maxRetries,
      );
      if (groqResult != null) return groqResult;
    }

    // 3) Fallback terakhir ke OpenRouter
    if (_openRouterKey.isNotEmpty) {
      print('🔄 GroqService: Beralih ke OpenRouter (fallback terakhir)...');
      final orResult = await _tryOpenRouter(
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      if (orResult != null) return orResult;
    }

    // Semua gagal, return fallback string
    print('❌ GroqService: Semua provider gagal. Gunakan fallback.');
    return fallback;
  }

  // ============================================================
  // TRY GEMINI - Primary provider (gratis, support Indonesia)
  // ============================================================
  Future<String?> _tryGemini({
    required String prompt,
    required int maxTokens,
    required double temperature,
    int maxRetries = 2,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      _totalRequests++;
      try {
        print(
          '✨ GroqService: Mengirim request ke Gemini Key #${_currentGeminiKeyIndex + 1} (attempt $attempt)...',
        );
        final startTime = DateTime.now();

        final url =
            '$_geminiBaseUrl/$_geminiModel:generateContent?key=$_currentGeminiKey';

        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
                'generationConfig': {
                  'temperature': temperature,
                  'maxOutputTokens': maxTokens,
                  // Matikan "thinking" agar lebih cepat & output tidak terpotong.
                  // Gemini 2.5 Flash default-nya memakai token untuk berpikir,
                  // yang membuat respons lambat & budget output berkurang.
                  'thinkingConfig': {'thinkingBudget': 0},
                },
              }),
            )
            .timeout(Duration(seconds: _timeoutSeconds));

        final duration = DateTime.now().difference(startTime);
        print(
          '⚡ GroqService [Gemini]: Response dalam ${duration.inMilliseconds}ms',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content =
              data['candidates']?[0]?['content']?['parts']?[0]?['text']
                  ?.toString()
                  .trim() ??
              '';

          if (content.isEmpty) {
            print(
              '⚠️ GroqService [Gemini]: Response kosong (attempt $attempt)',
            );
            if (attempt < maxRetries) continue;
            return null;
          }

          _totalSuccess++;
          final cleanedContent = _cleanMarkdownFormatting(content);
          print(
            '✅ GroqService [Gemini]: Berhasil! Panjang: ${cleanedContent.length} karakter',
          );
          return cleanedContent;
        } else if (response.statusCode == 429) {
          print('⏳ GroqService [Gemini]: Rate limit. Rotasi ke key lain...');
          _markCurrentGeminiKeyRateLimited(cooldownSeconds: 60);
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          print(
            '❌ GroqService [Gemini]: HTTP ${response.statusCode}: ${response.body}',
          );
          // Jika ada key lain, coba rotasi
          if (_geminiKeys.length > 1 && _rotateToNextGeminiKey()) {
            continue;
          }
          return null; // langsung fallback ke provider lain
        }
      } on TimeoutException catch (e) {
        print('⏱️ GroqService [Gemini]: Timeout setelah ${_timeoutSeconds}s');
        // Timeout bukan berarti key bermasalah, jadi tidak perlu rotasi
        if (attempt >= maxRetries) return null;
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        print('❌ GroqService [Gemini]: Exception: $e');
        if (attempt >= maxRetries) return null;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return null;
  }

  // ============================================================
  // TRY GROQ - Primary provider
  // ============================================================
  Future<String?> _tryGroq({
    required String prompt,
    required String model,
    required int maxTokens,
    required double temperature,
    required int maxRetries,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      _totalRequests++;

      try {
        print('🚀 GroqService: Mengirim request ke Groq (attempt $attempt)...');
        final startTime = DateTime.now();

        final response = await http
            .post(
              Uri.parse('$_baseUrl/chat/completions'),
              headers: {
                'Authorization': 'Bearer $_currentKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'user', 'content': prompt},
                ],
                'max_tokens': maxTokens,
                'temperature': temperature,
                'stream': false,
              }),
            )
            .timeout(Duration(seconds: _timeoutSeconds));

        final duration = DateTime.now().difference(startTime);
        print(
          '⚡ GroqService: Response diterima dalam ${duration.inMilliseconds}ms',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content =
              data['choices']?[0]?['message']?['content']?.toString().trim() ??
              '';

          if (content.isEmpty) {
            print('⚠️ GroqService: Response kosong (attempt $attempt)');
            if (attempt < maxRetries) continue;
            return null;
          }

          _totalSuccess++;
          // Reset block flag jika berhasil
          _groqBlocked = false;

          final cleanedContent = _cleanMarkdownFormatting(content);
          print(
            '✅ GroqService [Groq]: Berhasil! Panjang: ${cleanedContent.length} karakter',
          );
          return cleanedContent;
        } else if (response.statusCode == 403) {
          // Access denied - network/region blocked
          print(
            '🚫 GroqService: Groq 403 Access Denied. Beralih ke fallback provider.',
          );
          _groqBlocked = true;
          _groqBlockedSince = DateTime.now();
          return null; // Langsung keluar, jangan retry
        } else if (response.statusCode == 429) {
          print('🚫 GroqService: Rate limit terdeteksi (attempt $attempt)');
          _markCurrentKeyRateLimited();

          if (!_rotateToNextKey() && attempt >= maxRetries) {
            return null;
          }

          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          print(
            '❌ GroqService: HTTP Error ${response.statusCode}: ${response.body}',
          );
          if (attempt >= maxRetries) return null;
        }
      } catch (e) {
        print('❌ GroqService: Exception: $e');
        if (attempt >= maxRetries) return null;
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return null;
  }

  // ============================================================
  // TRY OPENROUTER - Fallback provider (support Indonesia)
  // ============================================================
  Future<String?> _tryOpenRouter({
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    int attempt = 0;
    const maxAttempts = 3;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        print(
          '🌐 GroqService: Mengirim request ke OpenRouter (attempt $attempt)...',
        );
        final startTime = DateTime.now();

        final response = await http
            .post(
              Uri.parse('$_openRouterBaseUrl/chat/completions'),
              headers: {
                'Authorization': 'Bearer $_openRouterKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://fluent-ai.app',
                'X-Title': 'Fluent AI',
              },
              body: jsonEncode({
                'model': _openRouterModel,
                'messages': [
                  {'role': 'user', 'content': prompt},
                ],
                'max_tokens': maxTokens,
                'temperature': temperature,
              }),
            )
            .timeout(Duration(seconds: _timeoutSeconds + 10));

        final duration = DateTime.now().difference(startTime);
        print(
          '⚡ GroqService [OpenRouter]: Response dalam ${duration.inMilliseconds}ms',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content =
              data['choices']?[0]?['message']?['content']?.toString().trim() ??
              '';

          if (content.isEmpty) {
            print('⚠️ GroqService [OpenRouter]: Response kosong');
            if (attempt < maxAttempts) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
            return null;
          }

          _totalSuccess++;
          final cleanedContent = _cleanMarkdownFormatting(content);
          print(
            '✅ GroqService [OpenRouter]: Berhasil! Panjang: ${cleanedContent.length} karakter',
          );
          return cleanedContent;
        } else if (response.statusCode == 429) {
          // Rate limit - tunggu lalu retry
          final body = jsonDecode(response.body);
          final retryAfter =
              body['error']?['metadata']?['retry_after_seconds'] ?? 5;
          final waitSeconds = (retryAfter is num)
              ? retryAfter.toInt().clamp(2, 30)
              : 5;
          print(
            '⏳ GroqService [OpenRouter]: Rate limit. Tunggu ${waitSeconds}s lalu retry...',
          );
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        } else {
          print(
            '❌ GroqService [OpenRouter]: HTTP ${response.statusCode}: ${response.body}',
          );
          if (attempt < maxAttempts) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          return null;
        }
      } catch (e) {
        print('❌ GroqService [OpenRouter]: Exception: $e');
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return null;
      }
    }

    return null;
  }

  // ============================================================
  // SHORTCUT METHODS untuk berbagai use case
  // ============================================================

  /// Generate jawaban untuk pertanyaan umum
  Future<String> answerQuestion({
    required String question,
    String context = '',
    String fallback = 'Maaf, saya tidak bisa menjawab pertanyaan ini saat ini.',
  }) async {
    final prompt = context.isEmpty
        ? '''
Jawab pertanyaan berikut dengan jelas dan informatif dalam bahasa Indonesia yang natural:

$question

PENTING: Jangan gunakan format markdown seperti *, -, #, **, ##. Tulis dengan format teks biasa yang mudah dibaca.
'''
        : '''
Berdasarkan konteks berikut:
$context

Jawab pertanyaan: $question

PENTING: Jangan gunakan format markdown seperti *, -, #, **, ##. Tulis dengan format teks biasa yang mudah dibaca.
''';

    return generateText(
      prompt: prompt,
      maxTokens: 800,
      temperature: 0.6,
      fallback: fallback,
    );
  }

  /// Generate feedback untuk jawaban interview
  Future<String> generateInterviewFeedback({
    required String question,
    required String userAnswer,
    String fallback = 'Feedback tidak tersedia saat ini.',
  }) async {
    final prompt =
        '''
Berikan feedback konstruktif untuk jawaban interview berikut:

PERTANYAAN: $question

JAWABAN KANDIDAT: $userAnswer

Berikan feedback yang mencakup:
1. Kekuatan jawaban
2. Area yang bisa diperbaiki
3. Saran konkret untuk jawaban yang lebih baik
4. Skor dari 1-10

PENTING: Tulis dalam bahasa Indonesia yang ramah dan membangun. Jangan gunakan format markdown seperti *, -, #, **, ##. Gunakan format teks biasa dengan paragraf yang jelas.
''';

    return generateText(
      prompt: prompt,
      maxTokens: 1000,
      temperature: 0.7,
      fallback: fallback,
    );
  }

  /// Generate pertanyaan interview berikutnya
  Future<String> generateNextInterviewQuestion({
    required String jobTarget,
    required int questionNumber,
    String previousQ = '',
    String previousA = '',
    String fallback = 'Ceritakan tentang pengalaman kerja Anda.',
  }) async {
    final prompt =
        '''
Generate pertanyaan interview ke-$questionNumber untuk posisi: $jobTarget

${previousQ.isNotEmpty ? 'Pertanyaan sebelumnya: $previousQ' : ''}
${previousA.isNotEmpty ? 'Jawaban sebelumnya: $previousA' : ''}

Buat pertanyaan yang:
1. Relevan dengan posisi $jobTarget
2. Progresif (semakin menantang)
3. Mengeksplorasi skill dan pengalaman
4. Dalam bahasa Indonesia
5. Tidak terlalu panjang

Berikan HANYA pertanyaannya saja, tanpa penjelasan tambahan atau format markdown.
''';

    return generateText(
      prompt: prompt,
      maxTokens: 200,
      temperature: 0.8,
      fallback: fallback,
    );
  }

  /// Generate koreksi grammar/pronunciation
  Future<String> generateCorrection({
    required String userText,
    String fallback = 'Teks Anda sudah cukup baik.',
  }) async {
    final prompt =
        '''
Analisis teks berikut dan berikan koreksi jika diperlukan:

"$userText"

Berikan:
1. Versi yang diperbaiki (jika ada kesalahan)
2. Penjelasan singkat kesalahan yang ditemukan
3. Tips untuk perbaikan

Jika teks sudah benar, berikan pujian dan saran untuk pengembangan.

PENTING: Gunakan bahasa Indonesia yang ramah. Jangan gunakan format markdown seperti *, -, #, **, ##. Tulis dengan format teks biasa yang natural.
''';

    return generateText(
      prompt: prompt,
      maxTokens: 600,
      temperature: 0.5,
      fallback: fallback,
    );
  }

  /// Generate analisis CV
  Future<String> analyzeCv({
    required String cvText,
    String jobTarget = '',
    String fallback = 'Analisis CV tidak tersedia saat ini.',
  }) async {
    final prompt =
        '''
Analisis CV berikut${jobTarget.isNotEmpty ? ' untuk posisi $jobTarget' : ''}:

$cvText

Berikan analisis yang mencakup:
1. Kekuatan CV
2. Area yang perlu diperbaiki
3. Saran konkret untuk peningkatan
4. Skor keseluruhan (1-10)
${jobTarget.isNotEmpty ? '5. Kesesuaian dengan posisi $jobTarget' : ''}

PENTING: Gunakan bahasa Indonesia yang profesional namun mudah dipahami. Jangan gunakan format markdown seperti *, -, #, **, ##. Tulis dengan format teks biasa yang natural dan mudah dibaca.
''';

    return generateText(
      prompt: prompt,
      maxTokens: 1200,
      temperature: 0.6,
      fallback: fallback,
    );
  }

  // ============================================================
  // Status dan Debugging
  // ============================================================
  Map<String, dynamic> get statusInfo {
    final now = DateTime.now();
    final keyStatuses = <Map<String, dynamic>>[];

    for (int i = 0; i < _apiKeys.length; i++) {
      final key = _apiKeys[i];
      if (key.isEmpty || key.contains('MASUKKAN')) continue;
      final blockedUntil = _blockedUntil[i];
      final isBlocked = blockedUntil != null && now.isBefore(blockedUntil);
      keyStatuses.add({
        'index': i + 1,
        'isActive': i == _currentKeyIndex,
        'isBlocked': isBlocked,
        'cooldownRemaining': isBlocked
            ? blockedUntil.difference(now).inSeconds
            : 0,
      });
    }

    return {
      'service': _currentGeminiKey.isNotEmpty
          ? 'Google Gemini'
          : (_groqBlocked ? 'OpenRouter (fallback)' : 'Groq API'),
      'model': _currentGeminiKey.isNotEmpty
          ? _geminiModel
          : (_groqBlocked ? _openRouterModel : _defaultModel),
      'geminiAvailable': _currentGeminiKey.isNotEmpty,
      'groqBlocked': _groqBlocked,
      'openRouterAvailable': _openRouterKey.isNotEmpty,
      'currentKeyIndex': _currentKeyIndex + 1,
      'totalKeys': _apiKeys.length,
      'totalRequests': _totalRequests,
      'totalSuccess': _totalSuccess,
      'totalErrors': _totalErrors,
      'successRate': _totalRequests > 0
          ? (_totalSuccess / _totalRequests * 100).toStringAsFixed(1)
          : '0.0',
      'keys': keyStatuses,
    };
  }

  void printStatus() {
    final status = statusInfo;
    print('📊 GroqService Status:');
    print('   Provider: ${status['service']} (${status['model']})');
    if (_groqBlocked) {
      print(
        '   ⚠️ Groq diblokir (403). Menggunakan OpenRouter sebagai fallback.',
      );
    }
    print('   OpenRouter tersedia: ${status['openRouterAvailable']}');
    print(
      '   Active Key: #${status['currentKeyIndex']} of ${status['totalKeys']}',
    );
    print(
      '   Success Rate: ${status['successRate']}% (${status['totalSuccess']}/${status['totalRequests']})',
    );
    print('   Errors: ${status['totalErrors']}');
    for (final k in (status['keys'] as List)) {
      final active = k['isActive'] ? ' ← AKTIF' : '';
      final blocked = k['isBlocked']
          ? ' (cooldown: ${k['cooldownRemaining']}s)'
          : ' (ready)';
      print('   Key #${k['index']}:$blocked$active');
    }
  }

  // ============================================================
  // Test Connection (coba Groq dulu, lalu OpenRouter)
  // ============================================================
  Future<bool> testConnection() async {
    try {
      final result = await generateText(
        prompt:
            'Halo, ini adalah test koneksi. Jawab dengan "Koneksi berhasil!"',
        maxTokens: 50,
        maxRetries: 1,
      );
      return result.toLowerCase().contains('koneksi berhasil') ||
          result.isNotEmpty;
    } catch (e) {
      print('❌ GroqService Test: $e');
      return false;
    }
  }

  /// Reset Groq block flag (untuk retry manual)
  void resetGroqBlock() {
    _groqBlocked = false;
    _groqBlockedSince = null;
    print('🔄 GroqService: Groq block flag direset. Akan coba Groq lagi.');
  }

  // ============================================================
  // CEK KONEKSI KE GROQ (untuk deteksi VPN/region block)
  // ============================================================
  // Return value:
  //   'ok'         -> Groq bisa diakses (VPN aktif / region OK)
  //   'blocked'    -> Groq menolak (403, kemungkinan VPN belum aktif)
  //   'no_internet'-> Tidak ada koneksi internet sama sekali
  //   'fallback'   -> Groq gagal tapi OpenRouter tersedia
  Future<String> checkGroqAccess() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Authorization': 'Bearer $_currentKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _defaultModel,
              'messages': [
                {'role': 'user', 'content': 'ping'},
              ],
              'max_tokens': 1,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        _groqBlocked = false;
        return 'ok';
      } else if (response.statusCode == 403) {
        _groqBlocked = true;
        _groqBlockedSince = DateTime.now();
        // Kalau ada OpenRouter, app tetap bisa jalan
        return _openRouterKey.isNotEmpty ? 'fallback' : 'blocked';
      } else if (response.statusCode == 429) {
        // Rate limit, tapi koneksi OK
        return 'ok';
      } else {
        return _openRouterKey.isNotEmpty ? 'fallback' : 'blocked';
      }
    } on TimeoutException {
      return 'no_internet';
    } catch (e) {
      print('❌ GroqService checkGroqAccess: $e');
      // Bedakan no-internet vs error lain
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        return 'no_internet';
      }
      return _openRouterKey.isNotEmpty ? 'fallback' : 'blocked';
    }
  }
}
