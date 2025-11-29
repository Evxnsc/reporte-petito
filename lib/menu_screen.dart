// lib/menu_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reporte_petito/generar_reporte_screen.dart';
import 'package:reporte_petito/feed_screen.dart';
import 'package:reporte_petito/pages/chat_list_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Cambiamos de StatelessWidget a StatefulWidget
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  
  // 2. Usamos initState para ejecutar código al arrancar la pantalla
  @override
  void initState() {
    super.initState();
    // Llamamos a la configuración de notificaciones aquí
    _setupNotifications();
  }

  // 3. La lógica para pedir permisos y guardar el token
  Future<void> _setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // A. Pedir permiso al usuario
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificaciones concedido');
      
      // B. Obtener el token del dispositivo
      String? token = await messaging.getToken();
      
      // C. Guardarlo en Firestore bajo el usuario actual
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token, // Guardamos el token
        }, SetOptions(merge: true)); // 'merge' evita borrar otros datos
        print("Token guardado con éxito.");
      }
    } else {
      print('Permiso de notificaciones denegado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botón para "GENERAR REPORTE"
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GenerarReporteScreen()),
                  );
                },
                child: const Text('Generar Reporte'),
              ),
              
              const SizedBox(height: 16),

              // Botón para "VER REPORTES" (Tu Feed)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedScreen()),
                  );
                },
                child: const Text('Ver Reportes (Feed)'),
              ),
              const SizedBox(height: 16),

              // Botón para "CHATS"
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatListScreen()),
                  );
                },
                child: const Text('Chats'),
              ),
              const SizedBox(height: 32),

              // Botón para "SALIR"
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/sign-in');
                  }
                },
                child: const Text('Salir (Cerrar Sesión)', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}