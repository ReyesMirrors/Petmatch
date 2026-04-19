/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging, MulticastMessage} from "firebase-admin/messaging";

initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

export const sendNotificationOnCreate = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) {
      logger.warn("Notification document has no data", { event });
      return;
    }

    const recipientId = data.recipientId as string | undefined;
    if (!recipientId) {
      logger.warn("Notification missing recipientId", { data });
      return;
    }

    const userSnapshot = await getFirestore().collection("users").doc(recipientId).get();
    if (!userSnapshot.exists) {
      logger.warn("Recipient user not found", { recipientId });
      return;
    }

    const userData = userSnapshot.data() || {};
    const tokens = [] as string[];
    if (Array.isArray(userData.fcmTokens)) {
      tokens.push(...userData.fcmTokens.filter((t) => typeof t === "string"));
    }
    if (typeof userData.fcmToken === "string") {
      tokens.push(userData.fcmToken);
    }

    if (tokens.length === 0) {
      logger.warn("No FCM tokens available for recipient", { recipientId });
      return;
    }

    const title = String(data.title ?? "PetMatch");
    const body = String(data.body ?? "Tienes una nueva notificación.");
    const payload = {
      notification: { title, body },
      data: {
        type: String(data.type ?? "notification"),
        petId: String(data.petId ?? ""),
        requestId: String(data.requestId ?? ""),
      },
    };

    if (tokens.length === 1) {
      await getMessaging().send({ token: tokens[0], ...payload });
      logger.log("Notification sent to single token", { recipientId, token: tokens[0] });
      return;
    }

    const multicast: MulticastMessage = {
      tokens,
      notification: payload.notification,
      data: payload.data,
    };
    const result = await getMessaging().sendEachForMulticast(multicast);
    logger.log("Notification sendEachForMulticast result", { recipientId, successCount: result.successCount, failureCount: result.failureCount });
  },
);

export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  response.send("Hello from Firebase!");
});
