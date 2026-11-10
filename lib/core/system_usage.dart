import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ollama_client.dart';
import 'providers.dart';

/// Snapshot of real-time system resource consumption.
class SystemUsage {
  const SystemUsage({
    required this.cpuPercent,
    required this.ramUsedGb,
    required this.ramTotalGb,
    required this.ramPercent,
    this.gpuPercent,
    required this.vramUsedGb,
    this.vramTotalGb,
    this.vramPercent,
    this.gpuName,
    this.loadedModels = const [],
  });

  final double cpuPercent; // 0.0 - 100.0
  final double ramUsedGb;
  final double ramTotalGb;
  final double ramPercent; // 0.0 - 100.0
  final double? gpuPercent; // 0.0 - 100.0
  final double vramUsedGb;
  final double? vramTotalGb;
  final double? vramPercent;
  final String? gpuName;
  final List<String> loadedModels;

  const SystemUsage.initial()
      : cpuPercent = 0.0,
        ramUsedGb = 0.0,
        ramTotalGb = 0.0,
        ramPercent = 0.0,
        gpuPercent = null,
        vramUsedGb = 0.0,
        vramTotalGb = null,
        vramPercent = null,
        gpuName = null,
        loadedModels = const [];
}

/// Service that queries CPU, RAM, GPU, and VRAM utilization across Linux and desktop targets.
class SystemUsageService {
  int? _prevIdleTime;
  int? _prevTotalTime;
  String? _detectedGpuType; // 'nvidia', 'intel', 'amd', or 'none'
  String? _intelActFreqPath;
  String? _intelMaxFreqPath;
  String? _amdBusyPath;

  SystemUsageService() {
    _initGpuDetection();
  }

  void _initGpuDetection() {
    if (!Platform.isLinux) return;

    // Check Intel i915 / Xe sysfs
    for (final card in ['card1', 'card0']) {
      final act = File('/sys/class/drm/$card/gt_act_freq_mhz');
      final max = File('/sys/class/drm/$card/gt_max_freq_mhz');
      if (act.existsSync() && max.existsSync()) {
        _detectedGpuType = 'intel';
        _intelActFreqPath = act.path;
        _intelMaxFreqPath = max.path;
        break;
      }
    }

    // Check AMD sysfs
    if (_detectedGpuType == null) {
      for (final card in ['card1', 'card0']) {
        final busy = File('/sys/class/drm/$card/device/gpu_busy_percent');
        if (busy.existsSync()) {
          _detectedGpuType = 'amd';
          _amdBusyPath = busy.path;
          break;
        }
      }
    }
  }

