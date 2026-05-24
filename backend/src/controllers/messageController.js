import db from "../config/db.js";
import { sendPushNotification } from "../utils/sendNotifications.js";
import { createNotification } from "../utils/createNotification.js";

export const getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;

    const [messages] = await db.query(
      `
      SELECT 
        cm.*,
        p.title AS product_title,
        p.price AS product_price,
        (
          SELECT pi.image_url
          FROM product_images pi
          WHERE pi.product_id = p.id
          AND pi.is_primary = 1
          LIMIT 1
        ) AS product_image
      FROM chat_messages cm
      LEFT JOIN products p ON cm.product_id = p.id
      WHERE cm.conversation_id = ?
      ORDER BY cm.created_at ASC
      `,
      [conversationId],
    );

    res.json({ messages });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

export const sendMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { conversation_id, message_text } = req.body;

    if (!conversation_id || !message_text) {
      return res.status(400).json({
        message: "Conversation ID and message text are required",
      });
    }

    const [conversationRows] = await db.query(
      `SELECT buyer_id, seller_id FROM conversations WHERE id = ?`,
      [conversation_id],
    );

    if (conversationRows.length === 0) {
      return res.status(404).json({
        message: "Conversation not found",
      });
    }

    const conversation = conversationRows[0];

    if (
      senderId !== conversation.buyer_id &&
      senderId !== conversation.seller_id
    ) {
      return res.status(403).json({
        message: "You are not part of this conversation",
      });
    }

    const receiverId =
      senderId === conversation.buyer_id
        ? conversation.seller_id
        : conversation.buyer_id;

    const [result] = await db.query(
      `INSERT INTO chat_messages 
       (conversation_id, sender_id, message_type, message_text)
       VALUES (?, ?, 'text', ?)`,
      [conversation_id, senderId, message_text],
    );

    const [message] = await db.query(
      `
      SELECT 
        cm.*,
        sender.full_name AS sender_name,
        p.title AS product_title,
        p.price AS product_price,
        (
          SELECT pi.image_url
          FROM product_images pi
          WHERE pi.product_id = p.id
          AND pi.is_primary = 1
          LIMIT 1
        ) AS product_image
      FROM chat_messages cm
      LEFT JOIN users sender ON cm.sender_id = sender.id
      LEFT JOIN products p ON cm.product_id = p.id
      WHERE cm.id = ?
      `,
      [result.insertId],
    );

    // await createNotification({
    //   userId: receiverId,
    //   actorId: senderId,
    //   type: "message",
    //   title: `New message from ${message[0].sender_name || "VINTY"}`,
    //   body: message_text,
    //   conversationId: conversation_id,
    // });

    await sendPushNotification({
      userId: receiverId,
      title: `New message from ${message[0].sender_name || "VINTY"}`,
      body: message_text,
      data: {
        type: "message",
        conversation_id: String(conversation_id),
        sender_id: String(senderId),
        message_id: String(result.insertId),
      },
    });

    res.status(201).json({
      message: message[0],
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
export const markConversationMessagesAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { conversationId } = req.params;

    await db.query(
      `
      UPDATE chat_messages
      SET is_read = TRUE
      WHERE conversation_id = ?
      AND sender_id != ?
      `,
      [conversationId, userId],
    );

    res.json({
      message: "Messages marked as read",
    });
  } catch (error) {
    console.log("markConversationMessagesAsRead error:", error);

    res.status(500).json({
      message: "Server error",
    });
  }
};
export const sendProductMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { conversation_id, product_id } = req.body;

    if (!conversation_id || !product_id) {
      return res.status(400).json({
        message: "Conversation ID and product ID are required",
      });
    }

    const [result] = await db.query(
      `INSERT INTO chat_messages
       (conversation_id, sender_id, message_type, message_text, product_id)
       VALUES (?, ?, 'product', ?, ?)`,
      [conversation_id, senderId, "Started chat from this product", product_id],
    );

    const [message] = await db.query(
      `
      SELECT 
        cm.*,
        p.title AS product_title,
        p.price AS product_price,
        (
          SELECT pi.image_url
          FROM product_images pi
          WHERE pi.product_id = p.id
          AND pi.is_primary = 1
          LIMIT 1
        ) AS product_image
      FROM chat_messages cm
      LEFT JOIN products p ON cm.product_id = p.id
      WHERE cm.id = ?
      `,
      [result.insertId],
    );

    res.status(201).json({
      message: message[0],
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
