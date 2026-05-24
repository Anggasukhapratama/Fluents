// lib/app/services/groq_service.dart
//
// ============================================================
// GROQ API SERVICE - SUPER CEPAT & GRATIS!
// ============================================================
// 🚀 Kecepatan: ~100 tokens/detik (10x lebih cepat dari Gemini)
// 🆓 Gratis: 14,400 requests per hari
// 🧠 Model: Llama 3.1 8B (sangat pintar)
// 
// CARA SETUP:
// 1. Daftar di: https://console.groq.com
// 2. Buat API Key gratis
// 3. Masukkan key di _apiKeys array di bawah
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  // ============================================================
  // 🔑 API KEY - Dibaca dari file .env
  // ============================================================
  // File .env harus berisi:
  // GROQ_API_KEY_1=gsk_xxxxx
  // GROQ_API_KEY_2=gsk_xxxxx (opsional)
  // GROQ_API_KEY_3=gsk_xxxxx (opsional)
  // ============================================================
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

  // Konfigurasi API
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _defaultModel = 'llama-3.1-8b-instant'; // Model tercepat
  static const int _timeoutSeconds = 30;

  // Singleton instance
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;
  GroqService._internal();

  // State internal
  int _currentKeyIndex = 0;
  final Map<int, DateTime> _blockedUntil = {};
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
    cleaned = cleaned.replaceAll(RegExp(r'^[\s]*\d+\.\s+', multiLine: true), '');
    
    // Hapus code blocks (```text```)
    cleaned = cleaned.replaceAll(RegExp(r'```[^`]*```', dotAll: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    
    // Bersihkan multiple newlines jadi single
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    
    return cleaned.trim();
  }

  // ============================================================
  // Ambil API Key yang aktif saat ini
  // ============================================================
  String get _currentKey {
    final validKeys = _apiKeys
        .where((k) => k.isNotEmpty && !k.contains('MASUKKAN'))
        .toList();

    if (validKeys.isEmpty) {
      throw Exception(
        '⚠️ Belum ada API Key Groq yang dimasukkan!\n'
        'Buka file: lib/app/services/groq_service.dart\n'
        'Tambahkan API Key Anda di bagian _apiKeys.\n'
        'Dapatkan key gratis di: https://console.groq.com',
      );
    }

    return _apiKeys[_currentKeyIndex];
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
    final alternatives = validIndices.where((i) => i != _currentKeyIndex).toList();
    if (alternatives.isNotEmpty) {
      _currentKeyIndex = alternatives.first;
      print('🔄 GroqService: Rotasi ke API Key #${_currentKeyIndex + 1}');
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

  // ============================================================
  // MAIN METHOD: Generate Text dengan Auto-Retry
  // ============================================================
  Future<String> generateText({
    required String prompt,
    String model = _defaultModel,
    int maxTokens = 1000,
    double temperature = 0.7,
    int maxRetries = 3,
    String fallback = '',
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      _totalRequests++;

      try {
        print('🚀 GroqService: Mengirim request (attempt $attempt)...');
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
                  {'role': 'user', 'content': prompt}
                ],
                'max_tokens': maxTokens,
                'temperature': temperature,
                'stream': false,
              }),
            )
            .timeout(Duration(seconds: _timeoutSeconds));

        final duration = DateTime.now().difference(startTime);
        print('⚡ GroqService: Response diterima dalam ${duration.inMilliseconds}ms');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content']?.toString().trim() ?? '';

          if (content.isEmpty) {
            print('⚠️ GroqService: Response kosong (attempt $attempt)');
            if (attempt < maxRetries) continue;
            return fallback;
          }

          _totalSuccess++;
          
          // Bersihkan markdown formatting dari response
          final cleanedContent = _cleanMarkdownFormatting(content);
          print('✅ GroqService: Berhasil! Panjang response: ${cleanedContent.length} karakter');
          return cleanedContent;
        } else if (response.statusCode == 429) {
          // Rate limit
          print('🚫 GroqService: Rate limit terdeteksi (attempt $attempt)');
          _markCurrentKeyRateLimited();

          if (!_rotateToNextKey() && attempt >= maxRetries) {
            print('❌ GroqService: Semua key kena limit. Gunakan fallback.');
            return fallback;
          }

          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          // Error lain
          print('❌ GroqService: HTTP Error ${response.statusCode}: ${response.body}');
          if (attempt >= maxRetries) return fallback;
        }
      } catch (e) {
        print('❌ GroqService: Exception: $e');
        if (attempt >= maxRetries) return fallback;
        
        // Tunggu sebentar sebelum retry
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return fallback;
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
    final prompt = '''
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
    final prompt = '''
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
    final prompt = '''
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
    final prompt = '''
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
        'cooldownRemaining': isBlocked ? blockedUntil.difference(now).inSeconds : 0,
      });
    }

    return {
      'service': 'Groq API',
      'model': _defaultModel,
      'currentKeyIndex': _currentKeyIndex + 1,
      'totalKeys': _apiKeys.where((k) => !k.contains('MASUKKAN')).length,
      'totalRequests': _totalRequests,
      'totalSuccess': _totalSuccess,
      'totalErrors': _totalErrors,
      'successRate': _totalRequests > 0 ? (_totalSuccess / _totalRequests * 100).toStringAsFixed(1) : '0.0',
      'keys': keyStatuses,
    };
  }

  void printStatus() {
    final status = statusInfo;
    print('📊 GroqService Status:');
    print('   Service: ${status['service']} (${status['model']})');
    print('   Active Key: #${status['currentKeyIndex']} of ${status['totalKeys']}');
    print('   Success Rate: ${status['successRate']}% (${status['totalSuccess']}/${status['totalRequests']})');
    print('   Errors: ${status['totalErrors']}');
    for (final k in (status['keys'] as List)) {
      final active = k['isActive'] ? ' ← AKTIF' : '';
      final blocked = k['isBlocked'] ? ' (cooldown: ${k['cooldownRemaining']}s)' : ' (ready)';
      print('   Key #${k['index']}:$blocked$active');
    }
  }

  // ============================================================
  // Test Connection
  // ============================================================
  Future<bool> testConnection() async {
    try {
      final result = await generateText(
        prompt: 'Halo, ini adalah test koneksi. Jawab dengan "Koneksi berhasil!"',
        maxTokens: 50,
        maxRetries: 1,
      );
      return result.toLowerCase().contains('koneksi berhasil') || result.isNotEmpty;
    } catch (e) {
      print('❌ GroqService Test: $e');
      return false;
    }
  }
}