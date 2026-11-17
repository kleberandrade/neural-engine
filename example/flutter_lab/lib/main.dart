import 'package:material_ui/material_ui.dart';
import 'app.dart';
import 'package:shared_preferences/shared_preferences.dart';
export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } catch (_) {/* Session-only locale when storage is blocked. */}
  runApp(NeuralLab(preferences: preferences));
}
