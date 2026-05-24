// lib/test_groq.dart
// 
// FILE TEST UNTUK MEMVERIFIKASI GROQ API
// Jalankan: flutter run lib/test_groq.dart
//

import 'package:flutter/material.dart';
import 'app/services/groq_service.dart';

void main() {
  runApp(const GroqTestApp());
}

class GroqTestApp extends StatelessWidget {
  const GroqTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groq API Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GroqTestPage(),
    );
  }
}

class GroqTestPage extends StatefulWidget {
  const GroqTestPage({super.key});

  @override
  State<GroqTestPage> createState() => _GroqTestPageState();
}

class _GroqTestPageState extends State<GroqTestPage> {
  final GroqService _groqService = GroqService();
  
  String _result = '';
  bool _isLoading = false;
  String _status = 'Belum ditest';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Groq API Test'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _getStatusColor(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Provider: Groq (Llama 3.1 8B)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering),
              label: Text(_isLoading ? 'Testing...' : 'Test Koneksi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testQuestionGeneration,
              icon: const Icon(Icons.quiz),
              label: const Text('Test Generate Pertanyaan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFeedback,
              icon: const Icon(Icons.feedback),
              label: const Text('Test Generate Feedback'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _printStatus,
              icon: const Icon(Icons.info),
              label: const Text('Print Status ke Console'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Result Area
            const Text(
              'Hasil Test:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? 'Belum ada hasil test...' : _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'Berhasil ✅':
        return Colors.green;
      case 'Gagal ❌':
        return Colors.red;
      case 'Testing...':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing...';
      _result = 'Menguji koneksi ke Groq API...\n';
    });

    try {
      final startTime = DateTime.now();
      
      final success = await _groqService.testConnection();
      
      final duration = DateTime.now().difference(startTime);
      
      if (success) {
        setState(() {
          _status = 'Berhasil ✅';
          _result += '\n✅ Koneksi berhasil!\n';
          _result += '⚡ Waktu response: ${duration.inMilliseconds}ms\n';
          _result += '🚀 Groq API siap digunakan!\n';
        });
      } else {
        setState(() {
          _status = 'Gagal ❌';
          _result += '\n❌ Koneksi gagal!\n';
          _result += '💡 Cek API Key di groq_service.dart\n';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Gagal ❌';
        _result += '\n❌ Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testQuestionGeneration() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing generate pertanyaan interview...\n';
    });

    try {
      final startTime = DateTime.now();
      
      final question = await _groqService.generateNextInterviewQuestion(
        jobTarget: 'Flutter Developer',
        questionNumber: 1,
      );
      
      final duration = DateTime.now().difference(startTime);
      
      setState(() {
        _result += '\n✅ Berhasil generate pertanyaan!\n';
        _result += '⚡ Waktu: ${duration.inMilliseconds}ms\n';
        _result += '📝 Pertanyaan: "$question"\n';
      });
    } catch (e) {
      setState(() {
        _result += '\n❌ Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFeedback() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing generate feedback...\n';
    });

    try {
      final startTime = DateTime.now();
      
      final feedback = await _groqService.generateInterviewFeedback(
        question: 'Ceritakan tentang diri Anda',
        userAnswer: 'Saya adalah seorang developer yang suka belajar teknologi baru',
      );
      
      final duration = DateTime.now().difference(startTime);
      
      setState(() {
        _result += '\n✅ Berhasil generate feedback!\n';
        _result += '⚡ Waktu: ${duration.inMilliseconds}ms\n';
        _result += '💬 Feedback: "$feedback"\n';
      });
    } catch (e) {
      setState(() {
        _result += '\n❌ Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _printStatus() {
    print('\n' + '='*50);
    print('🧪 GROQ TEST - STATUS INFO');
    print('='*50);
    
    _groqService.printStatus();
    
    print('\n📊 Status Info Object:');
    final status = _groqService.statusInfo;
    status.forEach((key, value) {
      print('   $key: $value');
    });
    
    print('='*50 + '\n');
    
    setState(() {
      _result = 'Status telah di-print ke console.\nCek terminal/debug console untuk detail lengkap.';
    });
  }
}