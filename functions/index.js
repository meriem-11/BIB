/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Fonction pour envoyer une notification au conducteur
exports.sendReservationNotification = functions.firestore
  .document("reservations/{reservationId}")
  .onUpdate((change, context) => {
    const reservation = change.after.data();
    const previousReservation = change.before.data();

    // Vérifier si l'état est changé en "en attente"
    if (reservation.etat === "en attente" && reservation.etat !== previousReservation.etat) {
      const conducteurToken = reservation.fcmtoken; // FCM Token du conducteur

      if (conducteurToken) {
        const departureCity = reservation.trajet?.departureCity || "Ville inconnue";
        const arrivalCity = reservation.trajet?.arrivalCity || "Ville inconnue";

        const payload = {
          notification: {
            title: "Nouvelle demande de réservation",
            body: `Le passager a demandé une réservation pour ${departureCity} ➡️ ${arrivalCity}.`,
          },
        };

        // Envoi de la notification
        return admin
          .messaging()
          .sendToDevice(conducteurToken, payload)
          .then((response) => {
            console.log("Notification envoyée avec succès au conducteur :", response);
          })
          .catch((error) => {
            console.error("Erreur lors de l'envoi de la notification au conducteur :", error);
          });
      } else {
        console.warn("Aucun token FCM disponible pour le conducteur.");
        return null;
      }
    }
    return null;
  });

// Fonction pour notifier le passager lorsque le conducteur accepte/annule
exports.sendPassengerResponseNotification = functions.firestore
  .document("reservations/{reservationId}")
  .onUpdate((change, context) => {
    const reservation = change.after.data();
    const previousReservation = change.before.data();

    // Vérifier si l'état a changé
    if (
      (reservation.etat === "accepté" || reservation.etat === "annulé") &&
      reservation.etat !== previousReservation.etat
    ) {
      const passengerToken = reservation.passengerToken;

      if (passengerToken) {
        const payload = {
          notification: {
            title: "Mise à jour de votre réservation",
            body: reservation.etat === "accepté"
              ? "Votre réservation a été acceptée par le conducteur."
              : "Votre réservation a été annulée par le conducteur.",
          },
        };

        // Envoi de la notification
        return admin
          .messaging()
          .sendToDevice(passengerToken, payload)
          .then((response) => {
            console.log("Notification envoyée au passager avec succès :", response);
          })
          .catch((error) => {
            console.error("Erreur lors de l'envoi de la notification au passager :", error);
          });
      } else {
        console.warn("Aucun token FCM disponible pour le passager.");
        return null;
      }
    }
    return null;
  });




// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
