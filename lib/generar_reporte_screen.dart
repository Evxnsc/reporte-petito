// lib/generar_reporte_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';



class GenerarReporteScreen extends StatefulWidget {
  const GenerarReporteScreen({super.key});

  @override
  State<GenerarReporteScreen> createState() => _GenerarReporteScreenState();
}

class _GenerarReporteScreenState extends State<GenerarReporteScreen> {
  // Variables de estado que ya teníamos
  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

  // --- NUEVO: Controlador para el campo de texto ---
  final TextEditingController _descripcionController = TextEditingController();
  
  // --- NUEVO: Variable para el estado de carga ---
  bool _estaCargando = false;

  // Función para seleccionar la imagen (ya la teníamos)
  Future<void> _seleccionarImagen() async {
    final XFile? xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() {
        _imagenSeleccionada = File(xFile.path);
      });
    }
  }

  // --- NUEVO: Función principal para subir el reporte ---
  // --- Reemplaza solo esta función ---
  Future<void> _realizarReporte() async {
    // 1. Validar campos
    if (_imagenSeleccionada == null) {
      _mostrarError('Por favor, selecciona una imagen.');
      return;
    }
    if (_descripcionController.text.isEmpty) {
      _mostrarError('Por favor, añade una descripción.');
      return;
    }

    // 2. Iniciar el estado de carga
    setState(() {
      _estaCargando = true;
    });

    // --- NUEVOS MENSAJES DE DEBUG ---
    print("PASO 1: Iniciando reporte...");

    try {
      // 3. Subir la imagen a Firebase Storage
      final String idUsuario = FirebaseAuth.instance.currentUser!.uid;
      final String emailUsuario = FirebaseAuth.instance.currentUser!.email!;
      final String nombreArchivo = '${idUsuario}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final Reference refStorage = FirebaseStorage.instance
          .ref()
          .child('reportes_fotos')
          .child(nombreArchivo);

      print("PASO 2: Subiendo imagen a Storage...");
      await refStorage.putFile(_imagenSeleccionada!);
      print("PASO 3: ¡Imagen subida! Obteniendo URL...");

      // 4. Obtener la URL de descarga
      final String urlDescarga = await refStorage.getDownloadURL();
      print("PASO 4: ¡URL obtenida! $urlDescarga");

      // 5. Guardar la información en Cloud Firestore
      print("PASO 5: Guardando datos en Firestore...");
      await FirebaseFirestore.instance.collection('reportes').add({
        'idUsuario': idUsuario,
        'emailUsuario': emailUsuario,
        'descripcion': _descripcionController.text,
        'fotoUrl': urlDescarga,
        'fechaPublicacion': Timestamp.now(),
      });
      print("PASO 6: ¡Datos guardados en Firestore!");

      // 6. Si todo salió bien, mostramos éxito y regresamos
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Reporte publicado con éxito!')),
        );
        Navigator.pop(context); // Regresamos al Menú
      }

    } catch (e) {
      // Si algo falla...
      setState(() {
        _estaCargando = false;
      });
      _mostrarError('Error al publicar el reporte: $e');
      
      // --- NUEVO MENSAJE DE DEBUG ---
      print("¡¡¡ERROR!!! El proceso falló: $e");
    }
  }
  // --- Fin de la función a reemplazar ---

  // --- NUEVO: Función de ayuda para mostrar errores ---
  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- NUEVO: Limpiar el controlador cuando el widget se destruya ---
  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Nuevo Reporte'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Contenedor de la imagen, sin cambios) ...
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imagenSeleccionada != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imagenSeleccionada!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt,
                        color: Colors.grey[600],
                        size: 60,
                      ),
              ),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _seleccionarImagen,
                  icon: const Icon(Icons.image),
                  label: const Text('Seleccionar Imagen'),
                ),
              ),
              const SizedBox(height: 24),

              // --- NUEVO: Conectar el controlador al TextField ---
              TextField(
                controller: _descripcionController, // ¡Importante!
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe la mascota, dónde la viste, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              // --- NUEVO: Lógica del botón de publicar ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                // Llamamos a nuestra nueva función. Deshabilitamos si está cargando.
                onPressed: _estaCargando ? null : _realizarReporte,
                child: _estaCargando
                    ? const CircularProgressIndicator(color: Colors.white) // Muestra el círculo de carga
                    : const Text('Realizar Reporte'), // Muestra el texto
              )
            ],
          ),
        ),
      ),
    );
  }
}