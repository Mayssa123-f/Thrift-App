import db from "../config/db.js";
import admin from "../config/firebaseAdmin.js";

export const sendPushNotification = async ({
  userId,
  title,
  body,
  data = {},
}) => {
  try {
    const [tokens] = await db.query(
      `SELECT token FROM user_fcm_tokens WHERE user_id = ?`,
      [userId]
    );

    if (tokens.length === 0) {
      console.log("No FCM token found for user:", userId);
      return;
    }

    for (const row of tokens) {
      await admin.messaging().send({
        token: row.token,
        notification: {
          title,
          body,
        },
        data: {
          ...data,
        },
      });
    }
  } catch (error) {
    console.log("Push notification error:", error);
  }
};