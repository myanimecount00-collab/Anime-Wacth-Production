import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final api = ApiService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('AnimeVault'),
      ),

      body: FutureBuilder<List<dynamic>>(
      future: api.getTrending(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

    final List<dynamic> animeList = snapshot.data!;

return ListView.builder(
  itemCount: animeList.length,
  itemBuilder: (context, index) {

    final anime = animeList[index];

   print(anime.runtimeType);

    return ListTile(
      title: Text(
        anime['title'],
      ),
    );
  },
);
        },
      ),
    );
  }
}