/// Data models for the Ollama API responses.
/// These are plain Dart classes — no code generation required.
library;

// ---------------------------------------------------------------------------
// OllamaModel
// ---------------------------------------------------------------------------

class OllamaModel {
  const OllamaModel({
    required this.name,
    required this.model,
    required this.size,
    required this.digest,
    required this.details,
    required this.modifiedAt,
  });

  final String name;
  final String model;
  final int size;
  final String digest;
  final ModelDetails details;
  final DateTime modifiedAt;

  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    return OllamaModel(
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? json['name'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      digest: json['digest'] as String? ?? '',
      details: json['details'] != null
          ? ModelDetails.fromJson(json['details'] as Map<String, dynamic>)
          : const ModelDetails.empty(),
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : DateTime.now(),
    );
  }

  /// Size in gigabytes, formatted to 2 decimal places.
  String get sizeGb => '${(size / 1e9).toStringAsFixed(2)} GB';
}

// ---------------------------------------------------------------------------
// ModelDetails
// ---------------------------------------------------------------------------

class ModelDetails {
  const ModelDetails({
    required this.format,
    required this.family,
    required this.parameterSize,
    required this.quantizationLevel,
    this.families,
  });

  const ModelDetails.empty()
      : format = '',
        family = '',
        parameterSize = '',
        quantizationLevel = '',
        families = null;

  final String format;
  final String family;
  final String parameterSize;
  final String quantizationLevel;
  final List<String>? families;

  factory ModelDetails.fromJson(Map<String, dynamic> json) {
    return ModelDetails(
      format: json['format'] as String? ?? '',
      family: json['family'] as String? ?? '',
      parameterSize: json['parameter_size'] as String? ?? '',
      quantizationLevel: json['quantization_level'] as String? ?? '',
      families: (json['families'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// ChatMessage
// ---------------------------------------------------------------------------

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.createdAt,
    this.images,
  });

  final String role;
  final String content;
  final DateTime? createdAt;
  final List<String>? images;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'role': role,
      'content': content,
    };
    if (images != null && images!.isNotEmpty) {
      map['images'] = images;
    }
    return map;
  }

  ChatMessage copyWith({String? role, String? content, DateTime? createdAt}) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      images: images,
    );
  }
}

// ---------------------------------------------------------------------------
// ModelInfo
// ---------------------------------------------------------------------------

class ModelInfo {
  const ModelInfo({
    required this.modelfile,
    required this.parameters,
    required this.template,
    required this.details,
    this.license,
    this.system,
  });

  final String modelfile;
  final String parameters;
  final String template;
  final OllamaModel details;
  final String? license;
  final String? system;

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      modelfile: json['modelfile'] as String? ?? '',
      parameters: json['parameters'] as String? ?? '',
      template: json['template'] as String? ?? '',
      details: json['details'] != null
          ? OllamaModel.fromJson({
              'name': json['model'] ?? '',
              ...json['details'] as Map<String, dynamic>,
            })
          : OllamaModel(
              name: '',
              model: '',
              size: 0,
              digest: '',
              details: const ModelDetails.empty(),
              modifiedAt: DateTime.now(),
            ),
      license: json['license'] as String?,
      system: json['system'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// RunningModel
// ---------------------------------------------------------------------------

class RunningModel {
  const RunningModel({
    required this.name,
    required this.model,
    required this.size,
    required this.vramSize,
    required this.expiresAt,
    required this.details,
  });

  final String name;
  final String model;
  final int size;
  final int vramSize;
  final DateTime expiresAt;
  final ModelDetails details;

  factory RunningModel.fromJson(Map<String, dynamic> json) {
    return RunningModel(
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      vramSize: (json['size_vram'] as num?)?.toInt() ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      details: json['details'] != null
          ? ModelDetails.fromJson(json['details'] as Map<String, dynamic>)
          : const ModelDetails.empty(),
    );
  }

  String get vramSizeGb => '${(vramSize / 1e9).toStringAsFixed(2)} GB';
}

// ---------------------------------------------------------------------------
// PullProgress
// ---------------------------------------------------------------------------

class PullProgress {
  const PullProgress({
    required this.status,
    this.completed,
    this.total,
    this.digest,
  });

  final String status;
  final int? completed;
  final int? total;
  final String? digest;

  factory PullProgress.fromJson(Map<String, dynamic> json) {
    return PullProgress(
      status: json['status'] as String? ?? '',
      completed: (json['completed'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      digest: json['digest'] as String?,
    );
  }

  double? get progress {
    if (total != null && total! > 0 && completed != null) {
      return completed! / total!;
    }
    return null;
  }

  bool get isDone => status == 'success';
}
