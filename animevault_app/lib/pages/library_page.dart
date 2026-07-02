import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06061A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06061A),
        foregroundColor: Colors.white,
        title: const Text('Library'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Continue Watching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  ContinueCard(
                    title: 'Hidarikiki no Eren',
                    progress: 75,
                  ),
                  ContinueCard(
                    title: 'Marriagetoxin',
                    progress: 30,
                  ),
                  ContinueCard(
                    title: 'Lastame Season 2',
                    progress: 95,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Favorites',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.65,
              children: const [
                FavoriteCard(title: 'One Piece'),
                FavoriteCard(title: 'Jujutsu Kaisen'),
                FavoriteCard(title: 'Sousou no Frieren'),
                FavoriteCard(title: 'Attack on Titan'),
                FavoriteCard(title: 'Hunter x Hunter'),
                FavoriteCard(title: 'Naruto'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContinueCard extends StatelessWidget {
  final String title;
  final int progress;

  const ContinueCard({
    super.key,
    required this.title,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.movie,
                size: 50,
                color: Colors.white54,
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress / 100,
            color: Colors.purpleAccent,
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteCard extends StatelessWidget {
  final String title;

  const FavoriteCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.movie,
                color: Colors.white54,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}