import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vidi/models/user_model.dart';
import 'package:vidi/pages/followers_page.dart';
import 'package:vidi/pages/projects_page.dart';
import 'package:vidi/pages/messages_page.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;

  const ProfileHeader({Key? key, required this.user}) : super(key: key);

  ImageProvider? _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) return null;
    
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        return null;
      }
    } else if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color!,
          ),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF8B5CF6),
            backgroundImage: _getImageProvider(user.profilePicUrl),
            child: user.profilePicUrl.isEmpty
                ? Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (user.isNew) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'New',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 6),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatButton(
                label: 'Followers',
                value: '${user.followers}',
                onTap: () => _navigateToFollowers(context, user.id),
              ),
              SizedBox(width: 40),
              _StatButton(
                label: 'Following',
                value: '${user.following}',
                onTap: () => _navigateToFollowing(context, user.id),
              ),
              SizedBox(width: 40),
              _StatButton(
                label: 'Projects',
                value: '${user.projectCount}',
                onTap: () => _navigateToProjects(context, user.id),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFFFA500).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFFFFA500),
                width: 1.5,
              ),
            ),
            child: Text(
              user.skillLevel,
              style: TextStyle(
                color: Color(0xFFFFA500),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFollowers(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersPage(userId: userId, title: 'Followers'),
      ),
    );
  }

  void _navigateToFollowing(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersPage(userId: userId, title: 'Following'),
      ),
    );
  }

  void _navigateToProjects(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectsPage(userId: userId),
      ),
    );
  }

  void _navigateToMessages(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesPage(otherUserId: userId),
      ),
    );
  }
}

class _StatButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
