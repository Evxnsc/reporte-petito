// Importaciones de Firebase Core y tu configuración
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Asegúrate de que esta ruta sea correcta en tu proyecto
import 'package:reporte_petito/firebase_options.dart';

// Importaciones para la autenticación de UI de Firebase
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

// *** PASO 1: IMPORTA TU NUEVA PANTALLA ***
import 'package:reporte_petito/menu_screen.dart'; // (Asegúrate que el nombre del paquete 'reporte_petito' sea correcto)

// Tu función main() original para inicializar Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Tu nueva clase MyApp para el manejo del login
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    return MaterialApp(
      // *** PASO 2: CAMBIA LA RUTA INICIAL ***
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/menu', // Antes decía '/profile'
      routes: {
        // Ruta para la pantalla de Sign-In
        '/sign-in': (context) {
          return SignInScreen(
            providers: providers,
            actions: [
              // Acción cuando se crea un nuevo usuario
              AuthStateChangeAction<UserCreated>((context, state) {
                // *** PASO 3: CAMBIA LA NAVEGACIÓN ***
                Navigator.pushReplacementNamed(context, '/menu'); // Antes decía '/profile'
              }),
              // Acción cuando un usuario existente inicia sesión
              AuthStateChangeAction<SignedIn>((context, state) {
                // *** PASO 4: CAMBIA LA NAVEGACIÓN ***
                Navigator.pushReplacementNamed(context, '/menu'); // Antes decía '/profile'
              }),
            ],
          );
        },
        // Ruta para la pantalla de Perfil (La seguimos necesitando)
        '/profile': (context) {
          return ProfileScreen(
            providers: providers,
            actions: [
              // Acción cuando el usuario cierra sesión
              SignedOutAction((context) {
                // Navega de vuelta al sign-in usando el 'context' de la acción
                Navigator.pushReplacementNamed(context, '/sign-in');
              }),
            ],
          );
        },

        // *** PASO 5: AÑADE LA RUTA DE TU NUEVA PANTALLA ***
        '/menu': (context) {
          return const MenuScreen();
        },
      },
    );
  }
}