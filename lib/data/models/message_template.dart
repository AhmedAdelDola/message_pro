class TemplateButton {
  final String text;
  final String type; // 'QUICK_REPLY', 'URL', 'PHONE_NUMBER'
  final String? url;
  final String? phoneNumber;

  const TemplateButton({
    required this.text,
    this.type = 'QUICK_REPLY',
    this.url,
    this.phoneNumber,
  });

  bool get isUrl => type.toUpperCase() == 'URL';
  bool get isQuickReply => type.toUpperCase() == 'QUICK_REPLY';
  bool get isPhoneNumber => type.toUpperCase() == 'PHONE_NUMBER';

  factory TemplateButton.from(dynamic item) {
    if (item is TemplateButton) return item;
    if (item is String) return TemplateButton(text: item);
    if (item is Map) {
      final reply = item['reply'];
      final button = item['button'];
      final nestedTitle = (reply is Map ? reply['title'] ?? reply['text'] : null) ??
          (button is Map ? button['title'] ?? button['text'] : null);
      final text = item['text']?.toString() ??
          item['title']?.toString() ??
          nestedTitle?.toString() ??
          item['value']?.toString() ??
          '';
      var type = item['type']?.toString().toUpperCase() ??
          (item['url'] != null ? 'URL' : 'QUICK_REPLY');
      if (type == 'REPLY') type = 'QUICK_REPLY';
      return TemplateButton(
        text: text,
        type: type,
        url: item['url']?.toString(),
        phoneNumber: item['phone_number']?.toString(),
      );
    }
    return const TemplateButton(text: '');
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'type': type,
    if (url != null) 'url': url,
    if (phoneNumber != null) 'phone_number': phoneNumber,
  };
}

class MessageTemplate {
  final int? id;
  final String? remoteId;
  final String name;
  final String category;
  final String language;
  final String status;
  final String? header;
  final String body;
  final String? footer;
  final List<TemplateButton> buttons;
  final List<String> labels;
  final Map<String, dynamic> rawJson;

  MessageTemplate({
    this.id,
    this.remoteId,
    required this.name,
    required this.category,
    required this.language,
    this.status = 'APPROVED',
    this.header,
    required this.body,
    this.footer,
    dynamic buttons = const <TemplateButton>[],
    this.labels = const [],
    this.rawJson = const {},
  }) : buttons = (buttons is List)
            ? buttons.map((b) => TemplateButton.from(b)).toList()
            : const [];

  List<String> get buttonTexts => buttons.map((b) => b.text).toList();

  String get categoryDisplay {
    final lower = category.toLowerCase();
    if (lower == 'marketing') return 'Marketing';
    if (lower == 'utility') return 'Utility';
    if (lower == 'authentication') return 'Authentication';
    return category;
  }

  String get languageDisplay {
    final lower = language.toLowerCase();
    if (lower == 'ar' || lower.startsWith('ar_') || lower.startsWith('ar-')) return 'Arabic';
    if (lower == 'en' || lower.startsWith('en_') || lower.startsWith('en-')) return 'English';
    return language;
  }

  String get fullText {
    final parts = <String>[];
    if (header != null && header!.trim().isNotEmpty) {
      parts.add(header!.trim());
    }
    if (body.trim().isNotEmpty) {
      parts.add(body.trim());
    }
    if (footer != null && footer!.trim().isNotEmpty) {
      parts.add(footer!.trim());
    }
    return parts.join('\n\n');
  }

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '');
    final remoteId = json['remote_id']?.toString();
    final name = json['name']?.toString() ?? '';
    final category = json['category']?.toString() ?? 'MARKETING';
    final language = json['language']?.toString() ?? 'ar_EG';
    final status = json['status']?.toString() ?? 'APPROVED';

    String? header;
    String body = '';
    String? footer;
    final buttonsList = <TemplateButton>[];

    final components = json['components'] ?? json['meta_payload']?['components'];
    if (components is List) {
      for (final c in components) {
        if (c is Map) {
          final type = c['type']?.toString().toUpperCase();
          if (type == 'HEADER' && c['text'] != null) {
            header = c['text'].toString();
          } else if (type == 'BODY' && c['text'] != null) {
            body = c['text'].toString();
          } else if (type == 'FOOTER' && c['text'] != null) {
            footer = c['text'].toString();
          } else if (type == 'BUTTONS' && c['buttons'] is List) {
            for (final b in c['buttons']) {
              final tb = TemplateButton.from(b);
              if (tb.text.isNotEmpty) {
                buttonsList.add(tb);
              }
            }
          }
        }
      }
    }

    if (body.isEmpty && json['body'] != null) {
      body = json['body'].toString();
    } else if (body.isEmpty && json['text'] != null) {
      body = json['text'].toString();
    }

    final rawLabels = json['labels'];
    final labelsList = <String>[];
    if (rawLabels is List) {
      for (final l in rawLabels) {
        if (l != null) labelsList.add(l.toString());
      }
    }

    return MessageTemplate(
      id: id,
      remoteId: remoteId,
      name: name,
      category: category,
      language: language,
      status: status,
      header: header,
      body: body,
      footer: footer,
      buttons: buttonsList,
      labels: labelsList,
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'name': name,
    'category': category,
    'language': language,
    'status': status,
    'header': header,
    'body': body,
    'footer': footer,
    'buttons': buttons.map((b) => b.toJson()).toList(),
    'labels': labels,
  };
}
