import 'package:flutter_test/flutter_test.dart';
import 'package:message_pro/data/models/user.dart';

void main() {
  group('Organization parsing & grouping', () {
    test('Account parses organizationName from map', () {
      final acc = Account.fromJson({
        'id': 1,
        'name': 'Customer Care',
        'role': 'administrator',
        'organization': {'id': 10, 'name': 'Acme Corp'},
      });

      expect(acc.organizationName, 'Acme Corp');
      expect(acc.organizationId, 10);
      expect(acc.getEffectiveOrgName('Fallback'), 'Acme Corp');
    });

    test('Account extracts organization from name delimiter if missing', () {
      final acc = Account.fromJson({
        'id': 2,
        'name': 'Message Pro - Support Team',
        'role': 'agent',
      });

      expect(acc.organizationName, null);
      expect(acc.getEffectiveOrgName('Fallback'), 'Message Pro');
      expect(acc.getDisplayNameInOrg('Message Pro'), 'Support Team');
    });

    test('User.fromJson populates account organization from root list', () {
      final user = User.fromJson({
        'id': 100,
        'name': 'Test User',
        'email': 'user@example.com',
        'account_id': 15,
        'organizations': [
          {
            'id': 10,
            'name': 'Alpha Enterprise',
            'accounts': [15, 16],
          }
        ],
        'accounts': [
          {'id': 15, 'name': 'Sales', 'role': 'agent'},
          {'id': 16, 'name': 'Support', 'role': 'agent'},
          {'id': 20, 'name': 'Beta - Dev', 'role': 'administrator'},
        ],
      });

      expect(user.accounts[0].organizationName, 'Alpha Enterprise');
      expect(user.accounts[1].organizationName, 'Alpha Enterprise');
      expect(user.accounts[2].getEffectiveOrgName('Fallback'), 'Beta');
    });
  });
}
