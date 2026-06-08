import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service class for interacting with the Gemini 1.5 Flash model.
/// It retrieves the API key securely using [flutter_dotenv].
class GeminiService {
  final GenerativeModel? _customModel;

  GeminiService({GenerativeModel? model}) : _customModel = model;

  /// Private getter to initialize and get the GenerativeModel.
  GenerativeModel get _model {
    final customModel = _customModel;
    if (customModel != null) {
      debugPrint('[StudyMate AI Service] Menggunakan custom model yang disuntikkan.');
      return customModel;
    }

    // Logging pemuatan dotenv
    final dotenvKeys = dotenv.env.keys.toList(); 
    debugPrint('[StudyMate AI Service] Memeriksa status load dotenv. Variabel yang dimuat: $dotenvKeys');

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    
    // Log pembacaan API Key secara aman
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[StudyMate AI Service] ERROR: GEMINI_API_KEY tidak ditemukan atau kosong di file .env!');
      throw Exception('GEMINI_API_KEY tidak ditemukan dalam file .env');
    } else {
      final maskedKey = apiKey.length > 10 
          ? '${apiKey.substring(0, 6)}...${apiKey.substring(apiKey.length - 4)}'
          : '***';
      debugPrint('[StudyMate AI Service] Berhasil membaca GEMINI_API_KEY dari .env (Masked: $maskedKey, Panjang: ${apiKey.length})');
    }

    // Memverifikasi apakah model gemini-2.5-flash benar digunakan
    debugPrint('[StudyMate AI Service] Menginisialisasi GenerativeModel dengan nama model: gemini-2.5-flash');
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'Anda adalah StudyMate AI, asisten belajar AI yang ramah, interaktif, dan cerdas. '
        'Jawablah selalu dalam Bahasa Indonesia dengan gaya bahasa yang mudah dipahami, '
        'mendukung, dan edukatif untuk membantu siswa belajar secara efektif.'
      ),
    );
  }

  /// Generates a response from the Gemini 1.5 Flash model for a given [prompt].
  /// Throws an [ArgumentError] if the prompt is empty.
  Future<String> generateResponse(String prompt) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      throw ArgumentError('Prompt tidak boleh kosong');
    }

    try {
      final modelInstance = _model;
      debugPrint('[StudyMate AI Service] Mengirim prompt ke Gemini AI: "$trimmedPrompt"');
      
      // Memanggil generateContent() dari package google_generative_ai
      final response = await modelInstance.generateContent([
        Content.text(trimmedPrompt),
      ]);

      final text = response.text;
      debugPrint('[StudyMate AI Service] Menerima respons dari Gemini AI.');
      debugPrint('[StudyMate AI Service] Status response.text null: ${text == null}');
      debugPrint('[StudyMate AI Service] Status response.text empty: ${text?.isEmpty ?? true}');
      debugPrint('[StudyMate AI Service] Isi teks respons: "$text"');
      
      if (text == null || text.isEmpty) {
        debugPrint('[StudyMate AI Service] ERROR: Respons dari Gemini AI bernilai null atau kosong!');
        throw Exception('Menerima respons kosong dari AI.');
      }

      return text;
    } catch (e, stackTrace) {
      debugPrint('[StudyMate AI Service] EXCEPTION ASLI TERDETEKSI di generateContent(): $e');
      debugPrint('[StudyMate AI Service] StackTrace:\n$stackTrace');
      rethrow;
    }
  }
}
