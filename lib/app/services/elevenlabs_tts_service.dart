// lib/app/services/elevenlabs_tts_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ElevenLabsTtsService {
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';
  final String? _apiKeyFromConstructor;
  final String _voiceId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _flutterTtsInitialized = false;
  
  int _currentKeyIndex = 0;

  // Cache untuk menyimpan audio bytes (opsional)
  final Map<String, Uint8List> _cache = {};

  // Stream subscription untuk menghindari memory leak
  StreamSubscription<PlayerState>? _playerStateSubscription;

  int _speakRequestId = 0;

  ElevenLabsTtsService({String? apiKey, String? voiceId})
    : _apiKeyFromConstructor = apiKey,
      _voiceId =
          voiceId ??
          dotenv.env['ELEVENLABS_VOICE_ID'] ??
          'pNInz6obpgDQGcFmaJgB' {
    if (_apiKeys.isEmpty) {
      print('⚠️ ELEVENLABS_API_KEY tidak ditemukan di .env');
    }
  }

  List<String> get _apiKeys {
    final keys = <String>[];
    final k0 = _apiKeyFromConstructor ?? dotenv.env['ELEVENLABS_API_KEY'] ?? '';
    final k1 = dotenv.env['ELEVENLABS_API_KEY_1'] ?? '';
    final k2 = dotenv.env['ELEVENLABS_API_KEY_2'] ?? '';
    final k3 = dotenv.env['ELEVENLABS_API_KEY_3'] ?? '';
    if (k0.isNotEmpty && !keys.contains(k0)) keys.add(k0);
    if (k1.isNotEmpty && !keys.contains(k1)) keys.add(k1);
    if (k2.isNotEmpty && !keys.contains(k2)) keys.add(k2);
    if (k3.isNotEmpty && !keys.contains(k3)) keys.add(k3);
    return keys;
  }

  String get _currentKey {
    final keys = _apiKeys;
    if (keys.isEmpty) return '';
    return keys[_currentKeyIndex % keys.length];
  }

  /// Generate audio dari teks dan putar langsung
  /// [onComplete] akan dipanggil ketika audio selesai diputar atau terjadi error
  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (text.trim().isEmpty) {
      onComplete?.call();
      return;
    }

    _speakRequestId++;
    final currentRequestId = _speakRequestId;
    bool isCompletedCalled = false;

    void safeOnComplete() {
      if (!isCompletedCalled && _speakRequestId == currentRequestId) {
        isCompletedCalled = true;
        onComplete?.call();
      }
    }

    try {
      // Cek cache
      Uint8List? audioData = _cache[text];
      if (audioData == null) {
        audioData = await _synthesizeWithRetry(text);
        _cache[text] = audioData;
      }

      if (_speakRequestId != currentRequestId) {
        // Request was aborted by a new one
        return;
      }

      // Simpan ke file sementara
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      await file.writeAsBytes(audioData);

      // Hentikan pemutaran sebelumnya jika ada
      await _audioPlayer.stop();
      // Batalkan subscription lama
      await _playerStateSubscription?.cancel();

      // Set sumber audio dan putar
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.file(file.path)));
      await _audioPlayer.play();

      // Dengarkan status pemutaran
      _playerStateSubscription = _audioPlayer.playerStateStream.listen(
        (state) {
          if (state.processingState == ProcessingState.completed) {
            // Hapus file setelah selesai diputar
            try { file.delete(); } catch(_) {}
            safeOnComplete();
          }
        },
        onError: (error) {
          print('❌ ElevenLabs TTS playback error: $error');
          try { file.delete(); } catch(_) {}
          safeOnComplete();
        },
      );
    } catch (e) {
      print('❌ ElevenLabs TTS error: $e. Fallback to Flutter TTS.');
      try {
        if (!_flutterTtsInitialized) {
          await _flutterTts.setLanguage("id-ID");
          await _flutterTts.setSpeechRate(0.5);
          await _flutterTts.setVolume(1.0);
          await _flutterTts.setPitch(1.0);
          _flutterTtsInitialized = true;
        }
        _flutterTts.setCompletionHandler(() {
          safeOnComplete();
        });
        _flutterTts.setErrorHandler((msg) {
          print('❌ Flutter TTS error: $msg');
          safeOnComplete();
        });
        await _flutterTts.speak(text);
      } catch (fallbackError) {
        print('❌ Flutter TTS fallback error: $fallbackError');
        safeOnComplete();
      }
    }
  }

  /// Synthesize teks ke audio (bytes) dengan multiple API key
  Future<Uint8List> _synthesizeWithRetry(String text) async {
    final keys = _apiKeys;
    if (keys.isEmpty) {
      throw Exception('Tidak ada API Key ElevenLabs yang tersedia.');
    }

    int attempts = 0;
    final maxAttempts = keys.length; // Coba semua key maksimal 1 putaran

    while (attempts < maxAttempts) {
      final key = _currentKey;
      try {
        final url = '$_baseUrl/text-to-speech/$_voiceId';

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'xi-api-key': key,
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
          },
          body: jsonEncode({
            'text': text,
            'model_id': 'eleven_multilingual_v2',
            'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75},
          }),
        );

        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else if (response.statusCode == 401 || response.statusCode == 429) {
          print('⚠️ ElevenLabs API error ${response.statusCode} on key index $_currentKeyIndex. Rotating to next key...');
          // Jika unauthorized atau rate limit, rotasi key dan coba lagi
          _currentKeyIndex++;
          attempts++;
          continue;
        } else {
          // Error lain (contoh: 500, 400), mungkin bukan masalah key
          throw Exception('ElevenLabs API error: ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ ElevenLabs API exception on key index $_currentKeyIndex: $e');
        _currentKeyIndex++;
        attempts++;
      }
    }
    
    // Jika sampai sini, berarti semua key gagal
    throw Exception('Semua API Key ElevenLabs gagal digunakan.');
  }

  /// Hentikan audio yang sedang diputar
  Future<void> stop() async {
    await _playerStateSubscription?.cancel();
    await _audioPlayer.stop();
    await _flutterTts.stop();
  }

  /// Dispose resource
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
  }
}

