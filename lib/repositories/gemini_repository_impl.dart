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
    try {
      return await _geminiService.generateResponse(prompt);
    } catch (e, stackTrace) {
      // Proactively print the original error in console for debugging
      debugPrint('[StudyMate AI Debug] Terjadi error pada repository impl saat memanggil service:');
      debugPrint('[StudyMate AI Debug] Error Asli: $e');
      debugPrint('[StudyMate AI Debug] StackTrace:\n$stackTrace');
      
      // Complete user-friendly error handling in Indonesian, preserving original exception
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

    // 5. Argument error (e.g. empty prompt)
    if (errorString.contains('argumenterror') || errorString.contains('prompt tidak boleh kosong')) {
      return 'Pertanyaan tidak boleh kosong. Silakan ketik sesuatu untuk mulai belajar!';
    }

    // 6. Generic / Unexpected Exceptions
    return 'Maaf, terjadi kesalahan teknis saat menghubungi StudyMate AI. Silakan coba beberapa saat lagi.';
  }
}
