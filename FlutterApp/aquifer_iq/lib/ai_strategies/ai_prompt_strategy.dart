import '../services//ble_service.dart';

/// Abstract interface for AI prompt generation strategies.
/// Each mode (Home, Agricultural, Industrial, ...) implements this interface
/// with its own prompt, standards, and expected JSON schema.
///
/// To add a new mode, simply create a new class that implements
/// [AiPromptStrategy] and register it in [AiService._promptStrategies].
abstract class AiPromptStrategy {
  /// The display name for this strategy (e.g., "Home", "Agricultural")
  String get label;

  /// Build the full prompt string for the given sensor data.
  /// This includes sensor readings, scientific standards, JSON format,
  /// and output rules — all tailored to the specific mode.
  String buildPrompt({
    required double tds,
    required double purity,
    required double temperature,
    required double? ph,
  });

  /// Build the system message that sets the AI's role.
  String buildSystemMessage();

  /// Parse the AI's raw JSON response into structured detail points.
  /// Different modes may expect different numbers of detail points
  /// or different parsing logic.
  List<String> parseDetailPoints(dynamic rawDetails);

  /// Generate a default recommendation if the AI fails to provide one.
  String defaultRecommendation(bool isSafe);

  /// Generate a default summary based on the safety assessment.
  String defaultSummary(bool isSafe);
}
