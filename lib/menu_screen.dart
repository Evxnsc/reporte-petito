// lib/menu_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reporte_petito/generar_reporte_screen.dart'; //
import 'package:reporte_petito/feed_screen.dart'; 
import 'package:reporte_petito/pages/chat_list_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        // Añadimos un botón para ir al perfil (opcional pero recomendado)
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navegamos a la pantalla de perfil que ya tienes
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
                  backgroundColor: Colors.red, // Color rojo para salir
                ),
                onPressed: () async {
                  // 1. Cerramos la sesión en Firebase
                  await FirebaseAuth.instance.signOut();

                  // 2. Regresamos al usuario a la pantalla de Login
                  // (Usamos 'context.mounted' para asegurar que el widget existe)
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