  /// Collects a single snapshot of system metrics.
  Future<SystemUsage> collect(OllamaClient ollamaClient) async {
    double cpuPct = 0.0;
    double ramUsedGb = 0.0;
    double ramTotalGb = 0.0;
    double ramPct = 0.0;
    double? gpuPct;
    double vramUsedGb = 0.0;
    double? vramTotalGb;
    double? vramPct;
    String? gpuName;
    List<String> loadedModels = [];

    // 1. CPU Usage via /proc/stat
    try {
      if (Platform.isLinux) {
        final statFile = File('/proc/stat');
        if (statFile.existsSync()) {
          final content = await statFile.readAsString();
          final cpuLine = content.split('\n').firstWhere((l) => l.startsWith('cpu '));
          final parts = cpuLine.trim().split(RegExp(r'\s+')).sublist(1).map(int.parse).toList();
          if (parts.length >= 7) {
            final idle = parts[3] + parts[4]; // idle + iowait
            final total = parts.reduce((a, b) => a + b);

            if (_prevIdleTime != null && _prevTotalTime != null) {
              final deltaTotal = total - _prevTotalTime!;
              final deltaIdle = idle - _prevIdleTime!;
              if (deltaTotal > 0) {
                cpuPct = ((deltaTotal - deltaIdle) / deltaTotal) * 100.0;
                cpuPct = cpuPct.clamp(0.0, 100.0);
              }
            }
            _prevIdleTime = idle;
            _prevTotalTime = total;
          }
        }
      }
    } catch (_) {}

    // 2. RAM Usage via /proc/meminfo
    try {
      if (Platform.isLinux) {
        final memFile = File('/proc/meminfo');
        if (memFile.existsSync()) {
          final lines = await memFile.readAsLines();
          int? memTotalKb;
          int? memAvailKb;
          for (final line in lines) {
            if (line.startsWith('MemTotal:')) {
              memTotalKb = int.tryParse(line.replaceAll(RegExp(r'[^0-9]'), ''));
            } else if (line.startsWith('MemAvailable:')) {
              memAvailKb = int.tryParse(line.replaceAll(RegExp(r'[^0-9]'), ''));
            }
          }
          if (memTotalKb != null && memAvailKb != null && memTotalKb > 0) {
            final usedKb = memTotalKb - memAvailKb;
            ramUsedGb = usedKb / (1024 * 1024);
            ramTotalGb = memTotalKb / (1024 * 1024);
            ramPct = (usedKb / memTotalKb) * 100.0;
          }
        }
      }
    } catch (_) {}

    // 3. GPU Metrics (NVIDIA / Intel / AMD)
    try {
      // First try nvidia-smi if available
      final nvsmiResult = await Process.run('nvidia-smi', [
        '--query-gpu=name,utilization.gpu,memory.used,memory.total',
        '--format=csv,noheader,nounits',
      ]).timeout(const Duration(milliseconds: 500), onTimeout: () => ProcessResult(0, -1, '', ''));

      if (nvsmiResult.exitCode == 0 && (nvsmiResult.stdout as String).trim().isNotEmpty) {
        final line = (nvsmiResult.stdout as String).trim().split('\n').first;
        final parts = line.split(',').map((s) => s.trim()).toList();
        if (parts.length >= 4) {
          gpuName = parts[0];
          gpuPct = double.tryParse(parts[1]);
          final usedMb = double.tryParse(parts[2]) ?? 0;
          final totalMb = double.tryParse(parts[3]) ?? 1;
          vramUsedGb = usedMb / 1024.0;
          vramTotalGb = totalMb / 1024.0;
          vramPct = (usedMb / totalMb) * 100.0;
        }
      } else {
        // Fallback to Intel or AMD sysfs
        if (_detectedGpuType == 'intel' && _intelActFreqPath != null && _intelMaxFreqPath != null) {
          final actStr = (await File(_intelActFreqPath!).readAsString()).trim();
          final maxStr = (await File(_intelMaxFreqPath!).readAsString()).trim();
          final act = double.tryParse(actStr) ?? 0;
          final max = double.tryParse(maxStr) ?? 1;
          if (max > 0) {
            gpuPct = (act / max) * 100.0;
            gpuName = 'Intel Graphics';
          }
        } else if (_detectedGpuType == 'amd' && _amdBusyPath != null) {
          final busyStr = (await File(_amdBusyPath!).readAsString()).trim();
          gpuPct = double.tryParse(busyStr);
          gpuName = 'AMD Radeon';
        }
      }
    } catch (_) {}

    // 4. VRAM from Ollama Running Models (/api/ps)
    try {
      final running = await ollamaClient.listRunning();
      if (running.isNotEmpty) {
        loadedModels = running.map((m) => m.name).toList();
        int totalOllamaVram = 0;
        for (final m in running) {
          totalOllamaVram += m.vramSize;
        }
        final ollamaVramGb = totalOllamaVram / 1e9;
        // If discrete GPU VRAM was not reported, report Ollama VRAM allocation directly
        if (vramUsedGb == 0.0 && ollamaVramGb > 0) {
          vramUsedGb = ollamaVramGb;
        }
      }
    } catch (_) {}

    return SystemUsage(
      cpuPercent: cpuPct,
      ramUsedGb: ramUsedGb,
      ramTotalGb: ramTotalGb,
      ramPercent: ramPct,
      gpuPercent: gpuPct,
      vramUsedGb: vramUsedGb,
      vramTotalGb: vramTotalGb,
      vramPercent: vramPct,
      gpuName: gpuName,
      loadedModels: loadedModels,
    );
  }

  /// Streams periodic system usage snapshots.
  Stream<SystemUsage> watchUsage(
    OllamaClient ollamaClient, {
    Duration interval = const Duration(seconds: 2),
  }) async* {
    // Initial collection to prime CPU delta
    yield await collect(ollamaClient);

    while (true) {
      await Future<void>.delayed(interval);
      yield await collect(ollamaClient);
    }
  }
}

/// Global stream provider for system resource metrics.
final systemUsageStreamProvider = StreamProvider<SystemUsage>((ref) {
  final service = SystemUsageService();
  final client = ref.watch(ollamaClientProvider);
  return service.watchUsage(client);
});
