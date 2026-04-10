import 'dart:async';
import 'package:flutter/material.dart';
import 'class.dart';
import 'fonctions.dart';
import 'HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final recettes = await chargerRecettes();
  runApp(MyApp(recettes: recettes));
}

class MyApp extends StatelessWidget {
  final List<Recette> recettes;
  const MyApp({super.key, required this.recettes});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liste de Courses',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      // Animation de transition entre pages
      onGenerateRoute: (settings) {
        final page = settings.arguments as Widget? ??
            HomePage(recettes: recettes);
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
      home: SplashScreen(recettes: recettes),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final List<Recette> recettes;
  const SplashScreen({super.key, required this.recettes});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomePage(recettes: widget.recettes),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade700,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    size: 60,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mes Courses',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fais tes courses intelligemment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade100,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}