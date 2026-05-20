/// Contract for the Gemini Repository following Clean Architecture.
/// Defines the domain boundary for interacting with StudyMate AI.
abstract class GeminiRepository {
  /// Fetches the AI-generated response for a given [prompt].
  ///
  /// Returns the generated text or throws a user-friendly exception.
  Future<String> getAIResponse(String prompt);
}
