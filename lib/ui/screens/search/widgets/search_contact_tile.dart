import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:message_pro/data/models/contact.dart';
import 'package:message_pro/ui/widgets/avatar_widget.dart';

class SearchContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const SearchContactTile({
    super.key,
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AvatarWidget(
        avatarUrl: contact.avatarUrl,
        name: contact.name,
        size: 40.r,
      ),
      title: Text(contact.name),
      subtitle: Text(
        contact.email ?? contact.phoneNumber ?? '',
      ),
      onTap: onTap,
    );
  }
}
