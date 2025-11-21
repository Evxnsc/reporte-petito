import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart'; // Importa tu pantalla de chat

class ChatListScreen extends StatelessWidget {
  ChatListScreen({Key? key}) : super(key: key);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Mis Chats"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Buscamos en 'chat_rooms' donde el campo 'participants'
        //    contenga nuestro ID.
        stream: _firestore
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastMessageTimestamp', descending: true) // Chats más recientes primero
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar chats."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No tienes chats. Inicia uno desde un reporte."));
          }

          // 2. Construir la lista
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return _buildChatListItem(doc, context);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(DocumentSnapshot doc, BuildContext context) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final String currentUserId = _auth.currentUser!.uid;

    // 3. Lógica para obtener los datos del OTRO usuario
    final Map<String, dynamic> participantsInfo = data['participantsInfo'];

    // Obtenemos el ID del otro usuario (el que no es el nuestro)
    String otherUserId = participantsInfo.keys.firstWhere(
      (key) => key != currentUserId,
      orElse: () => '?', // Fallback
    );

    // Obtenemos el email del otro usuario usando su ID
    String otherUserEmail = participantsInfo[otherUserId] ?? "Usuario Desconocido";
    String lastMessage = data['lastMessage'] ?? "Sin mensajes";

    return ListTile(
      leading: Icon(Icons.person),
      title: Text(otherUserEmail), // Mostramos el email del otro
      subtitle: Text(lastMessage), // Mostramos el último mensaje
      onTap: () {
        // 4. Navegar al chat existente
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              receiverEmail: otherUserEmail,
              receiverId: otherUserId,
            ),
          ),
        );
      },
    );
  }
}