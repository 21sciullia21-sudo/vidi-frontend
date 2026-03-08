import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/pages/user_profile_page.dart';

class FollowersPage extends StatelessWidget {
  final String userId;
  final String title;

  const FollowersPage({
    Key? key,
    required this.userId,
    this.title = 'Followers',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          // For demo purposes, show all users except the current one
          // In a real app, you'd filter based on actual follower relationships
          final users = provider.users
              .where((u) => u.id != userId)
              .take(10)
              .toList();

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No $title yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF8B5CF6),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.skillLevel),
                trailing: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size(0, 0),
                  ),
                  child: Text('Follow', style: TextStyle(fontSize: 12)),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfilePage(userId: user.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
