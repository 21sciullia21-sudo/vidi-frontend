import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vidi/models/message_model.dart';
import 'package:vidi/models/conversation_model.dart';
import 'package:vidi/models/user_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/services/message_service.dart';
import 'package:intl/intl.dart';

class MessagesPage extends StatefulWidget {
  final String otherUserId;

  const MessagesPage({Key? key, required this.otherUserId}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _messageService = MessageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = Uuid();
  
  ConversationModel? _conversation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  Future<void> _initConversation() async {
    final provider = context.read<AppProvider>();
    final currentUserId = provider.currentUser?.id;
    
    if (currentUserId == null) return;

    final conversation = await _messageService.getOrCreateConversation(
      currentUserId,
      widget.otherUserId,
    );

    setState(() {
      _conversation = conversation;
      _isLoading = false;
    });

    if (conversation != null) {
      _messageService.markMessagesAsRead(conversation.id, currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final otherUser = provider.getUserById(widget.otherUserId);
    final currentUser = provider.currentUser;

    if (currentUser == null || otherUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Messages')),
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildAvatar(otherUser),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    otherUser.skillLevel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: _conversation == null
                  ? Center(child: Text('Failed to load conversation'))
                  : StreamBuilder<List<MessageModel>>(
                      stream: _messageService.streamMessages(_conversation!.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == currentUser.id;
                            final showDate = index == 0 || 
                              !_isSameDay(messages[index - 1].sentAt, message.sentAt);

                            return Column(
                              children: [
                                if (showDate) _buildDateDivider(message.sentAt),
                                _buildMessage(message, isMe, otherUser),
                              ],
                            );
                          },
                        );
                      },
                    ),
              ),
              _buildInputArea(currentUser.id),
            ],
          ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String label;
    if (messageDate == today) {
      label = 'Today';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, y').format(date);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessage(MessageModel message, bool isMe, UserModel otherUser) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(otherUser),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Color(0xFF8B5CF6) : Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.sentAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    if (user.profilePicUrl.isNotEmpty) {
      if (user.profilePicUrl.startsWith('data:image')) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: MemoryImage(
            Uri.parse(user.profilePicUrl).data!.contentAsBytes(),
          ),
        );
      } else {
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(user.profilePicUrl),
        );
      }
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: Color(0xFF8B5CF6),
      child: Text(
        user.name[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInputArea(String currentUserId) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerTheme.color!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(currentUserId),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(currentUserId),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String currentUserId) async {
    if (_messageController.text.trim().isEmpty || _conversation == null) return;

    final message = MessageModel(
      id: _uuid.v4(),
      conversationId: _conversation!.id,
      senderId: currentUserId,
      content: _messageController.text.trim(),
      sentAt: DateTime.now(),
    );

    _messageController.clear();
    await _messageService.sendMessage(message);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
