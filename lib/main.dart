import 'package:flutter/material.dart';

void main() {
  runApp(const DuoTalkApp());
}

class DuoTalkApp extends StatelessWidget {
  const DuoTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DUOTALK',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07111F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BFFF),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selected = 0;

  final pages = const [
    VoicePage(),
    PhotoPage(),
    CameraPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  const Icon(
                    Icons.language,
                    color: Color(0xFF00CFFF),
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'DUOTALK',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            Expanded(child: pages[selected]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF101E30),
        indicatorColor: const Color(0xFF164C75),
        selectedIndex: selected,
        onDestinationSelected: (index) {
          setState(() => selected = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            label: 'Голос',
          ),
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            label: 'Фото',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'Камера',
          ),
        ],
      ),
    );
  }
}

class VoicePage extends StatelessWidget {
  const VoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 25),
          const Text(
            'Голосовой перевод',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          const LanguageCard(
            first: 'Русский',
            second: 'Испанский',
          ),
          const Spacer(),
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF102C49),
              border: Border.all(
                color: const Color(0xFF00BFFF),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.35),
                  blurRadius: 35,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic,
              size: 75,
              color: Color(0xFF00CFFF),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Нажми, чтобы начать разговор',
            style: TextStyle(color: Colors.white70),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class LanguageCard extends StatelessWidget {
  final String first;
  final String second;

  const LanguageCard({
    super.key,
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF14263B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(first, style: const TextStyle(fontSize: 16)),
          const Icon(Icons.swap_horiz, color: Colors.cyan),
          Text(second, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class PhotoPage extends StatelessWidget {
  const PhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image, size: 85, color: Colors.cyan),
          const SizedBox(height: 20),
          const Text(
            'Перевод из фотографии',
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 15),
          const Text('Выбери фотографию с текстом'),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file),
            label: const Text('Выбрать фото'),
          ),
        ],
      ),
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 85, color: Colors.cyan),
          const SizedBox(height: 20),
          const Text(
            'Перевод через камеру',
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 15),
          const Text('Наведи камеру на текст'),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera),
            label: const Text('Открыть камеру'),
          ),
        ],
      ),
    );
  }
}
