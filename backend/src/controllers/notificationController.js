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
      [userId, token, platform],
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

export const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const [notifications] = await db.query(
      `
      SELECT 
        n.id,
        n.user_id,
        n.actor_id,
        n.type,
        n.title,
        n.body,
        n.conversation_id,
        n.product_id,
        n.order_id,
        n.offer_id,
        n.is_read,
        n.created_at,

        actor.full_name AS actor_name,
        actor.profile_image_url AS actor_image

      FROM notifications n
      LEFT JOIN users actor ON n.actor_id = actor.id

      WHERE n.user_id = ?
      ORDER BY n.created_at DESC
      `,
      [userId],
    );

    res.json({ notifications });
  } catch (error) {
    console.log("Get notifications error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getUnreadNotificationCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const [rows] = await db.query(
      `
      SELECT COUNT(*) AS unread_count
      FROM notifications
      WHERE user_id = ?
      AND is_read = FALSE
      `,
      [userId],
    );

    res.json({
      unread_count: rows[0].unread_count,
    });
  } catch (error) {
    console.log("Unread notification count error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const markNotificationAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    await db.query(
      `
      UPDATE notifications
      SET is_read = TRUE
      WHERE id = ?
      AND user_id = ?
      `,
      [id, userId],
    );

    res.json({ message: "Notification marked as read" });
  } catch (error) {
    console.log("Mark notification read error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const markAllNotificationsAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    await db.query(
      `
      UPDATE notifications
      SET is_read = TRUE
      WHERE user_id = ?
      `,
      [userId],
    );

    res.json({ message: "All notifications marked as read" });
  } catch (error) {
    console.log("Mark all notifications read error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const clearNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    await db.query(
      `
      DELETE FROM notifications
      WHERE user_id = ?
      `,
      [userId],
    );

    res.json({ message: "Notifications cleared" });
  } catch (error) {
    console.log("Clear notifications error:", error);
    res.status(500).json({ message: "Server error" });
  }
};
