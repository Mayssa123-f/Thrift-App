import db from "../config/db.js";

export const getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;

    const [messages] = await db.query(
      `SELECT *
       FROM chat_messages
       WHERE conversation_id = ?
       ORDER BY created_at ASC`,
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
      "SELECT * FROM chat_messages WHERE id = ?",
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