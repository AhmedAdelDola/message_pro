class WorkflowInput {
  final String name;
  final String label;
  final String type;
  final bool required;
  final List<String> options;

  const WorkflowInput({
    required this.name,
    required this.label,
    this.type = 'text',
    this.required = false,
    this.options = const [],
  });

  factory WorkflowInput.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final opts = <String>[];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt != null) opts.add(opt.toString());
      }
    }
    return WorkflowInput(
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      required: json['required'] == true,
      options: opts,
    );
  }
}

class WorkflowShortcut {
  final int id;
  final String name;
  final String? icon;
  final String? description;
  final List<WorkflowInput> inputs;

  const WorkflowShortcut({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    this.inputs = const [],
  });

  factory WorkflowShortcut.fromJson(Map<String, dynamic> json) {
    final rawInputs = json['inputs'];
    final parsedInputs = <WorkflowInput>[];
    if (rawInputs is List) {
      for (final item in rawInputs) {
        if (item is Map) {
          parsedInputs.add(
            WorkflowInput.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final rawDesc = json['description']?.toString().trim();
    return WorkflowShortcut(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      description: (rawDesc != null && rawDesc.isNotEmpty) ? rawDesc : null,
      inputs: parsedInputs,
    );
  }
}

class WorkflowRun {
  final int id;
  final String name;
  final bool canStop;

  const WorkflowRun({
    required this.id,
    required this.name,
    this.canStop = true,
  });

  factory WorkflowRun.fromJson(Map<String, dynamic> json) {
    return WorkflowRun(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      canStop: json['can_stop'] != false,
    );
  }
}
