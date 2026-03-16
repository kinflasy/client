import 'package:client/features/church/presentation/screens/church_tab_screen.dart';
import 'package:client/features/menu/presentation/screens/menu_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    Center(child: Text('Início — em breve')),
    Center(child: Text('Agenda — em breve')),
    ChurchTabScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.church_outlined), label: 'Igreja'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Menu'),
        ],
      ),
    );
  }
}