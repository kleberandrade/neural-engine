/// Presets map only to implemented laboratory recipes.
class LabExample {
  final String id, title, description, parameters;
  final int tab;
  final int? hiddenUnits;
  final String? dataset;
  const LabExample(
      this.id, this.title, this.description, this.parameters, this.tab,
      {this.hiddenUnits, this.dataset});
}

const labExamples = <LabExample>[
  LabExample(
      'xor',
      'Learn XOR',
      'Separate four examples with a nonlinear hidden layer.',
      '2 → 8 → 1 · Adam 0.03 · 800 epochs',
      0,
      hiddenUnits: 8),
  LabExample(
      'xor-small',
      'A smaller hidden layer',
      'Compare the capacity of two hidden neurons with the eight-neuron recipe.',
      '2 → 2 → 1 · Adam 0.03 · 800 epochs',
      0,
      hiddenUnits: 2),
  LabExample(
      'som',
      'Organize RGB colors',
      'Discover neighborhoods without assigning class labels.',
      '6×6 map · 80 epochs · radius 3 → 0.4',
      1),
  LabExample(
      'cnn',
      'Recognize noisy bars',
      'Train shared filters, inspect channels and draw a new pattern.',
      '6×6 images · 4 filters · 100 epochs',
      2),
  LabExample(
      'autoencoder',
      'Denoise a pattern',
      'Explore what a two-value bottleneck can preserve.',
      '8 → 6 → 2 → 6 → 8 · 400 epochs',
      3),
  LabExample(
      'sequences',
      'Compare recurrent memory',
      'Give RNN, LSTM and GRU the same sine-wave windows.',
      '6 timesteps · 6 hidden units · 180 epochs',
      4),
  LabExample(
      'checkpoint',
      'Replay an exact continuation',
      'Restore model and optimizer state, then compare with a reference.',
      '40 + 60 epochs · 5 model families',
      5),
  LabExample(
      'iris',
      'Classify Iris flowers',
      'Compare held-out accuracy and F1 against a majority baseline.',
      '4 → 8 → 3 · 120 epochs · reserved test set',
      7,
      dataset: 'Iris'),
  LabExample(
      'passengers',
      'Forecast airline demand',
      'Compare a one-step GRU forecast with two simple baselines.',
      '12 monthly lags · GRU 8 · 100 epochs',
      7,
      dataset: 'AirPassengers'),
];

LabExample exampleById(String id) =>
    labExamples.firstWhere((example) => example.id == id);
