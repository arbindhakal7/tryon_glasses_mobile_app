import 'package:flutter/material.dart';
import 'package:mda622/camera_screen.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Try-On App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text("Virtual Try-On")),
        body: Center(
          child: Builder(
          builder: (context) => ElevatedButton(
            child: Text('Open Camera'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CameraScreen()),
              );
            },
          ),
        ),
      ),
    ));
  }
}