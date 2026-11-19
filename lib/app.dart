import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/movie_repository.dart';
import 'pages/home_page.dart';
import 'state/app_state.dart';

class AlatalolileApp extends StatelessWidget {
  const AlatalolileApp({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => AppState(MovieRepository())
      ..loadLatest()
      ..loadFavorites(),
    child: MaterialApp(
      title: 'alatalolile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC107),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    ),
  );
}
