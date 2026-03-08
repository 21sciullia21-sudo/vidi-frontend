import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/pages/feed_page.dart';
import 'package:vidi/pages/jobs_page.dart';
import 'package:vidi/pages/store_page.dart';
import 'package:vidi/pages/profile_page.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/widgets/messages_sidebar.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  Future<void> _initializeApp() async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.initialize();
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
      );
    }

    final List<Widget> pages = [
      const FeedPage(),
      const JobsPage(),
      const StorePage(),
      const ProfilePage(),
    ];

    return Consumer<AppProvider>(
      builder: (context, provider, _) => Scaffold(
        body: Stack(
          children: [
            pages[_selectedIndex],
            if (provider.showMessagesSidebar)
              GestureDetector(
                onTap: provider.closeMessagesSidebar,
                child: Container(color: Colors.black54),
              ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: provider.showMessagesSidebar ? 0 : -(MediaQuery.of(context).size.width / 3),
              top: 0,
              bottom: 0,
              child: MessagesSidebar(
                onClose: provider.closeMessagesSidebar,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFF2A2A2A),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.content_cut),
                activeIcon: Icon(Icons.content_cut),
                label: 'The Cut',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                activeIcon: Icon(Icons.work),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                activeIcon: Icon(Icons.storefront),
                label: 'Store',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
