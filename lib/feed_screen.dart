// lib/feed_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reporte_petito/pages/chat_screen.dart'; // ¡Importante!





class FeedScreen extends StatelessWidget {

  const FeedScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Reportes Recientes (Feed)'),

      ),

      // StreamBuilder es el widget que "escucha" los datos en tiempo real

      body: StreamBuilder<QuerySnapshot>(

        // 1. Le decimos qué "escuchar": la colección 'reportes'

        //    y que los ordene por 'fechaPublicacion' (los más nuevos primero)

        stream: FirebaseFirestore.instance

            .collection('reportes')

            .orderBy('fechaPublicacion', descending: true)

            .snapshots(),



        // 2. El 'builder' construye la UI basado en lo que recibe del stream

        builder: (context, snapshot) {

         

          // 3. Mientras espera los datos, muestra un círculo de carga

          if (snapshot.connectionState == ConnectionState.waiting) {

            return const Center(child: CircularProgressIndicator());

          }



          // 4. Si hay un error

          if (snapshot.hasError) {

            return const Center(child: Text('Ocurrió un error al cargar los reportes.'));

          }



          // 5. Si no hay datos (la colección está vacía)

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {

            return const Center(child: Text('Aún no hay reportes. ¡Publica el primero!'));

          }



          // 6. ¡Si todo salió bien y SÍ hay datos!

          // Obtenemos la lista de documentos (reportes)

          final reportes = snapshot.data!.docs;



          // Usamos un ListView para mostrar todos los reportes

          return ListView.builder(

            itemCount: reportes.length, // El número de reportes que encontró

            itemBuilder: (context, index) {

              // Obtenemos el reporte individual

              final reporte = reportes[index];

             

              // Obtenemos los datos de ese reporte

              final data = reporte.data() as Map<String, dynamic>;

              final String descripcion = data['descripcion'];

              final String fotoUrl = data['fotoUrl'];

              final String autorId = data['idUsuario']; // ID del creador del reporte
              final String autorEmail = data['emailUsuario'] ?? 'Email no disponible';
              final String currentUserId = FirebaseAuth.instance.currentUser!.uid; // Tu ID

              // (Opcional) Manejar la fecha

              // final Timestamp fecha = data['fechaPublicacion'];



              // Creamos una "Tarjeta" (Card) bonita para cada reporte

              return Card(

                margin: const EdgeInsets.all(10.0),

                clipBehavior: Clip.antiAlias, // Para que la imagen respete los bordes

                elevation: 5,

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    // 7. Mostramos la imagen desde la URL

                    Image.network(

                      fotoUrl,

                      height: 250,

                      fit: BoxFit.cover,

                      // Muestra un 'loading' mientras carga la imagen

                      loadingBuilder: (context, child, loadingProgress) {

                        if (loadingProgress == null) return child;

                        return const Center(

                          heightFactor: 5,

                          child: CircularProgressIndicator(),

                        );

                      },

                      // Muestra un ícono si la imagen falla en cargar

                      errorBuilder: (context, error, stackTrace) {

                        return const Center(

                          heightFactor: 5,

                          child: Icon(Icons.broken_image, size: 50),

                        );

                      },

                    ),

                   

                    // 8. Mostramos la descripción

                    Padding(

                      padding: const EdgeInsets.all(12.0),

                      child: Text(

                        descripcion,

                        style: const TextStyle(fontSize: 16),

                      ),

                    ),

                    // --- AÑADE TODO ESTE BLOQUE ---
                    if (autorId != currentUserId) // Solo mostrar si NO es tu reporte
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.chat_bubble_outline),
                          label: Text("Contactar"),
                          onPressed: () {
                            // Navegamos a la pantalla de chat
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  // Le pasamos los datos del AUTOR del reporte
                                  receiverEmail: autorEmail,
                                  receiverId: autorId,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    // --- FIN DEL BLOQUE A AÑADIR ---

                  ],

                ),

              );

            },

          );

        },

      ),

    );

  }

}