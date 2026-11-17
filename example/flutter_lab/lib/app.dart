import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/lab_copy.dart';
import 'pages/model_gallery.dart';
import 'widgets/lab_design.dart';

class NeuralLab extends StatefulWidget {
  final SharedPreferences? preferences;
  const NeuralLab({super.key, this.preferences});
  @override
  State<NeuralLab> createState() => _NeuralLabState();
}

class _NeuralLabState extends State<NeuralLab> {
  late LabLanguage _language;
  @override
  void initState() {
    super.initState();
    _language = widget.preferences?.getString('neural-lab-language') == 'pt-BR'
        ? LabLanguage.portuguese
        : LabLanguage.english;
  }

  void _changeLanguage(LabLanguage value) {
    if (_language == value) return;
    setState(() => _language = value);
    widget.preferences
        ?.setString('neural-lab-language',
            value == LabLanguage.portuguese ? 'pt-BR' : 'en')
        .catchError((Object _) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(seedColor: labAccent, brightness: Brightness.dark)
            .copyWith(
      primary: labAccent,
      secondary: labViolet,
      surface: labSurface,
      onSurface: const Color(0xFFEAF0F9),
      outline: labBorder,
    );
    return LabCopyScope(
        language: _language,
        onChanged: _changeLanguage,
        child: MaterialApp(
          locale: _language == LabLanguage.portuguese
              ? const Locale('pt', 'BR')
              : const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          title: 'Neural Engine Lab',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: labBackground,
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.1,
                  height: 1.15),
              headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.7),
              headlineSmall: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.5),
              titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              bodyMedium: TextStyle(fontSize: 14, height: 1.5),
              bodySmall: TextStyle(fontSize: 12, height: 1.5, color: labMuted),
            ),
            filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700))),
            outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    side: const BorderSide(color: labBorder),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)))),
            inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: labBackground.withValues(alpha: .55),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: labBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: labBorder))),
            dataTableTheme: const DataTableThemeData(
                headingTextStyle: TextStyle(
                    color: labMuted, fontWeight: FontWeight.w600, fontSize: 12),
                dataTextStyle:
                    TextStyle(fontSize: 13, color: Color(0xFFEAF0F9)),
                horizontalMargin: 12,
                columnSpacing: 24),
            dividerTheme: const DividerThemeData(color: labBorder, space: 1),
            sliderTheme: const SliderThemeData(trackHeight: 3),
          ),
          home: Semantics(
              localeForSubtree: _language == LabLanguage.portuguese
                  ? const Locale('pt', 'BR')
                  : const Locale('en'),
              child: const ModelGallery()),
        ));
  }
}
