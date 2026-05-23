import db from "../config/db.js";

export const saveFcmToken = async (req, res) => {
  try {
    const userId = req.user.id;
    const { token, platform = "android" } = req.body;

    if (!token) {
      return res.status(400).json({
        message: "FCM token is required",
      });
    }

    await db.query(
      `INSERT INTO user_fcm_tokens (user_id, token, platform)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE
         token = VALUES(token),
         updated_at = CURRENT_TIMESTAMP`,
      [userId, token, platform]
    );

    res.status(200).json({
      message: "FCM token saved successfully",
    });
  } catch (error) {
    console.log("Save FCM token error:", error);
    res.status(500).json({
      message: "Server error",
    });
  }
};