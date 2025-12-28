import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🔵 STARTING APP..."); // Debug Print 1

  try {
    if (Firebase.apps.isEmpty) {
      print("🔵 INITIALIZING FIREBASE..."); // Debug Print 2
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("🟢 FIREBASE INITIALIZED!"); // Debug Print 3
    } else {
      print("🟡 FIREBASE ALREADY INITIALIZED");
    }
  } catch (e) {
    print("🔴 FIREBASE ERROR: $e"); // Catches connection errors
  }

  print("🔵 RUNNING APP..."); // Debug Print 4
  runApp(const EmberApp());
}