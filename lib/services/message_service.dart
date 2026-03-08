import 'package:uuid/uuid.dart';
import 'package:vidi/models/message_model.dart';
import 'package:vidi/models/conversation_model.dart';
import 'package:vidi/supabase/supabase_config.dart';

class MessageService {
  final _uuid = Uuid();

  Future<ConversationModel?> getOrCreateConversation(String userId, String otherUserId) async {
    try {
      final participantIds = [userId, otherUserId]..sort();
      
      final existingData = await SupabaseConfig.client
        .from('conversations')
        .select()
        .contains('participant_ids', participantIds);

      if (existingData.isNotEmpty) {
        return ConversationModel.fromJson(existingData.first);
      }

      final newConversation = ConversationModel(
        id: _uuid.v4(),
        participantIds: participantIds,
        lastMessageAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await SupabaseConfig.client
        .from('conversations')
        .insert(newConversation.toJson());

      return newConversation;
    } catch (e) {
      print('Error getting/creating conversation: $e');
      return null;
    }
  }

  Future<List<ConversationModel>> getUserConversations(String userId) async {
    try {
      final data = await SupabaseConfig.client
        .from('conversations')
        .select()
        .contains('participant_ids', [userId])
        .order('last_message_at', ascending: false);

      return data.map((json) => ConversationModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  Future<List<MessageModel>> getConversationMessages(String conversationId) async {
    try {
      final data = await SupabaseConfig.client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: true);

      return data.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  Future<void> sendMessage(MessageModel message) async {
    try {
      await SupabaseConfig.client
        .from('messages')
        .insert(message.toJson());

      await SupabaseConfig.client
        .from('conversations')
        .update({
          'last_message': message.content,
          'last_message_at': message.sentAt.toIso8601String(),
        })
        .eq('id', message.conversationId);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      await SupabaseConfig.client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return SupabaseConfig.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('sent_at')
      .map((data) => data.map((json) => MessageModel.fromJson(json)).toList());
  }
}
