import 'package:test/test.dart';
// ignore: avoid_relative_lib_imports
import '../example/flutter_lab/lib/l10n/translations.dart';

void main() {
  test('Portuguese copy preserves API names and translates composed progress',
      () {
    expect(translate('Uma época percorre todo o conjunto de treino.', true),
        'Uma época percorre todo o conjunto de treino.');
    expect(translate('TrainingCheckpoint guarda o modelo no mapa.', true),
        'TrainingCheckpoint guarda o modelo no mapa.');
    expect(translate('Epoch 2 · loss 0.4 · validation 0.5', true),
        'Época 2 · perda 0.4 · validação 0.5');
    expect(translate('MLP · Learn the XOR rule', true),
        'MLP · Aprenda a regra XOR');
    expect(
        translate('REAL DATA / EVALUATION', true), 'DADOS REAIS / AVALIAÇÃO');
    expect(
        translate(
            'Objective: Compare two and eight hidden neurons with the same learning rate.',
            true),
        'Objetivo: Compare dois e oito neurônios ocultos com a mesma taxa de aprendizado.');
    expect(translate('Saved epoch: 40 · last run 100 ms', true),
        'Época salva: 40 · última execução 100 ms');
  });
}
