import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

exports.sendPendingNotification = functions.firestore
  .document("cases/{caseId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "Pending" && after.status === "Pending") {
      const message = {
        notification: {
          title: "New Case Pending",
          body: "A patient is requesting professional help.",
        },
        topic: "professionals",
      };
      await admin.messaging().send(message);
    }

    if (before.status === "Pending" && after.status === "Accepted") {
      // Optional logic here
    }
  });


