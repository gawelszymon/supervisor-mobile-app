import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'kiosk_controller.dart';
import 'guards.dart';
import 'n8n_client.dart';

void main() {
  runApp(const NadzorcaApp());
}

class NadzorcaApp extends StatelessWidget {
  const NadzorcaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool parentMode = false;

  Future<void> showPinDialog() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text("PIN rodzica"),
          content: TextField(
            controller: c,
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Anuluj"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, c.text),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (pin == "1234") {
      setState(() => parentMode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (d) async {
        if (d.globalPosition.dx < 80 && d.globalPosition.dy < 80) {
          await showPinDialog();
        }
      },
      child: Scaffold(
        appBar: parentMode
            ? AppBar(
                title: const Text("Tryb rodzica"),
                actions: [
                  TextButton(
                    onPressed: () => KioskController.startKiosk(),
                    child: const Text("Start kiosk"),
                  ),
                  TextButton(
                    onPressed: () => KioskController.stopKiosk(),
                    child: const Text("Stop kiosk"),
                  ),
                  TextButton(
                    onPressed: () => setState(() => parentMode = false),
                    child: const Text("Wyjdź"),
                  ),
                ],
              )
            : null,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              gameButton("Matematyka", "assets/games/math/index.html"),
              const SizedBox(height: 20),
              gameButton("Literki", "assets/games/letters/index.html"),
            ],
          ),
        ),
      ),
    );
  }

  Widget gameButton(String name, String asset) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(assetPath: asset, gameId: name),
          ),
        );
      },
      child: Text(name),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String assetPath;
  final String gameId;

  const GameScreen({super.key, required this.assetPath, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        "GameEvents",
        onMessageReceived: (msg) => handleGameEvent(msg.message),
      )
      ..loadFlutterAsset(widget.assetPath);
  }

  void handleGameEvent(String raw) {
    try {
      final data = json.decode(raw);
      N8nClient.logEvent({
        "game": widget.gameId,
        "event": data,
        "time": DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: WebViewWidget(controller: controller));
  }
}
