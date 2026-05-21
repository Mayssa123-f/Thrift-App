import db from "../config/db.js";

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
      [conversationId]
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

    const [result] = await db.query(
      `INSERT INTO chat_messages 
       (conversation_id, sender_id, message_type, message_text)
       VALUES (?, ?, 'text', ?)`,
      [conversation_id, senderId, message_text]
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
      [result.insertId]
    );

    res.status(201).json({
      message: message[0],
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
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
      [
        conversation_id,
        senderId,
        "Started chat from this product",
        product_id,
      ]
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
      [result.insertId]
    );

    res.status(201).json({
      message: message[0],
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};