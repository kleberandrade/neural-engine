// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'mlp_page.dart';
import 'model_demo_page.dart';
import 'sequence_page.dart';
import '../data/demo_kind.dart';

class ModelGallery extends StatelessWidget {
  const ModelGallery({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 5,
      child: Scaffold(
          appBar: AppBar(
              title: const Text('Neural Engine • Model Lab'),
              bottom: const TabBar(isScrollable: true, tabs: [
                Tab(text: 'MLP'),
                Tab(text: 'SOM'),
                Tab(text: 'CNN'),
                Tab(text: 'Autoencoder'),
                Tab(text: 'Sequences')
              ])),
          body: const TabBarView(children: [
            MlpPage(),
            ModelDemo(kind: DemoKind.som),
            ModelDemo(kind: DemoKind.cnn),
            ModelDemo(kind: DemoKind.autoencoder),
            SequencePage()
          ])));
}
