const admin = require("firebase-admin");
const serviceAccount = require("../../../../../../../C:/Users/TRRR/Desktop/version finale 24nov/covoiturageAuth-main/functions/projet-covoiturage-ca536-firebase-adminsdk-ujh7j-f1223df59e.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Simuler la mise à jour d'une réservation
const reservation = {
  etat: "en attente",
  fcmtoken: "e38LCaQXRPWpAXMZMp4vT3:APA91bF4tH5EXrkxogWpHNtiin4VojTMnugtKWnX3SsLJOlVAJjQJxO_GxeRCo54gSV0uO2nq7Ha_rCKfMl1NWg3q5uRKDCGs5BX1yC_i0vWrWNoNqZ4ypU"
, // Remplace ceci par un vrai FCM token du conducteur
  trajet: {
    departureCity: "Paris",
    arrivalCity: "Lyon"
  }
};

// Fonction pour envoyer la notification au conducteur
const sendReservationNotification = (reservation) => {
  const conducteurToken = reservation.fcmtoken;

  if (conducteurToken) {
    const departureCity = reservation.trajet.departureCity || "Ville inconnue";
    const arrivalCity = reservation.trajet.arrivalCity || "Ville inconnue";

    const payload = {
      notification: {
        title: "Nouvelle demande de réservation",
        body: `Le passager a demandé une réservation pour ${departureCity} ➡️ ${arrivalCity}.`,
      },
    };

    admin
      .messaging()
      .sendToDevice(conducteurToken, payload)
      .then((response) => {
        console.log("Notification envoyée avec succès :", response);
      })
      .catch((error) => {
        console.error("Erreur lors de l'envoi de la notification :", error);
      });
  } else {
    console.warn("Aucun token FCM disponible pour le conducteur.");
  }
};

// Appeler la fonction pour tester
sendReservationNotification(reservation);
