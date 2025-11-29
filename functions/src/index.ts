// 1. IMPORTACIONES
// Importamos 'onSchedule' (para la limpieza) y 'onDocumentCreated' (para el chat)
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentCreated } from "firebase-functions/v2/firestore"; // <--- NUEVA IMPORTACIÓN
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// 2. INICIALIZACIÓN
admin.initializeApp();

const db = admin.firestore();
const storage = admin.storage().bucket();

// ==================================================================
// FUNCIÓN 1: Limpieza Semanal (TU CÓDIGO ORIGINAL INTACTO)
// ==================================================================
export const borrarReportesSemanales = onSchedule(
  {
    schedule: "every monday 03:00", // Se ejecuta cada lunes en la madrugada
    timeZone: "America/Mexico_City",
  },
  async (event) => {
    logger.info("Iniciando limpieza semanal de reportes...");

    // 1. Calcular la fecha de hace 7 DÍAS (168 horas)
    const ahora = admin.firestore.Timestamp.now();
    const millisSieteDias = 7 * 24 * 60 * 60 * 1000; // 7 días en milisegundos
    const fechaLimite = admin.firestore.Timestamp.fromMillis(
      ahora.toMillis() - millisSieteDias
    );

    // 2. Buscar reportes viejos
    const reportesAntiguos = await db
      .collection("reportes")
      .where("fechaPublicacion", "<=", fechaLimite)
      .get();

    if (reportesAntiguos.empty) {
      logger.info("No hay reportes antiguos (de más de 7 días) para borrar.");
      return;
    }

    logger.info(`Encontrados ${reportesAntiguos.size} reportes para borrar.`);

    const batch = db.batch();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const promesasBorradoFotos: Promise<any>[] = [];

    // 3. Recorrer y preparar borrado
    reportesAntiguos.forEach((doc) => {
      const data = doc.data();
      const fotoUrl = data["fotoUrl"];

      // Borrar foto de Storage si existe
      if (fotoUrl) {
        try {
          const decodedUrl = decodeURIComponent(fotoUrl);
          // Extraer path del archivo de la URL
          const filePath = decodedUrl.substring(
            decodedUrl.indexOf("/o/") + 3,
            decodedUrl.indexOf("?alt=media")
          );

          const fileRef = storage.file(filePath);
          promesasBorradoFotos.push(fileRef.delete());
        } catch (error) {
          logger.error("Error extrayendo path de foto", { fotoUrl, error });
        }
      }

      // Borrar documento de Firestore
      batch.delete(doc.ref);
    });

    // 4. Ejecutar todo
    await Promise.all(promesasBorradoFotos); // Borra las fotos
    await batch.commit(); // Borra los documentos en la BD

    logger.info("Limpieza semanal completada con éxito.");
  }
);

// ==================================================================
// FUNCIÓN 2: Notificaciones de Chat (LA NUEVA AGREGADA)
// ==================================================================
export const enviarNotificacionChat = onDocumentCreated(
  "chat_rooms/{chatRoomId}/messages/{messageId}",
  async (event) => {
    // 1. Obtener los datos del mensaje recién creado
    const snapshot = event.data;
    if (!snapshot) {
      return; // Si no hay datos, no hacemos nada
    }
    
    const mensajeData = snapshot.data();
    const receiverId = mensajeData.receiverId; // A quién va dirigido
    const senderEmail = mensajeData.senderEmail; // Quién lo mandó
    const textoMensaje = mensajeData.message;

    logger.info(`Nuevo mensaje de ${senderEmail} para ${receiverId}`);

    try {
      // 2. Buscar el token del DESTINATARIO en la colección 'users'
      const userDoc = await db.collection("users").doc(receiverId).get();
      
      if (!userDoc.exists) {
        logger.warn(`El usuario ${receiverId} no tiene documento en la base de datos.`);
        return;
      }

      const userData = userDoc.data();
      // Usamos el operador ?. por seguridad
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        logger.warn(`El usuario ${receiverId} no tiene token FCM registrado.`);
        return;
      }

      // 3. Construir la notificación
      const message = {
        notification: {
          title: `Nuevo mensaje de ${senderEmail}`,
          body: textoMensaje,
        },
        token: fcmToken, // La dirección del celular destino
        data: {
          // Datos extra para navegación (opcional)
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          chatRoomId: event.params.chatRoomId,
        }
      };

      // 4. Enviar la notificación
      await admin.messaging().send(message);
      logger.info("Notificación enviada con éxito.");

    } catch (error) {
      logger.error("Error al enviar notificación:", error);
    }
  }
);