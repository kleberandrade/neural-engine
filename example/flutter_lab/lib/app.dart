// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'pages/model_gallery.dart';

class NeuralLab extends StatelessWidget {
  const NeuralLab({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Neural Engine Lab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.cyan,
            useMaterial3: true),
        home: const ModelGallery(),
      );
}
