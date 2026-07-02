import '../services/auth_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06061A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF06061A),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.deepPurple,
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'AnimeVault User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Center(
            child: Text(
              'Guest Account',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 24),

          GestureDetector(
            onTap: () async {
              print("BUTTON CLICK");

              final auth = AuthService();
              final result = await auth.signInWithGoogle();

              print("RESULT = $result");

              if (result != null) {
                print("LOGIN BERHASIL");
              }
            },
            child: _item(Icons.login, 'Login Google'),
          ),

          _item(Icons.favorite, 'Favorite Anime'),
          _item(Icons.history, 'Watch History'),
          _item(Icons.download, 'Download List'),

          const SizedBox(height: 24),

          _item(Icons.info_outline, 'About Application'),
          _item(Icons.verified, 'Version 1.0.0'),
          _item(Icons.dark_mode, 'Dark Theme'),

          const SizedBox(height: 24),

          _item(Icons.logout, 'Logout'),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title) {
    return Card(
      color: const Color(0xFF121212),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
      ),
    );
  }
}