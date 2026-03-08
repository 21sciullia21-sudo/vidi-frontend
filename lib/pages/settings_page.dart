import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/supabase/supabase_config.dart';
import 'package:vidi/pages/profile_edit_page.dart';
import 'package:vidi/pages/signin_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _privateAccount = false;
  bool _showActivityStatus = true;
  bool _allowTagging = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentUser = provider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: 'Account',
            children: [
              ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Edit Profile'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileEditPage()),
                ),
              ),
              ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text('Email'),
                subtitle: Text(currentUser?.email ?? 'Not available'),
              ),
              ListTile(
                leading: Icon(Icons.badge_outlined),
                title: Text('Account Type'),
                subtitle: Text(currentUser?.currentRole.toUpperCase() ?? 'Freelancer'),
              ),
            ],
          ),
          Divider(height: 32),
          _buildSection(
            context,
            title: 'Privacy',
            children: [
              SwitchListTile(
                secondary: Icon(Icons.lock_outline),
                title: Text('Private Account'),
                subtitle: Text('Only approved followers can see your content'),
                value: _privateAccount,
                onChanged: (val) => setState(() => _privateAccount = val),
              ),
              SwitchListTile(
                secondary: Icon(Icons.circle),
                title: Text('Show Activity Status'),
                subtitle: Text('Let others know when you\'re online'),
                value: _showActivityStatus,
                onChanged: (val) => setState(() => _showActivityStatus = val),
              ),
              SwitchListTile(
                secondary: Icon(Icons.local_offer_outlined),
                title: Text('Allow Tagging'),
                subtitle: Text('Let others tag you in posts'),
                value: _allowTagging,
                onChanged: (val) => setState(() => _allowTagging = val),
              ),
              ListTile(
                leading: Icon(Icons.block),
                title: Text('Blocked Accounts'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No blocked accounts')),
                  );
                },
              ),
            ],
          ),
          Divider(height: 32),
          _buildSection(
            context,
            title: 'Notifications',
            children: [
              SwitchListTile(
                secondary: Icon(Icons.notifications_outlined),
                title: Text('Enable Notifications'),
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
              if (_notificationsEnabled) ...[
                SwitchListTile(
                  secondary: Icon(Icons.email_outlined),
                  title: Text('Email Notifications'),
                  subtitle: Text('Receive notifications via email'),
                  value: _emailNotifications,
                  onChanged: (val) => setState(() => _emailNotifications = val),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.phone_android),
                  title: Text('Push Notifications'),
                  subtitle: Text('Receive push notifications on your device'),
                  value: _pushNotifications,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),
              ],
            ],
          ),
          Divider(height: 32),
          _buildSection(
            context,
            title: 'Security',
            children: [
              ListTile(
                leading: Icon(Icons.password),
                title: Text('Change Password'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password change coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.security),
                title: Text('Two-Factor Authentication'),
                subtitle: Text('Add an extra layer of security'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('2FA setup coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.devices),
                title: Text('Active Sessions'),
                subtitle: Text('Manage your active sessions'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Session management coming soon')),
                  );
                },
              ),
            ],
          ),
          Divider(height: 32),
          _buildSection(
            context,
            title: 'Preferences',
            children: [
              ListTile(
                leading: Icon(Icons.language),
                title: Text('Language'),
                subtitle: Text('English'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language selection coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.dark_mode_outlined),
                title: Text('Theme'),
                subtitle: Text('Dark mode'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Theme selection coming soon')),
                  );
                },
              ),
            ],
          ),
          Divider(height: 32),
          _buildSection(
            context,
            title: 'Support',
            children: [
              ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help Center'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Help center coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.feedback_outlined),
                title: Text('Send Feedback'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feedback form coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.description_outlined),
                title: Text('Terms of Service'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Terms of Service')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Privacy Policy'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Privacy Policy')),
                  );
                },
              ),
            ],
          ),
          Divider(height: 32),
          _buildSection(
            context,
            title: 'About',
            children: [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: Icon(Icons.update),
                title: Text('Check for Updates'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You\'re using the latest version')),
                  );
                },
              ),
            ],
          ),
          Divider(height: 32),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Sign Out'),
                        content: Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await SupabaseConfig.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => SignInPage()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Account'),
                        content: Text(
                          'This action is permanent and cannot be undone. All your data will be deleted.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Account deletion coming soon')),
                      );
                    }
                  },
                  child: Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Color(0xFF8B5CF6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
