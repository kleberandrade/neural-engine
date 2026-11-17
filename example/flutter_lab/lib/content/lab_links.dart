import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/lab_copy.dart';

const repositoryUrl = 'https://github.com/kleberandrade/neural-engine';
const coreVersion = '0.4.0';
const documentationPaths = [
  'README.md',
  'doc/models.md',
  'doc/models.pt-BR.md',
  'doc/recurrent.md',
  'doc/recurrent.pt-BR.md',
  'doc/evaluation.md',
  'doc/evaluation.pt-BR.md',
  'doc/async_training.md',
  'doc/async_training.pt-BR.md',
  'doc/persistence.md',
  'doc/persistence.pt-BR.md',
  'doc/real_world.md',
  'doc/real_world.pt-BR.md',
  'doc/architecture.md',
  'doc/lab_scenarios.md'
];
String documentationUrl(String path) => '$repositoryUrl/blob/main/$path';
Future<void> openLabLink(BuildContext context, String url) async {
  try {
    if (await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank')) return;
  } catch (_) {/* The UI reports a blocked or unsupported browser action. */}
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: LabText(
            'The link could not be opened. Please allow a new tab or copy the address: $url')));
  }
}
