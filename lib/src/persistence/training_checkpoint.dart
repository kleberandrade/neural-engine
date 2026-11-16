import 'dart:convert';
import '../contracts/json_model.dart';
import 'json_validation.dart';

/// Snapshot of a fixed-epoch training session. Dataset/loss remain caller-owned.
/// JSON getters return deep copies; no live weights/moments are shared.
class TrainingCheckpoint implements JsonModel {
  final Map<String, dynamic> _model, _optimizer, _state;
  final int epochsCompleted;
  final int seed;
  TrainingCheckpoint(
      {required Map<String, dynamic> model,
      required Map<String, dynamic> optimizer,
      required Map<String, dynamic> optimizerState,
      required this.epochsCompleted,
      required this.seed})
      : _model = _copy(model),
        _optimizer = _copy(optimizer),
        _state = _copy(optimizerState) {
    if (epochsCompleted < 0 || seed < 0 || seed > 0x7fffffff) {
      throw ArgumentError('Invalid checkpoint progress/seed.');
    }
  }
  Map<String, dynamic> get model => _copy(_model);
  Map<String, dynamic> get optimizer => _copy(_optimizer);
  Map<String, dynamic> get optimizerState => _copy(_state);
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_checkpoint',
        'version': 1,
        'epochsCompleted': epochsCompleted,
        'seed': seed,
        'model': model,
        'optimizer': optimizer,
        'optimizerState': optimizerState
      };
  factory TrainingCheckpoint.fromJson(Map<String, dynamic> json) {
    requireFormat(json, 'neural_engine_checkpoint');
    try {
      return TrainingCheckpoint(
          model: json['model'] as Map<String, dynamic>,
          optimizer: json['optimizer'] as Map<String, dynamic>,
          optimizerState: json['optimizerState'] as Map<String, dynamic>,
          epochsCompleted: json['epochsCompleted'] as int,
          seed: json['seed'] as int);
    } on Object catch (error) {
      throw FormatException('Invalid checkpoint: $error');
    }
  }
}

Map<String, dynamic> _copy(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
