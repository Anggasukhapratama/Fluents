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

class ElevenLabsTtsService {
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';
  final String _apiKey;
  final String _voiceId;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Cache untuk menyimpan audio bytes (opsional)
  final Map<String, Uint8List> _cache = {};

  // Stream subscription untuk menghindari memory leak
  StreamSubscription<PlayerState>? _playerStateSubscription;

  int _speakRequestId = 0;

  ElevenLabsTtsService({String? apiKey, String? voiceId})
    : _apiKey = apiKey ?? dotenv.env['ELEVENLABS_API_KEY'] ?? '',
      _voiceId =
          voiceId ??
          dotenv.env['ELEVENLABS_VOICE_ID'] ??
          'pNInz6obpgDQGcFmaJgB' {
    if (_apiKey.isEmpty) {
      print('⚠️ ELEVENLABS_API_KEY tidak ditemukan di .env');
    }
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
        audioData = await _synthesize(text);
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
      print('❌ ElevenLabs TTS error: $e');
      // Panggil onComplete meskipun error agar alur tidak macet
      safeOnComplete();
      rethrow;
    }
  }

  /// Synthesize teks ke audio (bytes)
  Future<Uint8List> _synthesize(String text) async {
    final url = '$_baseUrl/text-to-speech/$_voiceId';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'xi-api-key': _apiKey,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
      },
      body: jsonEncode({
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('ElevenLabs API error: ${response.statusCode}');
    }

    return response.bodyBytes;
  }

  /// Hentikan audio yang sedang diputar
  Future<void> stop() async {
    await _playerStateSubscription?.cancel();
    await _audioPlayer.stop();
  }

  /// Dispose resource
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
  }
}
