import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Importa tu servicio de chat
import '../services/chat_service.dart'; // Ajusta la ruta si es necesario

class ChatScreen extends StatefulWidget {
  // Recibimos estos datos de la Home Page
  final String receiverEmail;
  final String receiverId;

  const ChatScreen({
    Key? key,
    required this.receiverEmail,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controladores
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Para auto-scroll

  // Instancias
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// [Video 45:26] Método para enviar mensaje
  void sendMessage() async {
    // Solo enviar si el campo de texto no está vacío
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverId, widget.receiverEmail, _messageController.text);
      
      // Limpiar el texto después de enviar
      _messageController.clear();

      // [Video 01:04:14] Hacer scroll al último mensaje
      _scrollDown();
    }
  }

  /// [Video 01:02:32] Método para hacer scroll automático
  void _scrollDown() {
    // Damos un pequeño delay para que el ListView se actualice
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // [Video 01:04:02] Hacer scroll al entrar a la pantalla
    // Usamos addPostFrameCallback para esperar a que todo esté renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail), // Email del receptor en la barra
      ),
      body: Column(
        children: [
          // 1. LISTA DE MENSAJES (EXPANDIDA)
          // [Video 46:29]
          Expanded(
            child: _buildMessageList(),
          ),

          // 2. INPUT DE USUARIO (FILA)
          // [Video 48:20]
          _buildUserInput(),
        ],
      ),
    );
  }

  /// Widget: Construye la lista de mensajes
  Widget _buildMessageList() {
    String currentUserId = _auth.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      // [Video 46:54] Escuchamos al stream de mensajes
      stream: _chatService.getMessagesStream(currentUserId, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Envía un mensaje para empezar."));
        }
        
        // Hacemos scroll cada vez que llega un mensaje nuevo
        _scrollDown();

        return ListView(
          controller: _scrollController, // Asignamos el controlador
          padding: EdgeInsets.all(10),
          children: snapshot.data!.docs.map((doc) {
            return _buildMessageItem(doc);
          }).toList(),
        );
      },
    );
  }

  /// Widget: Construye un item individual de mensaje (la burbuja)
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // [Video 50:14] Revisar si el mensaje es del usuario actual
    bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;

    // [Video 50:33] Alinear a la derecha (actual) o izquierda (otro)
    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // [Video 52:38] (Simplificado) Usamos un Container como "ChatBubble"
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentUser ? Theme.of(context).primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data['message'],
              style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget: Construye el campo de texto y el botón de enviar
  Widget _buildUserInput() {
    return Padding(
      // [Video 52:05] Añadir padding al input
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // [Video 48:33] Campo de texto (Expanded)
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              // [Video 01:01:13] Para el FocusNode (mejora de auto-scroll)
              // (Lo omitimos por simplicidad, el scroll básico ya está)
            ),
          ),
          SizedBox(width: 10),
          // [Video 48:52] Botón de enviar
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: EdgeInsets.all(12),
            ),
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }
}