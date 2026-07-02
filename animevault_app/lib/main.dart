import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'pages/main_navigation.dart';
import 'provider/history_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print("STEP 1");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("STEP 2");
  } catch (e) {
    print("FIREBASE ERROR: $e");
  }

  print("STEP 3");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HistoryProvider()..initialize(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainNavigation(),
    );
  }
}