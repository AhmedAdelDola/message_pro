import '../../core/network/api_client.dart';
import '../models/contact.dart';
import '../models/conversation.dart';

class ContactRepository {
  final ApiClient _api = ApiClient();

  Future<List<Contact>> searchContacts(String query, {int page = 1}) async {
    final response = await _api.get(
      'contacts/search',
      queryParameters: {'q': query, 'page': page},
    );
    final data = response.data;
    List list = [];
    if (data is Map && data['payload'] != null) {
      list = data['payload'];
    } else if (data is List) {
      list = data;
    }
    return list.map((c) => Contact.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Contact> getContact(int id) async {
    final response = await _api.get('contacts/$id');
    final data = response.data;
    final payload = data is Map && data['payload'] != null ? data['payload'] : data;
    return Contact.fromJson(payload as Map<String, dynamic>);
  }

  Future<List<Conversation>> getContactConversations(int contactId) async {
    final response = await _api.get('contacts/$contactId/conversations');
    final data = response.data;
    List list = [];
    if (data is Map && data['payload'] != null) {
      list = data['payload'];
    } else if (data is List) {
      list = data;
    }
    return list.map((c) => Conversation.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Contact> createContact({
    required String name,
    String? email,
    String? phoneNumber,
  }) async {
    final response = await _api.post(
      'contacts',
      data: {
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
      },
    );
    final data = response.data;
    final payload = data is Map && data['payload'] != null ? data['payload'] : data;
    return Contact.fromJson(payload as Map<String, dynamic>);
  }
}
