// Re-export AI Hub Screen as the new Statistics/Wasil screen
// This maintains backward compatibility with existing routes
export '../../ai_assistant/screens/ai_hub_screen.dart' show AIHubScreen;

import '../../ai_assistant/screens/ai_hub_screen.dart';

/// Statistics Screen is now the AI Hub (واصل)
/// This class is kept for backward compatibility with routes
class StatisticsScreen extends AIHubScreen {
  const StatisticsScreen({super.key});
}
