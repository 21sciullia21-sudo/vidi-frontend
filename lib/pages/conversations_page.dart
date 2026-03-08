import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/models/conversation_model.dart';
import 'package:vidi/models/user_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/services/message_service.dart';
import 'package:vidi/pages/messages_page.dart';
import 'package:intl/intl.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentUser = provider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Messages')),
        body: Center(child: Text('Please sign in')),
      );
    }

    final messageService = MessageService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
      ),
      body: FutureBuilder<List<ConversationModel>>(
        future: messageService.getUserConversations(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load messages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start chatting with freelancers!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId = conversation.participantIds.firstWhere(
                (id) => id != currentUser.id,
                orElse: () => '',
              );
              final otherUser = provider.getUserById(otherUserId);

              if (otherUser == null) {
                return SizedBox.shrink();
              }

              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _buildAvatar(otherUser),
                title: Text(
                  otherUser.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  conversation.lastMessage ?? 'No messages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(conversation.lastMessageAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if ((conversation.unreadCount[currentUser.id] ?? 0) > 0)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${conversation.unreadCount[currentUser.id]}',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessagesPage(otherUserId: otherUserId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    if (user.profilePicUrl.isNotEmpty) {
      if (user.profilePicUrl.startsWith('data:image')) {
        return CircleAvatar(
          radius: 24,
          backgroundImage: MemoryImage(
            Uri.parse(user.profilePicUrl).data!.contentAsBytes(),
          ),
        );
      } else {
        return CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(user.profilePicUrl),
        );
      }
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Color(0xFF8B5CF6),
      child: Text(
        user.name[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
