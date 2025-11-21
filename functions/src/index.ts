// Importa las herramientas necesarias de Firebase (V2)
import {onSchedule, ScheduledEvent} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Inicializa la app de "admin"
admin.initializeApp();

// Obtenemos acceso a Firestore y al bucket (cubeta) de Storage
const db = admin.firestore();
const storage = admin.storage().bucket();

/**
 * Función programada (cron job) para limpiar reportes antiguos.
 * Esta es la sintaxis V2 corregida.
 */
export const limpiarReportesAntiguos = onSchedule(
  {
    schedule: "every day 03:00",
    timeZone: "America/Mexico_City", // ¡Importante! Usa tu zona horaria
  },
  // Usamos _event para que sepa que no usamos el parámetro (arregla 'unused-vars')
  async (_event: ScheduledEvent) => {
    logger.info("Iniciando la limpieza de reportes antiguos...");

    // 1. Calcula la fecha de "hace 2 días"
    const ahora = admin.firestore.Timestamp.now();
    const dosDiasAtras = admin.firestore.Timestamp.fromMillis(
      ahora.toMillis() - 48 * 60 * 60 * 1000 // 48 horas
    );

    // 2. Busca en Firestore los reportes para borrar
    const reportesAntiguos = await db
      .collection("reportes")
      .where("fechaPublicacion", "<=", dosDiasAtras)
      .get();

    if (reportesAntiguos.empty) {
      logger.info("No se encontraron reportes antiguos para borrar.");
      return;
    }

    logger.info(`Encontrados ${reportesAntiguos.size} reportes para borrar.`);

    const batch = db.batch();
    // Arreglamos el 'any' (es solo una advertencia, pero es mejor así)
    const promesasDeBorradoStorage: Promise<any>[] = [];

    // 4. Recorre cada reporte encontrado
    reportesAntiguos.forEach((doc) => {
      const reporte = doc.data();
      const fotoUrl = reporte.fotoUrl;

      // A. Borrar la foto de Storage
      if (fotoUrl) {
        try {
          const decodedUrl = decodeURIComponent(fotoUrl);
          const filePath = decodedUrl.substring(
            decodedUrl.indexOf("/o/") + 3,
            decodedUrl.indexOf("?alt=media")
          );

          const refFoto = storage.file(filePath);
          promesasDeBorradoStorage.push(refFoto.delete());
          logger.info(`Marcando para borrar foto: ${filePath}`);
        } catch (error) {
          // Arreglamos la línea larga (max-len)
          logger.error(
            "Error al procesar la URL de la foto",
            {fotoUrl, error}
          );
        }
      }

      // B. Borrar el documento de Firestore
      batch.delete(doc.ref);
    });

    // 5. Ejecuta todos los borrados
    try {
      await Promise.all(promesasDeBorradoStorage);
      logger.info("Fotos de Storage borradas con éxito.");

      await batch.commit();
      logger.info("Documentos de Firestore borrados con éxito.");
    } catch (error) {
      logger.error("Error durante el borrado en lote:", error);
    }

    return;
  }
);
// Se añade línea nueva al final para arreglar 'eol-last'