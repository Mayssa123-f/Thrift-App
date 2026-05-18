import db from "../config/db.js";

export const createOffer = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const { conversation_id, product_id, seller_id, offered_price } = req.body;

    if (!conversation_id || !product_id || !seller_id || !offered_price) {
      return res.status(400).json({
        message: "Missing offer information",
      });
    }

    const [result] = await db.query(
      `INSERT INTO offers 
       (conversation_id, product_id, buyer_id, seller_id, offered_price)
       VALUES (?, ?, ?, ?, ?)`,
      [conversation_id, product_id, buyerId, seller_id, offered_price]
    );

    const offerId = result.insertId;

    await db.query(
      `INSERT INTO chat_messages 
       (conversation_id, sender_id, message_type, message_text, offer_id)
       VALUES (?, ?, 'offer', ?, ?)`,
      [
        conversation_id,
        buyerId,
        `Offered $${offered_price}`,
        offerId,
      ]
    );

    const [offer] = await db.query(
      "SELECT * FROM offers WHERE id = ?",
      [offerId]
    );

    res.status(201).json({
      offer: offer[0],
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

export const acceptOffer = async (req, res) => {
  try {
    const sellerId = req.user.id;
    const { offerId } = req.params;

    const [offers] = await db.query(
      "SELECT * FROM offers WHERE id = ?",
      [offerId]
    );

    if (offers.length === 0) {
      return res.status(404).json({ message: "Offer not found" });
    }

    const offer = offers[0];

    if (offer.seller_id !== sellerId) {
      return res.status(403).json({
        message: "Only the seller can accept this offer",
      });
    }

    await db.query(
      "UPDATE offers SET status = 'accepted' WHERE id = ?",
      [offerId]
    );

    await db.query(
      `INSERT INTO chat_messages
       (conversation_id, sender_id, message_type, message_text, offer_id)
       VALUES (?, ?, 'system', ?, ?)`,
      [
        offer.conversation_id,
        sellerId,
        `Offer accepted for $${offer.offered_price}`,
        offerId,
      ]
    );

    res.json({ message: "Offer accepted successfully" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

export const declineOffer = async (req, res) => {
  try {
    const sellerId = req.user.id;
    const { offerId } = req.params;

    const [offers] = await db.query(
      "SELECT * FROM offers WHERE id = ?",
      [offerId]
    );

    if (offers.length === 0) {
      return res.status(404).json({ message: "Offer not found" });
    }

    const offer = offers[0];

    if (offer.seller_id !== sellerId) {
      return res.status(403).json({
        message: "Only the seller can decline this offer",
      });
    }

    await db.query(
      "UPDATE offers SET status = 'declined' WHERE id = ?",
      [offerId]
    );

    await db.query(
      `INSERT INTO chat_messages
       (conversation_id, sender_id, message_type, message_text, offer_id)
       VALUES (?, ?, 'system', ?, ?)`,
      [
        offer.conversation_id,
        sellerId,
        `Offer declined`,
        offerId,
      ]
    );

    res.json({ message: "Offer declined successfully" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};