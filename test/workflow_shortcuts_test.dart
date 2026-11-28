import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/workflow.dart';

void main() {
  group('Workflow models', () {
    test('WorkflowShortcut.fromJson parses shortcut with description and inputs', () {
      final shortcut = WorkflowShortcut.fromJson({
        'id': 309,
        'name': 'تحويل للسيلز',
        'icon': null,
        'description': 'توزيع المحادثة بالتساوي على فريق السيلز',
        'inputs': [
          {
            'name': 'team',
            'label': 'Team',
            'type': 'select',
            'required': true,
            'options': ['Sales', 'Support'],
          },
        ],
      });

      expect(shortcut.id, 309);
      expect(shortcut.name, 'تحويل للسيلز');
      expect(shortcut.description, 'توزيع المحادثة بالتساوي على فريق السيلز');
      expect(shortcut.inputs.length, 1);
      expect(shortcut.inputs.first.type, 'select');
      expect(shortcut.inputs.first.required, isTrue);
      expect(shortcut.inputs.first.options, ['Sales', 'Support']);
    });

    test('WorkflowRun.fromJson parses active run', () {
      final run = WorkflowRun.fromJson({
        'id': 42,
        'name': 'متابعة 1',
        'can_stop': true,
      });

      expect(run.id, 42);
      expect(run.name, 'متابعة 1');
      expect(run.canStop, isTrue);
    });
  });
}
