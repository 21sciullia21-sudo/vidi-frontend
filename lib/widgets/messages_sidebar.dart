import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/models/conversation_model.dart';
import 'package:vidi/models/user_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/services/message_service.dart';
import 'package:vidi/pages/messages_page.dart';
import 'package:intl/intl.dart';

class MessagesSidebar extends StatelessWidget {
  final VoidCallback onClose;
  
  const MessagesSidebar({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentUser = provider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth / 3;

    if (currentUser == null) {
      return Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(left: BorderSide(color: Color(0xFF2A2A2A))),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(-2, 0))],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Center(
                child: Text('Please sign in', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      );
    }

    final messageService = MessageService();

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(left: BorderSide(color: Color(0xFF2A2A2A))),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(-2, 0))],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FutureBuilder<List<ConversationModel>>(
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
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 12),
                        Text(
                          'Failed to load messages',
                          style: TextStyle(color: Colors.grey[400]),
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
                        Icon(Icons.forum_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Color(0xFF2A2A2A)),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final otherUserId = conversation.participantIds.firstWhere(
                      (id) => id != currentUser.id,
                      orElse: () => '',
                    );
                    final otherUser = provider.getUserById(otherUserId);

                    if (otherUser == null) return SizedBox.shrink();

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: _buildAvatar(otherUser),
                      title: Text(
                        otherUser.name,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        conversation.lastMessage ?? 'No messages',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      trailing: SizedBox(
                        width: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(conversation.lastMessageAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((conversation.unreadCount[currentUser.id] ?? 0) > 0)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(0xFF8B5CF6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conversation.unreadCount[currentUser.id]}',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      onTap: () {
                        onClose();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessagesPage(otherUserId: otherUserId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
    ),
    child: Row(
      children: [
        Icon(Icons.forum, color: Color(0xFF8B5CF6), size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Messages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: onClose,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );

  Widget _buildAvatar(UserModel user) {
    if (user.profilePicUrl.isNotEmpty) {
      if (user.profilePicUrl.startsWith('data:image')) {
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(
            Uri.parse(user.profilePicUrl).data!.contentAsBytes(),
          ),
        );
      } else {
        return CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(user.profilePicUrl),
        );
      }
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFF8B5CF6),
      child: Text(
        user.name[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
