import db from "../config/db.js";

export const createConversation = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const { product_id, seller_id } = req.body;

    if (!product_id || !seller_id) {
      return res.status(400).json({
        message: "Product ID and seller ID are required",
      });
    }

    const [existing] = await db.query(
      `SELECT * FROM conversations
   WHERE buyer_id = ? AND seller_id = ?`,
      [buyerId, seller_id],
    );

    if (existing.length > 0) {
      return res.json({
        conversation: existing[0],
      });
    }

    const [result] = await db.query(
      `INSERT INTO conversations (product_id, buyer_id, seller_id)
       VALUES (?, ?, ?)`,
      [product_id, buyerId, seller_id],
    );

    const [conversation] = await db.query(
      "SELECT * FROM conversations WHERE id = ?",
      [result.insertId],
    );

    res.status(201).json({
      conversation: conversation[0],
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getConversations = async (req, res) => {
  try {
    const userId = req.user.id;

    const [conversations] = await db.query(
      `
      SELECT 
        c.id,
        c.product_id,
        c.buyer_id,
        c.seller_id,
        c.created_at,

        CASE
          WHEN c.buyer_id = ? THEN seller.full_name
          ELSE buyer.full_name
        END AS receiver_name,

        CASE
          WHEN c.buyer_id = ? THEN seller.profile_image_url
          ELSE buyer.profile_image_url
        END AS receiver_image,

        p.title AS product_title,

        (
          SELECT cm.created_at
          FROM chat_messages cm
          WHERE cm.conversation_id = c.id
          ORDER BY cm.created_at DESC
          LIMIT 1
        ) AS last_message_at,

        (
          SELECT COUNT(*)
          FROM chat_messages cm
          WHERE cm.conversation_id = c.id
          AND cm.sender_id != ?
          AND cm.is_read = FALSE
        ) AS unread_count,

        (
          SELECT pi.image_url
          FROM product_images pi
          WHERE pi.product_id = p.id
          AND pi.is_primary = 1
          LIMIT 1
        ) AS product_image,

        p.price AS product_price,

        (
          SELECT cm.message_text
          FROM chat_messages cm
          WHERE cm.conversation_id = c.id
          ORDER BY cm.created_at DESC
          LIMIT 1
        ) AS last_message,

        (
          SELECT cm.message_type
          FROM chat_messages cm
          WHERE cm.conversation_id = c.id
          ORDER BY cm.created_at DESC
          LIMIT 1
        ) AS last_message_type

      FROM conversations c

      JOIN users buyer
        ON c.buyer_id = buyer.id

      JOIN users seller
        ON c.seller_id = seller.id

      LEFT JOIN products p
        ON c.product_id = p.id

      WHERE c.buyer_id = ?
      OR c.seller_id = ?

      ORDER BY last_message_at DESC, c.created_at DESC
      `,
      [userId, userId, userId, userId, userId],
    );

    res.json({ conversations });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
export const getConversationById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const [conversations] = await db.query(
      `
      SELECT 
        c.id,
        c.product_id,
        c.buyer_id,
        c.seller_id,
        c.created_at,

        CASE
          WHEN c.buyer_id = ? THEN seller.full_name
          ELSE buyer.full_name
        END AS receiver_name,

        CASE
          WHEN c.buyer_id = ? THEN seller.profile_image_url
          ELSE buyer.profile_image_url
        END AS receiver_image,

        p.title AS product_title,

        (
          SELECT pi.image_url
          FROM product_images pi
          WHERE pi.product_id = p.id
          AND pi.is_primary = 1
          LIMIT 1
        ) AS product_image,

        p.price AS product_price

      FROM conversations c
      JOIN users buyer ON c.buyer_id = buyer.id
      JOIN users seller ON c.seller_id = seller.id
      LEFT JOIN products p ON c.product_id = p.id

      WHERE c.id = ?
      AND (c.buyer_id = ? OR c.seller_id = ?)
      LIMIT 1
      `,
      [userId, userId, id, userId, userId],
    );

    if (conversations.length === 0) {
      return res.status(404).json({ message: "Conversation not found" });
    }

    res.json({ conversation: conversations[0] });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
export const getUnreadMessagesCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const [rows] = await db.query(
      `
      SELECT COUNT(*) AS unread_count
      FROM chat_messages cm
      JOIN conversations c ON cm.conversation_id = c.id
      WHERE (c.buyer_id = ? OR c.seller_id = ?)
      AND cm.sender_id != ?
      AND cm.is_read = FALSE
      `,
      [userId, userId, userId]
    );

    res.json({
      unread_count: rows[0].unread_count,
    });
  } catch (error) {
    console.log("getUnreadMessagesCount error:", error);
    res.status(500).json({ message: "Server error" });
  }
};
