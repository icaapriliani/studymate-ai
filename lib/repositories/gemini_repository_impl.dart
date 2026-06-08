import 'package:flutter/foundation.dart';
import '../domain/repositories/gemini_repository.dart';
import '../services/gemini_service.dart';

/// Implementation of the [GeminiRepository] following Clean Architecture.
/// It wraps the [GeminiService] and maps technical exceptions into
/// polite, user-friendly Indonesian error messages.
class GeminiRepositoryImpl implements GeminiRepository {
  final GeminiService _geminiService;

  GeminiRepositoryImpl({required GeminiService geminiService})
      : _geminiService = geminiService;

  @override
  Future<String> getAIResponse(String prompt) async {
    return _executeWithRetry(() => _geminiService.generateResponse(prompt));
  }

  @override
  Future<String> generateQuizQuestions(String materialTitle) async {
    final prompt = '''
Buatkan 5 soal pilihan ganda bahasa Indonesia tentang materi "$materialTitle".
Setiap soal harus memiliki 4 pilihan (options), satu jawaban benar (correctAnswer), dan penjelasan singkat (explanation).
Output WAJIB berupa JSON array valid persis seperti format berikut tanpa tambahan teks apapun di luar array JSON:

[
  {
    "question": "pertanyaan",
    "options": ["opsi 1", "opsi 2", "opsi 3", "opsi 4"],
    "correctAnswer": "opsi benar",
    "explanation": "penjelasan singkat"
  }
]
''';

    return _executeWithRetry(() => _geminiService.generateResponse(prompt));
  }

  /// Helper method to detect HTTP 503, UNAVAILABLE, or high demand errors.
  bool _is503Error(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('503') ||
        errorString.contains('unavailable') ||
        errorString.contains('high demand') ||
        errorString.contains('overloaded') ||
        errorString.contains('busy');
  }

  /// Private runner method to execute a Gemini API call with automatic 1-time retry for 503 errors.
  Future<String> _executeWithRetry(Future<String> Function() call) async {
    try {
      return await call();
    } catch (e, stackTrace) {
      if (_is503Error(e)) {
        // Log the initial 503 error for debugging
        debugPrint('[StudyMate AI Debug] Mendeteksi error 503/UNAVAILABLE/High Demand:');
        debugPrint('[StudyMate AI Debug] Error Asli: $e');
        debugPrint('[StudyMate AI Debug] Menunggu 2 detik sebelum melakukan retry...');
        
        await Future.delayed(const Duration(seconds: 2));
        
        try {
          debugPrint('[StudyMate AI Debug] Melakukan retry request ke Gemini...');
          return await call();
        } catch (retryError, retryStackTrace) {
          // Log the retry failure for debugging
          debugPrint('[StudyMate AI Debug] Retry gagal:');
          debugPrint('[StudyMate AI Debug] Error Asli Retry: $retryError');
          debugPrint('[StudyMate AI Debug] StackTrace Retry:\n$retryStackTrace');
          
          // Throw friendly message without technical details
          throw Exception('StudyMate AI sedang sibuk melayani banyak pengguna. Silakan coba lagi dalam beberapa detik.');
        }
      }

      // Log other errors for debugging
      debugPrint('[StudyMate AI Debug] Terjadi error pada repository impl saat memanggil service:');
      debugPrint('[StudyMate AI Debug] Error Asli: $e');
      debugPrint('[StudyMate AI Debug] StackTrace:\n$stackTrace');
      
      final friendlyMessage = _mapErrorToUserFriendlyMessage(e);
      throw Exception('$friendlyMessage (Detail Galat Asli: $e)');
    }
  }

  /// Maps low-level exceptions to descriptive Indonesian error messages.
  String _mapErrorToUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // 1. API Key or Configuration issues
    if (errorString.contains('api_key') || 
        errorString.contains('api key') || 
        errorString.contains('api-key') || 
        errorString.contains('api key not found') || 
        errorString.contains('invalid api key') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('credential') ||
        errorString.contains('invalid key') ||
        errorString.contains('api_key_invalid') ||
        errorString.contains('403') ||
        errorString.contains('400')) {
      return 'Konfigurasi layanan StudyMate AI gagal. Kunci API Gemini tidak valid atau belum disetel di berkas .env Anda.';
    }

    // 2. Internet / Network Connectivity issues
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('clientexception') ||
        errorString.contains('connection failed') ||
        errorString.contains('failed host lookup')) {
      return 'Koneksi internet bermasalah. Silakan periksa jaringan Anda dan coba beberapa saat lagi.';
    }

    // 3. Quota Exceeded / Rate Limiting (HTTP 429)
    if (errorString.contains('quota') ||
        errorString.contains('429') ||
        errorString.contains('rate limit') ||
        errorString.contains('resource exhausted')) {
      return 'Batas permintaan terlampaui. StudyMate AI sedang menerima terlalu banyak pertanyaan. Silakan tunggu beberapa saat sebelum mencoba kembali.';
    }

    // 4. Content Safety / Blocked Prompt Issues
    if (errorString.contains('safety') || 
        errorString.contains('blocked') || 
        errorString.contains('candidate') || 
        errorString.contains('finishreason.safety')) {
      return 'Pertanyaan Anda diblokir oleh kebijakan keamanan konten. Harap ubah kata-kata Anda menjadi pertanyaan yang sesuai untuk pembelajaran.';
    }

    // 5. 503 / Service Unavailable / High Demand
    if (errorString.contains('503') ||
        errorString.contains('unavailable') ||
        errorString.contains('high demand')) {
      return 'StudyMate AI sedang sibuk melayani banyak pengguna. Silakan coba lagi dalam beberapa detik.';
    }

    // 6. Argument error (e.g. empty prompt)
    if (errorString.contains('argumenterror') || errorString.contains('prompt tidak boleh kosong')) {
      return 'Pertanyaan tidak boleh kosong. Silakan ketik sesuatu untuk mulai belajar!';
    }

    // 7. Generic / Unexpected Exceptions
    return 'Maaf, terjadi kesalahan teknis saat menghubungi StudyMate AI. Silakan coba beberapa saat lagi.';
  }
}
