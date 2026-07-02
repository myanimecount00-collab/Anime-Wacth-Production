import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06061A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF06061A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Explore'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // SEARCH
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari anime...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Waktu Tayang',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _daySection('Senin'),
          _daySection('Selasa'),
          _daySection('Rabu'),
          _daySection('Kamis'),
          _daySection('Jumat'),
          _daySection('Sabtu'),
          _daySection('Minggu'),
        ],
      ),
    );
  }

  Widget _daySection(String day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          day,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {

              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      height: 90,
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

                    const SizedBox(height: 8),

                    Text(
                      'Anime Dummy ${index + 1}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Episode 11',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}