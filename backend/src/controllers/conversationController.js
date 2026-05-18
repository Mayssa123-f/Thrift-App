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
       WHERE product_id = ? AND buyer_id = ? AND seller_id = ?`,
      [product_id, buyerId, seller_id]
    );

    if (existing.length > 0) {
      return res.json({
        conversation: existing[0],
      });
    }

    const [result] = await db.query(
      `INSERT INTO conversations (product_id, buyer_id, seller_id)
       VALUES (?, ?, ?)`,
      [product_id, buyerId, seller_id]
    );

    const [conversation] = await db.query(
      "SELECT * FROM conversations WHERE id = ?",
      [result.insertId]
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
      `SELECT *
       FROM conversations
       WHERE buyer_id = ? OR seller_id = ?
       ORDER BY created_at DESC`,
      [userId, userId]
    );

    res.json({ conversations });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};