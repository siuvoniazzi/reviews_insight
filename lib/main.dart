import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/review_provider.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Add Firebase configuration
  // try {
  //   await Firebase.initializeApp(
  //     options: const FirebaseOptions(
  //       apiKey: "YOUR_API_KEY",
  //       appId: "YOUR_APP_ID",
  //       messagingSenderId: "YOUR_SENDER_ID",
  //       projectId: "YOUR_PROJECT_ID",
  //     ),
  //   );
  // } catch (e) {
  //   print("Firebase initialization failed (expected if not configured): $e");
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ReviewProvider())],
      child: MaterialApp(
        title: 'Review Insights',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
