import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importa tu modelo de mensaje
import '../models/message.dart'; // Ajusta la ruta si es necesario

class ChatService {
  // Instancias de Firestore y Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1. OBTENER STREAM DE USUARIOS
  /// (Para mostrar tu lista de usuarios en la Home Page)
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Devuelve cada usuario como un mapa
        return doc.data();
      }).toList();
    });
  }

  /// 2. ENVIAR MENSAJE
  // Reemplaza toda la función 'sendMessage' por esta:

  Future<void> sendMessage(String receiverId, String receiverEmail, String message) async {
    // 1. Obtener info del usuario actual
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // 2. Crear el nuevo mensaje
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // 3. Construir el ID de la sala de chat
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    // 4. Añadir el nuevo mensaje a la subcolección 'messages'
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // 5. --- !! MODIFICACIÓN IMPORTANTE !! ---
    // Actualizar el documento principal del chat_room para la lista de chats
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': ids,
      'participantsInfo': {
        currentUserId: currentUserEmail,
        receiverId: receiverEmail,
      },
      'lastMessage': message,
      'lastMessageTimestamp': timestamp,
    }, SetOptions(merge: true)); // merge:true evita sobreescribir datos
  }

  /// 3. OBTENER MENSAJES
  Stream<QuerySnapshot> getMessagesStream(String userId, String otherUserId) {
    // [Video 44:17] Construir el ID de la sala de chat (igual que al enviar)
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    // [Video 44:36] Obtener el stream de la subcolección 'messages'
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Ordenar por fecha
        .snapshots();
  }
}