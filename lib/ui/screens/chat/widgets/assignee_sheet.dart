import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../widgets/avatar_widget.dart';

class AssigneeSheet extends StatelessWidget {
  final List<User> agents;
  final User? currentAssignee;
  final Function(int? agentId) onSelect;

  const AssigneeSheet({
    super.key,
    required this.agents,
    this.currentAssignee,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'تعيين المسؤول (Assign Agent)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person_off_outlined, color: Colors.white, size: 20),
            ),
            title: const Text('إلغاء التعيين (Unassigned)'),
            selected: currentAssignee == null,
            trailing: currentAssignee == null ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              Navigator.pop(context);
              onSelect(null);
            },
          ),
          ...agents.map((agent) {
            final isSelected = currentAssignee?.id == agent.id;
            return ListTile(
              leading: AvatarWidget(
                avatarUrl: agent.avatarUrl,
                name: agent.name,
                size: 36,
                isOnline: agent.availabilityStatus == 'online',
                showStatus: true,
              ),
              title: Text(agent.name),
              subtitle: Text(agent.email, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                Navigator.pop(context);
                onSelect(agent.id);
              },
            );
          }),
        ],
      ),
    );
  }
}
