import 'dart:io';

int? memoryBytes() => ProcessInfo.currentRss;
Map<String, Object?> runtimeInfo() => {
      'runtime': Platform.version,
      'os': Platform.operatingSystem,
      'processors': Platform.numberOfProcessors,
      'memoryMetric': 'process RSS (all isolates)'
    };
